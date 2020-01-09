#
# @summary mlocate class , install and configure mlocate
#
# @example
#  class{'mlocate':
#    prunepaths   => ['/afs', '/mnt' ],
#    prunefs      => ['afs', 'fuse'],
#    prunenames   => ['.cache', '.git'],
#    period       => weekly,
#    force_update => true,
#  }
#
# @param ensure Install mlocate or remove mlocate
# @param prunefs List of filesystem types to ignore
# @param prune_bind_mounts Should bind mounts be searched?
# @param prunepaths List of file systems paths not to search
# @param prunenames List of directory or files names to match adn not include.
# @param period Should the update interval be daily, weekly, monthly or infinite.
# @param package_cron Path to a cron file entry to be purged.
# @param force_updatedb Should puppet run updatedb if no database already exists.
#
class mlocate (
  Boolean                                     $ensure = true,
  Array[String[1]]                            $prunefs = [],
  Boolean                                     $prune_bind_mounts = true,
  Array[Stdlib::Unixpath]                     $prunepaths = [],
  Array[String[1]]                            $prunenames = [],
  Enum['infinite','daily','weekly','monthly'] $period = 'daily',
  Optional[Stdlib::Unixpath]                  $package_cron = undef,
  Boolean                                     $force_updatedb = false,

) {

  # Is the package cron or timer based?
  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['release']['major'] {
        '6','7': {
          $periodic_method = 'cron'
        }
        default: {
          $periodic_method = 'timer'
        }
      }
    }
    default: {
      fail('Only os.family RedHat is supported')
    }
  }

  Class['mlocate::install'] -> Class['mlocate::config']

  contain mlocate::install
  contain mlocate::config

}
