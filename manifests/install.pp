# @summary
#  This class handles installation of mlocate
#
# @api private
#
class mlocate::install(
  $ensure = $mlocate::ensure,
) {

  $_pkg_ensure = $ensure ? {
    true  => 'present',
    false => 'absent',
  }

  package{'mlocate':
    ensure => $_pkg_ensure,
  }

}
