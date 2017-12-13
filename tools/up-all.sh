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
PIDS_TO_WAIT_ON=()
for ((i=1; i <= NUM_NODES ; i++)); do
  vagrant up node-${i} &
  PIDS_TO_WAIT_ON+=($!)
done

PID_DONE=0
while [ ${PID_DONE} -lt ${#PIDS_TO_WAIT_ON[@]} ];do
  for pid in "${PIDS_TO_WAIT_ON[@]}"; do
    ps | grep ${pid} > /dev/null
    if [ $? -ne 0 ]; then
      PID_DONE=$((PID_DONE + 1))
    fi
  done
  printf "Waiting for vagrant to finish...\n"
  sleep 10s
done
printf "Vagrant Done, bootstrapping gluster cluster\n"
${DIR}/heketi-configure.sh
