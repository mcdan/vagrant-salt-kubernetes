# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  numSlaves = 3
   
  config.vm.define :master do |master|
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "10.0.0.10"
    master.vm.provision "shell", name: "Set Mintion ID", inline: "mkdir -p /etc/salt/minion.d/; echo master.local > /etc/salt/minion_id"
    master.vm.provision "shell", name: "Set Salt Master DNS Name", inline: "echo master: master.local > /etc/salt/minion.d/master.conf"
    master.vm.provision "shell", name: "Add latest Salt key", inline: "wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | sudo apt-key add -"
    master.vm.provision "shell", name: "Add new Salt repos", inline: "echo deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main > /etc/apt/sources.list.d/saltstack.list"
    master.vm.provision "shell", name: "Apt Installs", inline: "apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-api salt-cloud salt-master salt-minion salt-ssh salt-ssh avahi-daemon libnss-mdns git python-pygit2"
    master.vm.provision "shell", name: "Adobe NTP Setup", path: "./ntp-adobe.sh"
    master.vm.provision "file",  source: "./master-configs", destination: "~/"
    master.vm.provision "shell", name: "Move confs to Salt Master directory", inline: "mv /home/ubuntu/master-configs/* /etc/salt/master.d/"
    master.vm.provision "shell", name: "Restart Salt Master to get new config", inline: "systemctl restart salt-master"
    master.vm.synced_folder "salt-base/", "/etc/salt/base-file-root", owner: "root", group: "root"
  end

  (1..numSlaves).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.provision "shell", name: "Set Mintion ID", inline: "mkdir -p /etc/salt/minion.d/; echo node-#{i}.local > /etc/salt/minion_id"
      node.vm.provision "shell", name: "Set Salt Master DNS Name", inline: "echo master: master.local > /etc/salt/minion.d/master.conf"
      node.vm.provision "shell", name: "Add latest Salt key", inline: "wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | sudo apt-key add -"
      node.vm.provision "shell", name: "Add new Salt repos", inline: "echo deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main > /etc/apt/sources.list.d/saltstack.list"
      node.vm.network :private_network, ip: "10.0.0.#{i + 10}"
      node.vm.provision "shell", name: "Apt Installs", inline: "apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-minion avahi-daemon libnss-mdns"
      node.vm.provider "virtualbox" do |vb|
        disk = "./disks/gluster-s#{i}.vdi"
        unless File.exist?(disk)
          vb.customize ['createhd', '--filename', disk, '--variant', 'Fixed', '--size', 20 * 1024]
          vb.customize ['storageattach', :id,  '--storagectl', 'SCSI Controller', '--port', 4, '--device', 0, '--type', 'hdd', '--medium', disk]
        end
      end
      node.vm.provision :shell, name: "Configure New Disks", path: "./vagrant-prepdrive.sh"
      node.vm.provision :shell, name: "Adobe NTP Setup", path: "./ntp-adobe.sh"
    end
  end
end
