# @summary
#  This class handles installation of mlocate
#
# @api private
#
class mlocate::install (
  $package_names = $mlocate::package_names,
  $ensure = $mlocate::ensure,
  $locate = $mlocate::locate,
) {
  $_pkg_ensure = $ensure ? {
    true  => 'present',
    false => 'absent',
  }

  # Remove other package
  $_other = $locate ? {
    'mlocate' => 'plocate',
    default   => 'mlocate'
  }

  package { $_other:
    ensure => 'absent',
    before => Package[$locate],
  }

  package { $locate:
    ensure => $_pkg_ensure,
  }
}
