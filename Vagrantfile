# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
ENV['ANSIBLE_NOCOWS'] = "1"

base_box = "chef/centos-6.5"
if ENV.has_key?('VENISON_UBUNTU')
    base_box = "ubuntu/trusty64"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "venison" do |venison|
    venison.vm.box = base_box
    venison.vm.hostname = "venison"
    venison.vm.network "forwarded_port", guest: 80, host: 9000
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "venison.yml"
    ansible.sudo = true
    ansible.verbose = "v"
  end
end
