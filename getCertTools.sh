#!/bin/bash
mkdir -p ~/k8s-tools
cd ~/k8s-tools
if [ ! -f /usr/local/bin/cfssl ]; then
  wget -q --show-progress --https-only --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
  chmod +x cfssl_linux-amd64
  sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
else
  printf "cfssl already installed.\n"
fi

if [ ! -f /usr/local/bin/cfssljson ]; then
  wget -q --show-progress --https-only --timestamping https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  chmod +x cfssljson_linux-amd64
  sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
else
  printf "cfssljson already installed.\n"
fi

rm -rf ~/k8s-tools
