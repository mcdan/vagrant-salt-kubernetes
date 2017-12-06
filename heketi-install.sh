#!/bin/bash
set -euo pipefail
set -x
PUBLIC_KEY=$1
PRIVATE_KEY=$2
CONFIG_FILE=$4
SERVICE_FILE=$3
HEKETI_VERSION=5.0.0
USER_EXISTS=$(cat /etc/passwd | grep heketi | wc -l)
if [ ${USER_EXISTS} -ne 1 ]; then
  useradd heketi -m -d /home/heketi
fi

if [ -f ${CONFIG_FILE} -a ! -f /opt/conf/heketi/heketi.json ]; then
  mkdir -p /opt/conf/heketi
  mv ${CONFIG_FILE} /opt/conf/heketi/heketi.json
fi

if [ "$(md5sum ${CONFIG_FILE} | cut -d " " -f 1)" != "$(md5sum /opt/conf/heketi/heketi.json | cut -d " " -f 1)" ]; then
  mv ${CONFIG_FILE} /opt/conf/heketi/heketi.json
fi


if [ -f ${SERVICE_FILE} -a ! -f /etc/systemd/system/heketi.service ]; then
  mv ${SERVICE_FILE} /etc/systemd/system/heketi.service
fi

if [ "$(md5sum ${SERVICE_FILE} | cut -d " " -f 1)" != "$(md5sum /etc/systemd/system/heketi.service | cut -d " " -f 1)" ]; then
  mv ${SERVICE_FILE} /etc/systemd/system/heketi.service
  systemctl daemon-reload
fi

if [ -f $1 -a -f $2 ]; then
  mkdir -p /home/heketi/.ssh/
  mv $1 /home/heketi/.ssh/id_rsa.pub
  mv $2 /home/heketi/.ssh/id_rsa
  chmod -R 600 /home/heketi/.ssh/*
  chown -R heketi:heketi /home/heketi
fi

if [ ! -f /home/heketi/.ssh/id_rsa.pub ] || [ ! -f /home/heketi/.ssh/id_rsa ]; then
  >&2 echo "Could not find ssh keys for heketi user"
  exit 1
fi

mkdir -p /opt/bin/heketi
if [ ! -f /opt/bin/heketi/heketi ]; then
  wget https://github.com/heketi/heketi/releases/download/v${HEKETI_VERSION}/heketi-v${HEKETI_VERSION}.linux.amd64.tar.gz -O /opt/bin/heketi.tar.gz
  tar -xvf /opt/bin/heketi.tar.gz --strip-components=1 -C /opt/bin/heketi
  rm /opt/bin/heketi.tar.gz
fi

chown -R heketi:heketi /opt/bin/heketi
mkdir -p /opt/data/heketi
chown -R heketi:heketi /opt/data/heketi

if [ ! -f /etc/systemd/system/heketi.service ]; then
  >&2 echo "Systemd doesn't know about heketi, something is wrong."
  exit 4
fi

systemctl start heketi.service
