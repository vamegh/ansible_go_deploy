# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'resolv'

@required_plugins = [ 'vagrant-vbguest',
                      'vagrant-hostmanager',
                      'vagrant-hosts',
                      'vagrant-hostsupdater']
require_relative "vagrant_requires.rb"

centos7_box_url   = 'https://atlas.hashicorp.com/puppetlabs/boxes/centos-7.1-64-nocm'

hosts = []
if File.exist?("hosts.yaml")
  hosts= YAML.load(File.read("hosts.yaml"), File::RDONLY)
end

Vagrant.configure("2") do |config|
  ## disable this to update the virtualbox guest plugin
  #config.vbguest.auto_update = false
  hosts.each do |host|
    config.vm.define host[:name] do |c|
      c.vm.box = host[:box]
      c.vm.box_url = centos7_box_url
      c.vm.hostname = host[:hostname]
      c.vm.network :private_network, ip: host[:ip], netmask: host[:netmask]
      ## Workaround for ansible && vagrant bug described here: https://github.com/mitchellh/vagrant/issues/6793
      c.vm.provision :shell, :path => "scripts/provision.sh"
      c.vm.provision :ansible_local do |ansible|
        ansible.provisioning_path = "/opt/vagrant/ansible"
        ansible.playbook = "playbook.yaml"
        ansible.verbose = true
        ansible.install = false
        ansible.limit = host[:name]
        ansible.groups = {
          "app" => ["app[1:10]"],
          "lb" => ["lb[1:10]"],
          "all:children" => ["app", "lb"],
        }
      end
      c.vm.provider :virtualbox do |vb|
        modifyvm_args = ['modifyvm', :id]
        modifyvm_args << "--memory" << host[:memory]
        modifyvm_args << "--cpus" << host[:cpu]
        modifyvm_args << "--name" << host[:hostname]
        modifyvm_args << "--ioapic" << "on"
        vb.customize(modifyvm_args)
      end

      if !host[:port_forward].empty? then
        host[:port_forward].each do |forward_rule|
          c.vm.network "forwarded_port", guest: forward_rule[:guest], host: forward_rule[:host], auto_correct: true
        end
      end

      c.vm.synced_folder ".", "/opt/vagrant"
    end
  end
end
