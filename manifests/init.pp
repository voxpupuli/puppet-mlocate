#
# @summary mlocate class, install and configure mlocate or plocate
#
# @example Simple Case
#
#  class{'mlocate':
#    prunepaths   => ['/afs', '/mnt' ],
#    prunefs      => ['afs', 'fuse'],
#    prunenames   => ['.cache', '.git'],
#    period       => weekly,
#    force_update => true,
#  }
#
# @example Use plocate rather than mlocate
#  class{ 'mlocate':
#    locate => 'plocate',
#  }
#
# @param package_names Deprecated
# @param locate Use plocate or mlocate, default per OS in hiera
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
  Enum['mlocate','plocate']                   $locate,
  Optional[Array[String[1]]]                  $package_names = undef,
  Boolean                                     $ensure = true,
  Array[String[1]]                            $prunefs = [],
  Boolean                                     $prune_bind_mounts = true,
  Array[Stdlib::Unixpath]                     $prunepaths = [],
  Array[String[1]]                            $prunenames = [],
  Enum['infinite','daily','weekly','monthly'] $period = 'daily',
  Optional[Stdlib::Unixpath]                  $package_cron = undef,
  Boolean                                     $force_updatedb = false,

) {
  if $package_names {
    fail('Setting \$package_names explicitly is deprecated, the new locate parameter can be used to specify mlocate or plocate')
  }

  if ( ($facts['os']['name'] == 'Fedora' and  versioncmp($facts['os']['release']['major'],'37') >= 0 ) or
  ($facts['os']['family'] != 'RedHat' ) ) and $locate == 'mlocate' {
    fail('mlocate is obsoleted by plocate and \$locate cannot be set to \'mlocate\'')
  }

  if $facts['os']['release']['major'] == '7' and $locate == 'plocate' {
    fail('plocate is not available on EL7')
  }

  # Is the package cron or timer based?
  $periodic_method = ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7') ? {
    true    => 'cron',
    default => 'timer',
  }

  Class['mlocate::install'] -> Class['mlocate::config']

  contain mlocate::install
  contain mlocate::config
}
