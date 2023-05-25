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
  $locate            = $mlocate::locate,
) {
  $_file_ensure = $ensure ? {
    true  => 'file',
    false => 'absent',
  }

  if $ensure {
    file { '/etc/updatedb.conf':
      ensure  => 'file',
      mode    => '0644',
      owner   => root,
      group   => root,
      content => epp('mlocate/updatedb.conf.epp', {
          'prunefs'           => $prunefs,
          'prune_bind_mounts' => $prune_bind_mounts,
          'prunepaths'        => $prunepaths,
          'prunenames'        => $prunenames,
      }),
    }
  }

  # Purge package cron if there is one.
  if $package_cron and $ensure {
    file { $package_cron:
      ensure  => 'file',
      owner   => root,
      group   => root,
      mode    => '0700',
      content => "# Puppet has clobbered file from package\n",
    }
  }

  if $periodic_method == 'cron' {
    if $locate != 'mlocate' {
      fail('Old cron based configuration is only supported with \$locate ==  mlocate')
    }
    $_updatedb_command = '/usr/local/bin/mlocate-wrapper'

    file { $_updatedb_command:
      ensure => $_file_ensure,
      owner  => root,
      group  => root,
      mode   => '0755',
      source => 'puppet:///modules/mlocate/mlocate-wrapper',
    }

    case $period {
      'daily': {
        $_cron_ensure = true
        $_minute      = "${fqdn_rand(59,'mlocate')}"
        $_hour        = "${fqdn_rand(24,'mlocate')}"
        $_date        = '*'
        $_month       = '*'
        $_weekday     = '*'
      }
      'weekly': {
        $_cron_ensure = true
        $_minute      = "${fqdn_rand(59,'mlocate')}"
        $_hour        = "${fqdn_rand(24,'mlocate')}"
        $_date        = '*'
        $_month       = '*'
        $_weekday     = "${fqdn_rand(7,'mlocate')}"
      }
      'monthly': {
        $_cron_ensure = true
        $_minute      = "${fqdn_rand(59,'mlocate')}"
        $_hour        = "${fqdn_rand(24,'mlocate')}"
        $_date        = "${fqdn_rand(28,'mlocate')}"
        $_month       = '*'
        $_weekday     = '*'
      }
      'infinite': {
        $_cron_ensure = false
        $_minute      = undef
        $_hour        = undef
        $_date        = undef
        $_month       = undef
        $_weekday     = undef
      }
      default: {
        fail('Undefined period')
      }
    }

    # Remove old filename that cron::job does not support with a '.' in
    # Last in version 1.0.0
    file { '/etc/cron.d/mlocate-puppet.cron':
      ensure => 'absent',
    }

    if $_cron_ensure and $ensure {
      $_cron_job_ensure = 'present'
    } else {
      $_cron_job_ensure = 'absent'
    }

    cron::job { 'mlocate-puppet':
      ensure      => $_cron_job_ensure,
      command     => '/usr/local/bin/mlocate-wrapper',
      user        => 'root',
      minute      => $_minute,
      hour        => $_hour,
      date        => $_date,
      weekday     => $_weekday,
      month       => $_month,
      description => 'Update mlocate database',
    }

    # End of cron based systemd
  } elsif $periodic_method == 'timer' {
    $_updatedb_command = "/usr/bin/systemctl start ${locate}-updatedb.service"

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

    $_dropin_file_ensure = $ensure ? {
      true  => $_dropin_ensure,
      false => 'absent',
    }

    systemd::dropin_file { 'period.conf':
      ensure  => $_dropin_file_ensure,
      unit    => "${locate}-updatedb.timer",
      content => "#Puppet installed\n[Timer]\nOnCalendar=\nOnCalendar=${period}\n",
    }

    if $ensure {
      service { "${locate}-updatedb.timer":
        ensure => $_timer_active,
        enable => $_timer_active,
      }
    }
  }

  # Run updatedb if no database present.
  if $force_updatedb and $ensure {
    exec { 'force_updatedb':
      command => $_updatedb_command,
      creates => "/var/lib/${locate}/${locate}.db",
    }
  }
}
