
# Need to install systemd on debian for systemctl to exist.
if $facts['os']['family'] == 'Debian' {
  package{'systemd':
    ensure => present,
  }
}
