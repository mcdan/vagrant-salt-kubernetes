#!/bin/bash
add-apt-repository -y ppa:gluster/glusterfs-3.12
apt-get update
apt-get install -y glusterfs-server

letters=( {a..z} )
nodeid=$(hostname | cut -d '-' -f2)
NUM_WORKERS=${NUM_WORKERS:-3}
BRICK_PATH=${BRICK_PATH:-/data/brick1}
used_letter=0
for i in $(seq 1 ${NUM_WORKERS}); do
  if [ ${i} -ne ${nodeid} ] ; then
     gluster peer probe node-${i}.local || true
  fi
  for j in $(seq $((i + 1)) ${NUM_WORKERS}); do
    if [ ${nodeid} -eq ${i} ] || [ ${nodeid} -eq ${j} ]; then
      echo "Creating Volume : ${letters[${used_letter}]} on node-${i} and node-${j}"
      mkdir -p ${BRICK_PATH}/gv${letters[${used_letter}]}
    fi
    used_letter=$(( used_letter + 1))
  done
done

