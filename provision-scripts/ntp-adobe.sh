#!/bin/bash
sudo su
cp /vagrant/provision-scripts/ntp.conf /etc/ntp.conf
hwclock --systohc
#systemctl enable ntp.service
systemctl restart ntp.service
exit
