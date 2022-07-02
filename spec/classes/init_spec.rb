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
        it { is_expected.to contain_package('mlocate') }
        it { is_expected.not_to contain_exec('force_updatedb') }

        # Test default contents of the configurations files.
        # Note the defaults need to be sorted firt as puppet does this
        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s+=\s+"9p afs anon_inodefs auto autofs bdev binfmt_misc ceph cgroup cifs coda configfs cpuset debugfs devpts ecryptfs exofs fuse fuse.ceph fuse.glusterfs fuse.sshfs fusectl gfs gfs2 gpfs hugetlbfs inotifyfs iso9660 jffs2 lustre mqueue ncpfs nfs nfs4 nfsd pipefs proc ramfs rootfs rpc_pipefs securityfs selinuxfs sfs sockfs sysfs tmpfs ubifs udf usbfs"$}) }
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /tmp /udev /var/cache/ccache /var/lib/ceph /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
        else
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEFS\s+=\s+"9p afs anon_inodefs auto autofs bdev binfmt_misc ceph cgroup cifs coda configfs cpuset debugfs devpts ecryptfs exofs fuse fuse.ceph fuse.sshfs fusectl gfs gfs2 gpfs hugetlbfs inotifyfs iso9660 jffs2 lustre mqueue ncpfs nfs nfs4 nfsd pipefs proc ramfs rootfs rpc_pipefs securityfs selinuxfs sfs sockfs sysfs tmpfs ubifs udf usbfs"$}) }

          if facts[:os]['release']['major'] == '8'
            it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /tmp /udev /var/cache/ccache /var/lib/ceph /var/lib/dnf/yumdb /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
          else
            it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNEPATHS\s+=\s+"/afs /media /mnt /net /sfs /sysroot/ostree/deploy /tmp /udev /var/cache/ccache /var/cache/fscache /var/lib/ceph /var/lib/dnf/yumdb /var/lib/mock /var/lib/yum/yumdb /var/spool/cups /var/spool/squid /var/tmp"$}) }
          end
        end

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNENAMES\s+=\s+"\.git \.hg \.svn"$}) }
        else
          it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNENAMES\s+=\s+"\.arch-ids \.bzr \.git \.hg \.svn CVS \{arch\}"$}) }
        end

        it { is_expected.to contain_file('/etc/updatedb.conf').with_content(%r{^PRUNE_BIND_MOUNTS\s+=\s+"yes"$}) }

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

          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper').with_source('puppet:///modules/mlocate/mlocate-wrapper') }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        else
          it { is_expected.not_to contain_file('/etc/cron.d/mlocate-puppet.cron') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
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
        when '6', '7'
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
        else
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        end
      end

      context 'with period set to weekly (the default in package)' do
        let(:params) do
          {
            period: 'weekly'
          }
        end

        case facts[:os]['release']['major']
        when '6', '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday(%r{\d}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        else
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('present') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_content(%r{^OnCalendar=$}) }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_content(%r{^OnCalendar=weekly$}) }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        end
      end

      context 'with period set to monthly (the default in package)' do
        let(:params) do
          {
            period: 'monthly'
          }
        end

        case facts[:os]['release']['major']
        when '6', '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('present') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_minute(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_hour(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_date(%r{^\d\d?}) }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_weekday('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_month('*') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_user('root') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_command('/usr/local/bin/mlocate-wrapper') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        else
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('present') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_content(%r{^OnCalendar=monthly$}) }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(true) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(true) }
        end
      end

      context 'with period set to infinite (never run)' do
        let(:params) do
          {
            period: 'infinite'
          }
        end

        case facts[:os]['release']['major']
        when '6', '7'
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/cron.daily/mlocate').with_content(%r{^#.*clobbered.*$}) }
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        else
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.to contain_service('mlocate-updatedb.timer') }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_ensure(false) }
          it { is_expected.to contain_service('mlocate-updatedb.timer').with_enable(false) }
        end
      end

      context 'with force_updatedb set to true' do
        let(:params) do
          {
            force_updatedb: true
          }
        end

        it { is_expected.to contain_exec('force_updatedb') }
        it { is_expected.to contain_exec('force_updatedb').with_creates('/var/lib/mlocate/mlocate.db') }

        case facts[:os]['release']['major']
        when '6', '7'
          it { is_expected.to contain_exec('force_updatedb').with_command('/usr/local/bin/mlocate-wrapper') }
        else
          it { is_expected.to contain_exec('force_updatedb').with_command('/usr/bin/systemctl start mlocate-updatedb.service') }
        end
      end

      context 'with ensure set to false' do
        let(:params) do
          {
            ensure: false
          }
        end

        it { is_expected.not_to contain_file('/etc/updatedb.conf') }
        it { is_expected.to contain_package('mlocate').with_ensure('absent') }
        it { is_expected.not_to contain_file('/etc/cron.daily/mlocate') }
        it { is_expected.not_to contain_service('mlocate-updatedb.timer') }
        it { is_expected.not_to contain_exec('force_updatedb') }

        case facts[:os]['release']['major']
        when '7'
          it { is_expected.not_to contain_systemd__dropin_file('period.conf') }
          it { is_expected.to contain_cron__job('mlocate-puppet').with_ensure('absent') }
          it { is_expected.to contain_file('/usr/local/bin/mlocate-wrapper').with_ensure('absent') }
        else
          it { is_expected.to contain_systemd__dropin_file('period.conf').with_ensure('absent') }
          it { is_expected.not_to contain_cron__job('mlocate-puppet') }
          it { is_expected.not_to contain_file('/usr/local/bin/mlocate-wrapper') }
        end
      end
    end
  end
end
