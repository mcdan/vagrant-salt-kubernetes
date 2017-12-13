#!/bin/bash
sudo su
parted -s /dev/sdc mklabel gpt mkpart /dev/sdc1 'xfs' '0%' '100%'
mkfs.xfs /dev/sdc1
echo "/dev/sdc1 /data/sdc1 xfs defaults 0 0"  >> /etc/fstab
mkdir -p /data/sdc1 && mount -a
exit
