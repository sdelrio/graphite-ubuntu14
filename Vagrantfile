# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.define "graphite"  do |graphite|
      graphite.vm.hostname = "graphite.vagrant.vm"
      graphite.vm.box = "ubuntu/trusty64"
      graphite.vm.provider "virtualbox" do |vb|
            vb.customize ["modifyvm", :id, "--cpus", "1"]
            vb.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
            vb.customize ["modifyvm", :id, "--memory", "1024"]
            vb.customize ["modifyvm", :id, "--natnet1", "192.168.44/24"]
      end
      graphite.vm.provision :shell, :path => "graphite.sh"
#     graphite.vm.provision :shell, :path => "collectdubuntu.sh"
      graphite.vm.network "forwarded_port", guest: 80, host: 80
      graphite.vm.network "forwarded_port", guest: 8080, host: 8080
      graphite.vm.network "forwarded_port", guest: 2003, host: 2003
      graphite.vm.network "forwarded_port", guest: 2004, host: 2004
      graphite.vm.network "forwarded_port", guest: 7002, host: 7002
      graphite.vm.network "forwarded_port", guest: 5000, host: 5000
   end

end
