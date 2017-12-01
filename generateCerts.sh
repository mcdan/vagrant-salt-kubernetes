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

TEMP_DIR=$(mktemp -d)
mkdir -p ${targetLocation}
cd ${TEMP_DIR}
printf "Generating Root CA!\n"
NUM_WORKERS=${NUM_WORKERS:-3}
CERT_CONFIG_DIR=/home/ubuntu/cert-generation
cfssl gencert -initca ${CERT_CONFIG_DIR}/ca-csr.json | cfssljson -bare ca

for i in $(seq 1 ${NUM_WORKERS}); do
    export INSTANCENAME="node-${i}"
    INSTANCEIP="10.0.0.$((i + 10))"
    JSON_DATA=$(envsubst < ${CERT_CONFIG_DIR}/node-template.json)
    echo $JSON_DATA > ${INSTANCENAME}.json
    printf "Generating Node ${i} Client Cert and Key!\n"
    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=${CERT_CONFIG_DIR}/ca-config.json \
    -hostname=${INSTANCENAME},${INSTANCENAME}.local,${INSTANCEIP} \
    -profile=kubernetes \
    ${INSTANCENAME}.json | cfssljson -bare ${INSTANCENAME}
    rm ${INSTANCENAME}.json
done

printf "Generating Proxy Cert and Key!\n"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/kube-proxy-csr.json | cfssljson -bare kube-proxy


printf "Generating K8S Cert!\n"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -hostname=127.0.0.1,localhost,kubernetes.default,${otherhosts} \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/kubernetes-csr.json | cfssljson -bare kubernetes


printf "Generating Admin Cert and Key!\n"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${CERT_CONFIG_DIR}/ca-config.json \
  -profile=kubernetes \
  ${CERT_CONFIG_DIR}/admin-csr.json | cfssljson -bare admin

mv * ${targetLocation}
cd /
rm -rf ${CERT_CONFIG_DIR}/
rm -rf ${TEMP_DIR}
