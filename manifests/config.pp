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

  $_updatedb_command = $facts['os']['family'] ? {
    'Debian' => "/bin/systemctl start ${locate}-updatedb.service",
    default  => "/usr/bin/systemctl start ${locate}-updatedb.service",
  }

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

  # Run updatedb if no database present.
  if $force_updatedb and $ensure {
    exec { 'force_updatedb':
      command => $_updatedb_command,
      unless  => "/usr/bin/test -s /var/lib/${locate}/${locate}.db",
    }
  }
}
