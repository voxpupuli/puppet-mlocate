# @summary
#  This class handles installation of mlocate
#
# @api private
#
class mlocate::install (
  $package_names = $mlocate::package_names,
  $ensure = $mlocate::ensure,
) {
  $_pkg_ensure = $ensure ? {
    true  => 'present',
    false => 'absent',
  }

  package { $package_names:
    ensure => $_pkg_ensure,
  }
}
