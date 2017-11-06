#!/bin/bash
sudo su
cp /vagrant/ntp.conf /etc/ntp.conf
hwclock --systohc
#systemctl enable ntp.service
systemctl restart ntp.service
exit
