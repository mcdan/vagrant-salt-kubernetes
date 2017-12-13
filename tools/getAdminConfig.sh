#!/bin/bash
set -euo pipefail
port=$(vagrant ssh-config master | grep Port | tr -s " " | cut -d ' ' -f3)
idfile=$(vagrant ssh-config master | grep IdentityFile | tr -s " " | cut -d ' ' -f3)
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P ${port} -i ${idfile} ubuntu@127.0.0.1:/opt/k8s/conf/admin.kubeconfig .
