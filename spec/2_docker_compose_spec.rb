require 'spec_helper'
require 'dockerspec'
require 'dockerspec/serverspec'

wait = ENV['TRAVIS'] ? 30 : 1
describe docker_compose('docker-compose.yml', wait: wait) do
  its_container(:sftp) do
    its(:stderr, retry: 15) { should include 'Server listening on 0.0.0.0 port 2238.' }

    describe port(2238) do
      it { should be_listening.with('tcp') }
    end

    describe file('/chroot/in/test.txt') do
      it { should exist }
      it { should be_file }
      its(:content) { eq file_fixture('sftp/test.txt') }
    end

    describe command("cd /tmp; echo 'get -r *' | sftp -v -i /etc/ssh/keys/ssh-key -o StrictHostKeyChecking=no -P 2238 sftp@localhost") do
      # Connects succesfully
      its(:stderr) { should include 'Connected to' }

      # chroot should work so only /in/test.txt is visible
      its(:stdout) { should eq "sftp> get -r *\nFetching /in/test.txt to test.txt\n" }
    end
  end
end
