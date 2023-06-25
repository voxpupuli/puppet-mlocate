# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'mlocate class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'works idempotently with no errors' do
      pp = <<-EOS
      class { 'mlocate':}
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/updatedb.conf') do
      it { is_expected.to be_file }
    end
  end

  context 'forceing an mlocate run' do
    # Using puppet_apply as a helper
    it 'works idempotently with no errors' do
      pp = <<-EOS
      class { 'mlocate':
        force_updatedb => true,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/usr/bin/locate /etc/passwd') do
      its(:stdout) { is_expected.to match %r{/etc/passwd} }
    end
  end

  context 'mlocate absent' do
    # Using puppet_apply as a helper
    it 'works idempotently with no errors' do
      pp = <<-EOS
      class { 'mlocate':
        ensure => false,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe package(%w[mlocate plocate]) do
      it { is_expected.not_to be_installed }
    end
  end
end
