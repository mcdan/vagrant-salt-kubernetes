#!/bin/bash
set -euo pipefail
#set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NUM_NODES=${NUM_WORKERS:-}
if [[ -z "${NUM_NODES=}" ]]; then
  printf "Please set NUM_WORKERS in the enviornment, e.g.:\nexport NUM_WORKERS=4\n"
  exit 1
fi

vagrant up master
for ((i=1; i <= NUM_NODES ; i++)); do
  vagrant up node-${i} &
done


wait
printf "Vagrant Done, bootstrapping gluster cluster\n"
${DIR}/heketi-configure.sh
