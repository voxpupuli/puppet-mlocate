# mlocate

[![License](https://img.shields.io/github/license/voxpupuli/puppet-mlocate.svg)](https://github.com/voxpupuli/puppet-mlocate/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/voxpupuli/puppet-mlocate.png?branch=master)](https://travis-ci.org/voxpupuli/puppet-mlocate)
[![Code Coverage](https://coveralls.io/repos/github/voxpupuli/puppet-mlocate/badge.svg?branch=master)](https://coveralls.io/github/voxpupuli/puppet-mlocate)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/mlocate.svg)](https://forge.puppetlabs.com/puppet/mlocate)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/mlocate.svg)](https://forge.puppetlabs.com/puppet/mlocate)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/mlocate.svg)](https://forge.puppetlabs.com/puppet/mlocate)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/mlocate.svg)](https://forge.puppetlabs.com/puppet/mlocate)

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
1. [Setup - The basics of getting started with ntp](#setup)

<a id="module-description"></a>
## Module Description

* Install mlocate or plocate package
* Configures `/etc/updatedb.conf`
* Maintains a cron or timer to run mlocate or plocate.

<a id="setup"></a>
## Setup

Install mlocate or plocate and configure with default configuration.
```puppet
include mlocate
```

Fedora 37 and newer will install plocate always since mlocate will
be obsoleted by the plocate RPM allways.

Configure everything we can.
```puppet
class{'mlocate':
  ensure            => true,
  locate            => 'plocate',
  prunefs           => ['9p', 'afs', 'autofs', 'bdev'],
  prune_bind_mounts => true,
  prunenames        => ['.git', 'CVS'],
  prunepaths        => ['/afs', 'mnt' ],
  period            => 'daily',
  force_updatedb    => true,
}
```

The parameters `prunefs`, `prunenames` and `prunepaths` are configured with
a `unique` merge strategy within hiera so the defaults can be easily extended.

```yaml
---
mlocate::prunefs:
  - winnt
mlocate::prunenames:
  - .cache
mlocate::prunepaths:
  - /cvmfs
```

To override all values and set and exact parameter the `lookup_options` will need to be re-defined

```yaml
lookup_options:
  mlocate::prunepaths:
    merge: unique

mocate::prunepaths:
  - /set/prunepaths/to/this/path/and/drop/defaults
```

or just set via parameters:

```puppet
class{ 'mlocate':
  prunepaths => ['just', 'this'],
}
```

If you wish to switch to `plocate` instead you can use the `locate` parameter to switch to that implementation instead.

```yaml
---
mlocate::locate: plocate
```

Using plocate is the default for Archlinux, Debian 11 and newer, Fedora 37 and newer and RHEL 10 and newer

* mlocate is the default for RHEL 7, 8 and 9 and also Fedora 36.
* plocate is the default for Debian and any newer Fedoras or RHELs.
