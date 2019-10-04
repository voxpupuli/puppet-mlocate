# mlocate

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
1. [Setup - The basics of getting started with ntp](#setup)

<a id="module-description"></a>
## Module Description

* Install mlocate package
* Configures `/etc/updatedb.conf`
* Maintains a cron or timer to run mlocate.

<a id="setup"></a>
## Setup

Install mlocate and configure with default configuration.
```puppet
include mlocate
```

Configure everything we can.
```puppet
class{'mlocate':
  ensure            => true,
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

