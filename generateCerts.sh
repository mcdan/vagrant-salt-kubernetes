#!/bin/bash
otherhosts=$1
targetLocation=$2
if [ $# -ne 2 ]; then
  printf "Send two arguments: extrahosts for api and target for certs when done\n"
  exit -1
fi

if [ $(ls -al ${targetLocation}/*.pem | wc -c) -ne 0 ]; then
  printf "Refusing to overwrite existing certs, cause I'm chicken."
  exit -2
fi

mkdir ~/k8s-certs
mkdir -p ${targetLocation}
cd ~/k8s-certs
CERT_CONFIG_DIR=/home/ubuntu/cert-generation
cfssl gencert -initca ${CERT_CONFIG_DIR}/ca-csr.json | cfssljson -bare ca
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/admin-csr.json | cfssljson -bare admin

for i in {1..3}; do
    export INSTANCENAME="node-${i}"
    INSTANCEIP="10.0.0.$((i + 10))"
    JSON_DATA=$(envsubst < ${CERT_CONFIG_DIR}/node-template.json)
    echo $JSON_DATA > ${INSTANCENAME}.json
    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=${CERT_CONFIG_DIR}/ca-config.json \
    -hostname=${INSTANCENAME},${INSTANCEIP} \
    -profile=kubernetes \
    ${INSTANCENAME}.json | cfssljson -bare ${INSTANCENAME}
    rm ${INSTANCENAME}.json
done

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/kube-proxy-csr.json | cfssljson -bare kube-proxy


cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -hostname=127.0.0.1,localhost,kubernetes.default,${otherhosts} \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/kubernetes-csr.json | cfssljson -bare kubernetes
mv *.pem ${targetLocation}
cd /
rm -rf ~/k8s-certs
