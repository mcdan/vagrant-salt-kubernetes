# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  numSlaves = 3
   
  config.vm.define :master do |master|
    master.vm.hostname = "master.cluster.test"
    master.vm.network :private_network, ip: "10.0.0.10"
    master.vm.provision "shell", inline: "apt-get update"
    master.vm.provision "shell", inline: "apt-get install -y apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-api salt-cloud salt-master salt-minion salt-ssh salt-ssh avahi-daemon libnss-mdns"
    master.vm.provision :shell, path: "./ntp-adobe.sh"
  end

  (1..numSlaves).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}.cluster.test"
      node.vm.network :private_network, ip: "10.0.0.#{i + 10}"
      node.vm.provision "shell", inline: "apt-get update"
      node.vm.provision "shell", inline: "apt-get install -y apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-api salt-cloud salt-minion salt-ssh salt-ssh avahi-daemon libnss-mdns"
      node.vm.provider "virtualbox" do |vb|
        disk = "./disks/gluster-s#{i}.vdi"
        unless File.exist?(disk)
          vb.customize ['createhd', '--filename', disk, '--variant', 'Fixed', '--size', 20 * 1024]
          vb.customize ['storageattach', :id,  '--storagectl', 'SCSI Controller', '--port', 4, '--device', 0, '--type', 'hdd', '--medium', disk]
        end
      end
      node.vm.provision :shell, path: "./vagrant-prepdrive.sh"
      node.vm.provision :shell, path: "./ntp-adobe.sh"
    end
  end
end

