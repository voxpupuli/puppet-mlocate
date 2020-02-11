# @summary
#  This class handles configuration of mlocate
#
# @api private
#
class mlocate::config (
  $ensure            = $mlocate::ensure,
  $prunefs           = $mlocate::prunefs,
  $prune_bind_mounts = $mlocate::prune_bind_mounts,
  $prunepaths        = $mlocate::prunepaths,
  $prunenames        = $mlocate::prunenames,
  $period            = $mlocate::period,
  $package_cron      = $mlocate::package_cron,
  $periodic_method   = $mlocate::periodic_method,
  $force_updatedb    = $mlocate::force_updatedb,
) {

  $_file_ensure = $ensure ? {
    true  => 'file',
    false => 'absent',
  }

  if $ensure {
    file{'/etc/updatedb.conf':
      ensure  => 'present',
      mode    => '0644',
      owner   => root,
      group   => root,
      content => epp('mlocate/updatedb.conf.epp',{
        'prunefs'           => $prunefs,
        'prune_bind_mounts' => $prune_bind_mounts,
        'prunepaths'        => $prunepaths,
        'prunenames'        => $prunenames,
      }),
    }
  }

  # Purge package cron if there is one.
  if $package_cron and $ensure {
    file{$package_cron:
      ensure  => 'present',
      owner   => root,
      group   => root,
      mode    => '0700',
      content => "# Puppet has clobbered file from package\n",
    }
  }

  if $periodic_method == 'cron' {
    file{'/usr/local/bin/mlocate-wrapper':
      ensure => $_file_ensure,
      owner  => root,
      group  => root,
      mode   => '0755',
      source => 'puppet:///modules/mlocate/mlocate-wrapper',
    }

    case $period {
      'daily': {
        $_cron_time   = "${fqdn_rand(59,'mlocate')} ${fqdn_rand(24,'mlocate')} * * *"
        $_cron_ensure = 'present'
      }
      'weekly': {
        $_cron_time   = "${fqdn_rand(59,'mlocate')} ${fqdn_rand(24,'mlocate')} * * ${fqdn_rand(7,'mlocate')}"
        $_cron_ensure = 'present'
      }
      'monthly': {
        $_cron_time   = "${fqdn_rand(59,'mlocate')} ${fqdn_rand(24,'mlocate')} ${fqdn_rand(28,'mlocate')} * *"
        $_cron_ensure = 'present'
      }
      'infinite': {
        $_cron_time   = 'irrelevent'
        $_cron_ensure = 'absent'
      }
      default: {
        fail('Undefined period')
      }
    }

    $_cron_file_ensure = $ensure ? {
      true  => $_cron_ensure,
      false => 'absent',
    }

    file{'/etc/cron.d/mlocate-puppet.cron':
      ensure  => $_cron_file_ensure,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => "#Puppet installed\n${_cron_time} root /usr/local/bin/mlocate-wrapper\n",
    }

    $_updatedb_command = '/usr/local/bin/mlocate-wrapper'

    # End of cron based systemd

  } elsif $periodic_method == 'timer' {

    # daily is default so no dropin required.
    case $period {
      'daily': {
        $_dropin_ensure = 'absent'
        $_timer_active  = true
      }
      'weekly', 'monthly': {
        $_dropin_ensure = 'present'
        $_timer_active  = true
      }
      'infinite': {
        $_dropin_ensure = 'absent'
        $_timer_active  = false
      }
      default: {
        fail('Unknown period')
      }
    }

    contain systemd::systemctl::daemon_reload

    $_dropin_file_ensure = $ensure ? {
      true  => $_dropin_ensure,
      false => 'absent',
    }

    systemd::dropin_file{'period.conf':
      ensure  => $_dropin_file_ensure,
      unit    => 'mlocate-updatedb.timer',
      content => "#Puppet installed\n[Timer]\nOnCalendar=\nOnCalendar=${period}\n",
    }

    if $ensure {
      Class['systemd::systemctl::daemon_reload'] -> Service['mlocate-updatedb.timer']
      service{'mlocate-updatedb.timer':
        ensure => $_timer_active,
        enable => $_timer_active,
      }
    }

    $_updatedb_command = '/usr/bin/systemctl start mlocate-updatedb.service'

  }

  # Run updatedb if no database present.
  if $force_updatedb and $ensure {
    exec{'force_updatedb':
      command => $_updatedb_command,
      creates => '/var/lib/mlocate/mlocate.db',
    }
  }

}
