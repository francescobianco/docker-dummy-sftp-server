require 'spec_helper'
require 'dockerspec'
require 'dockerspec/serverspec'

describe docker_build('.', tag: 'dummy-sftp-server') do
  it { should have_entrypoint '/docker-entrypoint.sh' }
  it { should have_cmd ['/usr/sbin/sshd', '-D', '-e'] }
  it { should have_env 'LANG' }
  it { should have_env 'TZ' }
  it { should have_env 'FOLDER' }
  it { should have_env 'PORT' }

  # Travis is quite slow
  wait = ENV['TRAVIS'] ? 10 : 2

  context "using password" do
    describe docker_run('dummy-sftp-server', wait: wait, family: :alpine, env: {
      USERNAME: 'sftp_test',
      PASSWORD: 'password',
      PORT: 12345,
      CHROOT: 0
    }) do
      its(:stderr, retry: 10) { should include 'Server listening on 0.0.0.0 port 12345.' }

      # This shouldn't be there anymore
      its(:stderr) { should_not include 'Creating mailbox file' }

      describe 'SSHD' do
        describe package('openssh') do
          it { should be_installed }
        end

        it 'sshd' do
          expect(command('which sshd').exit_status).to eq 0
        end

        describe process('/usr/sbin/sshd') do
          it { should be_running }
          its(:args) { should include "-D" }
          its(:args) { should include "-e" }
        end

        describe port(12345) do
          it { should be_listening.with('tcp') }
        end

        describe file('/etc/ssh/sshd_config') do
          it { should exist }
          it { should be_file }
          its(:content) { should match(/^MaxAuthTries 100000$/) }
          its(:content) { should match(/^Port 12345/) }
        end
      end

      context "login with sftp" do
        describe command('apk add -U sshpass') do
          its(:stdout) { should include 'Installing sshpass' }
        end

        describe command('echo version | sshpass -p password sftp -o StrictHostKeyChecking=no -P 12345 sftp_test@localhost') do
          its(:stderr) { should include 'Connected to' } # Newer sftp says: 'Connected to sftp@localhost' older says 'Connected to localhost'
          its(:stdout) { should include 'SFTP protocol version 3' }
        end
      end

      describe 'Private SSH host keys' do
        %w(ssh_host_rsa_key ssh_host_dsa_key ssh_host_ecdsa_key).each do |private_key_file|
          describe file("/etc/ssh/#{private_key_file}") do
            it { should exist }
            it { should be_file }
            it { should be_mode 600 }
          end
        end
      end
    end
  end
end




