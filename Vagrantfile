# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'shell'
#vagrant plugin install vagrant-reload
Vagrant.configure("2") do |config|
  VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))
  config.vm.box = "ubuntu/zesty64"
  #config.vm.box = "ubuntu/xenial64"

  numSlaves = 3
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    
  end
  networkPrefix="172.17.8"
  config.vm.define :master do |master|
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "#{networkPrefix}.100"
    master.vm.network "forwarded_port", guest: 6443, host: 6443
    #master.vm.provision "Upgrade Kernel", type: :shell, inline: "apt-get install -y --install-recommends linux-generic-hwe-16.04"
    #master.vm.provision :reload

    master.vm.provision "Set-Minion-ID", type: :shell, inline: "mkdir -p /etc/salt/minion.d/; echo master.local > /etc/salt/minion_id"
    master.vm.provision "Set-salt-master", type: :shell, inline: "echo master: master.local > /etc/salt/minion.d/master.conf"
    master.vm.provision "Set-Grains", type: :shell, path: "./controller-grain.sh" 

    master.vm.provision "Add-Salt-Apt-Key", type: :shell, inline: "wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | sudo apt-key add -"
    master.vm.provision "Add-Salt-Apt-Repo", type: :shell, inline: "echo deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main > /etc/apt/sources.list.d/saltstack.list"
    master.vm.provision "Apt-Install", type: :shell, inline: "apt-get update && apt-get upgrade -y && apt-get install -y rng-tools apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-api salt-cloud salt-master salt-minion salt-ssh salt-ssh git python-pygit2"

    master.vm.provision "Adobe-NTP", type: :shell, path: "./ntp-adobe.sh"

    master.vm.provision "Copy-master-confs", type: :file, source: "./master-configs", destination: "~/"
    master.vm.provision "Move-master-confs", type: :shell, inline: "mv /home/ubuntu/master-configs/* /etc/salt/master.d/"
    master.vm.provision "Restart-Salt-Master", type: :shell, inline: "systemctl restart salt-master"
    master.vm.synced_folder "salt-base/", "/etc/salt/base-file-root", owner: "root", group: "root"

    master.vm.provision "Get-Cert-Tools", type: :shell, path: "./getCertTools.sh" 
    hostip=''
    if RUBY_PLATFORM.include? 'linux'
      sh = Shell.new
      targetAdapter = (sh.system("netstat -rn") | sh.system("grep '^0.0.0.0 '") | sh.system("tr -s ' '") | sh.system("cut -d ' ' -f 8")).to_s
      sh = Shell.new
      hostip = (sh.system("ifconfig #{targetAdapter}") | sh.system("grep 'inet addr'") | sh.system("cut -d ':' -f2") | sh.system("cut -d ' ' -f1")).to_s
    end
    master.vm.provision "Add Master DNS Record", type: :shell, inline: "grep -q -F '#{networkPrefix}.100 master master.local' /etc/hosts || echo '#{networkPrefix}.100 master master.local' >> /etc/hosts"
    (1..numSlaves).each do |i|
      master.vm.provision "Add Node-#{i} DNS Record", type: :shell, inline: "grep -q -F '#{networkPrefix}.#{i + 100} node-#{i} node-#{i}.local' /etc/hosts || echo '#{networkPrefix}.#{i + 100} node-#{i} node-#{i}.local' >> /etc/hosts"
    end
    master.vm.provision "Copy-Cert-Json", type: :file, source: "./cert-generation/", destination: "~/cert-generation"
    master.vm.provision "Gen-Certs", type: :shell, path: "./generateCerts.sh", args: ["10.0.0.1,master.local,#{networkPrefix}.100,#{hostip}", "/etc/salt/base-file-root/file_root/certs"] 
    master.vm.provision "Salt-Public-IP", type: :shell, inline: "echo -e 'kubernetes:\\n  public-ip: #{hostip}' > /etc/salt/base-file-root/pillar_root/public-ip.sls" 
  end

  (1..numSlaves).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}.local"
      node.vm.network :private_network, ip: "#{networkPrefix}.#{i + 100}"

      #node.vm.provision "Upgrade Kernel", type: :shell, inline: "apt-get install -y --install-recommends linux-generic-hwe-16.04"
      #node.vm.provision :reload

      node.vm.provision "Set-Minion-ID", type: :shell, inline: "mkdir -p /etc/salt/minion.d/; echo node-#{i}.local > /etc/salt/minion_id"
      node.vm.provision "Set-Master-Name", type: :shell, inline: "echo master: master.local > /etc/salt/minion.d/master.conf"
      node.vm.provision "Set-Grains", type: :shell, path: "./worker-grain.sh" 

      node.vm.provision "Add-Salt-Apt-Key", type: :shell, inline: "wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | sudo apt-key add -"
      node.vm.provision "Add-Salt-Repos", type: :shell, inline: "echo deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main > /etc/apt/sources.list.d/saltstack.list"
      node.vm.provision "Apt-Install", type: :shell, inline: "apt-get update && apt-get upgrade -y && apt-get install -y rng-tools apt-transport-https ca-certificates curl software-properties-common ntp ntpdate ntp-doc salt-minion"
      diskPath = "%s/%s" % [VAGRANT_ROOT, "disks/storage-cluster-n#{i}.vdi"]
      unless File.exist?(diskPath)
        node.vm.provider "virtualbox" do |vb|
          vb.customize ['createmedium', 'disk', '--filename', diskPath, '--variant', 'Fixed', '--size', 20 * 1024]
          vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 4, '--device', 0, '--type', 'hdd', '--medium', diskPath]
        end
      end
      node.vm.provision "Add-Disks", type: :shell, path: "./vagrant-prepdrive.sh"
      node.vm.provision "Config-NTP", type: :shell, path: "./ntp-adobe.sh"
      node.vm.provision "Add Master DNS Record", type: :shell, inline: "grep -q -F '#{networkPrefix}.100 master master.local' /etc/hosts || echo '#{networkPrefix}.100 master master.local' >> /etc/hosts"
      (1..numSlaves).each do |j|
        node.vm.provision "Add Node-#{j} DNS Record", type: :shell, inline: "grep -q -F '#{networkPrefix}.#{j + 100} node-#{j} node-#{j}.local' /etc/hosts || echo '#{networkPrefix}.#{j + 100} node-#{j} node-#{j}.local' >> /etc/hosts"      
      end
    end
  end
end
