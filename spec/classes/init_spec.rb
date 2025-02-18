# frozen_string_literal: true

require 'spec_helper'
describe 'mlocate' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with defaults for all parameters' do
        it { is_expected.to compile }
        it { is_expected.to contain_class('mlocate::install') }
        it { is_expected.to contain_class('mlocate::config') }
        it { is_expected.to contain_file('/etc/updatedb.conf') }

        it { is_expected.not_to contain_exec('force_updatedb') }

        # Test default contents of the configurations files.

        # Use the exact match tests up to Redhat 9 since they exist but give up on it after
        # that and use the simpler tests - testing single hiera files with no merge is not needed
        # and more boring that I want to do.
        # Note the defaults need to be sorted firt as puppet does this
        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s+=\s+"9p afs anon_inodefs auto autofs bdev binfmt_misc ceph cgroup cifs coda configfs cpuset debugfs devpts ecryptfs exofs fuse fuse.ceph fuse.glusterfs fuse.sshfs fusectl gfs gfs2 gpfs hugetlbfs inotifyfs iso9660 jffs2 lustre mqueue ncpfs nfs nfs4 nfsd pipefs proc ramfs rootfs rpc_pipefs securityfs selinuxfs sfs sockfs sysfs tmpfs ubifs udf usbfs"$}) }
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /tmp /udev /var/cache/ccache /var/cache/yum /var/lib/ceph /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
        when '8', '9'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s+=\s+"9p afs anon_inodefs auto autofs bdev binfmt_misc ceph cgroup cifs coda configfs cpuset debugfs devpts ecryptfs exofs fuse fuse.ceph fuse.sshfs fusectl gfs gfs2 gpfs hugetlbfs inotifyfs iso9660 jffs2 lustre mqueue ncpfs nfs nfs4 nfsd pipefs proc ramfs rootfs rpc_pipefs securityfs selinuxfs sfs sockfs sysfs tmpfs ubifs udf usbfs"$}) }

          if facts[:os]['release']['major'] == '8'
            it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /tmp /udev /var/cache/ccache /var/cache/dnf /var/cache/yum /var/lib/ceph /var/lib/dnf/yumdb /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
          else
            it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /sysroot/ostree/deploy /tmp /udev /var/cache/ccache /var/cache/dnf /var/cache/fscache /var/cache/yum /var/lib/ceph /var/lib/dnf/yumdb /var/lib/mock /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
          end
        end

        # End of tests that will not be extended beyond RHEL9

        # The simpler tests for now and the future. family is redhat, debian or archlinux currently
        #

        case facts[:os]['family']
        when 'RedHat', 'Archlinux'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s=\s"/afs\s.*\s/var/tmp"$}) }
        else
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s=\s".*/media\s.*\s/var/spool"$}) }
        end

        case facts[:os]['family']
        when 'Debian'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s=\s"NFS\s.*\susbfs"$}) }
        when 'RedHat'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s=\s"9p\s.*\susbfs"$}) }
        else
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s=\s"9p\s.*\svboxsf"$}) }
        end

        case [facts[:os]['family'], facts[:os]['release']['major']]
        when %w[RedHat 8], %w[RedHat 9], %w[RedHat 36], %w[RedHat 37], %w[RedHat 38]
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNENAMES\s=\s"\.arch-ids\s.*\s\{arch\}"$}) }
        when %w[Debian 11], %w[Debian 12], %w[Debian 22.04], %w[Debian 24.04]
          it { is_expected.to contain_file('/etc/updatedb.conf').without_content(%r{^PRUNENAMES.*$}) }
        else # only arch and rhel7 left
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNENAMES\s=\s"\.git\s.*\s\.svn"$}) }
        end

        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNE_BIND_MOUNTS\s+=\s+"yes"$}) }
      end

      context 'with locate set to mlocate' do
        let(:params) do
          {
            locate: 'mlocate'
          }
        end

        case facts[:os]['release']['major']
        when '7', '8', '9', '36'
          it { is_expected.to contain_package('mlocate') }
          it { is_expected.not_to contain_service('plocate-updatedb.timer') }
        else
          it { is_expected.to compile.and_raise_error(%r{mlocate is obsoleted by plocate and}) }
        end
        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/etc/cron.d/mlocate-puppet.cron').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper').with_source('puppet:///modules/mlocate/mlocate-wrapper') }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        when '8', '9', '36'
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.not_to contain_file('/etc/cron.d/mlocate-puppet.cron') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }

          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }

          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'absent',
                unit: 'mlocate-updatedb.timer',
              }
            )
          }

          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        else
          it { is_expected.to compile.and_raise_error(%r{mlocate is obsoleted by plocate}) }
        end
      end

      context 'with locate set to plocate' do
        let(:params) do
          {
            locate: 'plocate'
          }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to compile.and_raise_error(%r{plocate is not available on EL7}) }
        else
          it { is_expected.to contain_package('plocate') }
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('plocate-updatedb.timer') }

          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'absent',
                unit: 'plocate-updatedb.timer',
              }
            )
          }
        end
      end

      context 'with updatedb.conf parameters set' do
        let(:params) do
          {
            prunefs: %w[foo bar],
            prune_bind_mounts: false,
            prunepaths: ['/ythis', '/xthat'],
            prunenames: %w[way no]
          }
        end

        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s+=\s+"bar foo"$}) }
        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNE_BIND_MOUNTS\s+=\s+"no"$}) }
        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/xthat /ythis"$}) }
        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNENAMES\s+=\s+"no way"$}) }
      end

      context 'with period set to daily (the default in package)' do
        let(:params) do
          {
            period: 'daily'
          }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        when '8', '9', '36'
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        else
          it {
            is_expected.to contain_service('plocate-updatedb.timer').with(
              {
                ensure: true,
                enable: true,
              }
            )
          }
        end
      end

      context 'with period set to weekly (the default in package)' do
        let(:params) do
          {
            period: 'weekly'
          }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday(%r{\d}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
        else
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        when '8', '9', '36'
          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'present',
                unit: 'mlocate-updatedb.timer',
                content: %r{^OnCalendar=weekly$},
              }
            )
          }

          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        else
          it { is_expected.to contain_systemd__dropin_file('period.conf') }

          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'present',
                unit: 'plocate-updatedb.timer',
                content: %r{^OnCalendar=weekly$},
              }
            )
          }

          it { is_expected.to contain_service('plocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('plocate-updatedb.timer').with_enable(true) }
        end
      end

      context 'with period set to monthly (the default in package)' do
        let(:params) do
          {
            period: 'monthly'
          }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
        else
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        when '8', '9', '36'
          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'present',
                content: %r{^OnCalendar=monthly$},
                unit: 'mlocate-updatedb.timer',
              }
            )
          }

          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        else
          it {
            is_expected.to contain_systemd__dropin_file('period.conf').with(
              {
                ensure: 'present',
                content: %r{^OnCalendar=monthly$},
                unit: 'plocate-updatedb.timer',
              }
            )
          }

          it { is_expected.to contain_service('plocate-updatedb.timer') }
          it { is_expected.to contain_service('plocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('plocate-updatedb.timer').with_enable(true) }
        end
      end

      context 'with period set to infinite (never run)' do
        let(:params) do
          {
            period: 'infinite'
          }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
        else
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        when '8', '9', '36'
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(false) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(false) }
        else
          it { is_expected.to contain_service('plocate-updatedb.timer').with_ensure(false) }
          it { is_expected.to contain_service('plocate-updatedb.timer').with_enable(false) }
        end
      end

      context 'with force_updatedb set to true' do
        let(:params) do
          {
            force_updatedb: true
          }
        end

        it { is_expected.to contain_exec('force_updatedb') }

        case facts[:os]['release']['major']
        when '7', '8', '9', '36'
          it { is_expected.to contain_exec('force_updatedb').with_unless('/usr/bin/test -s /var/lib/mlocate/mlocate.db') }
        else
          it { is_expected.to contain_exec('force_updatedb').with_unless('/usr/bin/test -s /var/lib/plocate/plocate.db') }
        end

        case facts[:os]['family']
        when 'Debian'
          it { is_expected.to contain_exec('force_updatedb').with_command('/bin/systemctl start plocate-updatedb.service') }
        else
          case facts[:os]['release']['major']
          when '7'
            it { is_expected.to contain_exec('force_updatedb').with_command('/usr/local/bin/mlocate-wrapper') }
          when '8', '9', '36'
            it { is_expected.to contain_exec('force_updatedb').with_command('/usr/bin/systemctl start mlocate-updatedb.service') }
          else
            it { is_expected.to contain_exec('force_updatedb').with_command('/usr/bin/systemctl start plocate-updatedb.service') }
          end
        end
      end

      context 'with ensure set to false' do
        let(:params) do
          {
            ensure: false
          }
        end

        it { is_expected.not_to contain_file('/etc/updatedb.conf') }
        it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
        it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        it { is_expected.not_to contain_exec('force_updatedb') }

        case facts[:os]['release']['major']
        when '7', '8', '9', '36'
          it { is_expected.to contain_package('mlocate').with_ensure('absent') }
        else
          it { is_expected.to contain_package('plocate').with_ensure('absent') }
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper').with_ensure('absent') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('absent') }
        else
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
        end
      end
    end
  end
end
