#!/bin/bash
NUM_WORKERS=${NUM_WORKERS:-3}
READY_WORKERS=0
nodeid=$(hostname | cut -d '-' -f2)
printf "Waiting for ${NUM_WORKERS} to be available\n"
while [ ${READY_WORKERS} -ne ${NUM_WORKERS} ]; do
  READY_WORKERS=0
  for i in $(seq 1 ${NUM_WORKERS}); do
    printf "Checking node-${i}.local"
    nc -w 1 node-${i}.local 24007 < /dev/null 
    if [ $? -eq 0 ]; then
      READY_WORKERS=$(( READY_WORKERS + 1))
      printf " - Ready.\n"
    else
      printf " - Gluster port not open.\n"
    fi
  done
  printf "*******\nAvailable peers: ${READY_WORKERS}\n*******\n"
done

letters=( {a..z} )
BRICK_PATH=${BRICK_PATH:-/data/sdc1/brick1}
used_letter=0
for i in $(seq 1 ${NUM_WORKERS}); do
  if [ ${i} -ne ${nodeid} ] ; then
     gluster peer probe node-${i}.local || true
  fi
  for j in $(seq $((i + 1)) ${NUM_WORKERS}); do
    if [ ${nodeid} -eq ${i} ] || [ ${nodeid} -eq ${j} ]; then
      echo "Creating Directories : ${letters[${used_letter}]} on node-${i} and node-${j}"
      mkdir -p ${BRICK_PATH}/gv${letters[${used_letter}]}
    fi
    used_letter=$(( used_letter + 1))
  done
done

if [ ${nodeid} -eq 1 ]; then
  sleep 20s
  used_letter=0
  for i in $(seq 1 ${NUM_WORKERS}); do
    for j in $(seq $((i + 1)) ${NUM_WORKERS}); do
      printf "Checking if gv${letters[${used_letter}]} exists "
      exists=$(sudo gluster volume status 2>&1 | grep "gv${letters[${used_letter}]}" | wc -l)
      if [ ${exists} -eq 0 ]; then
        echo " - Creating Gluster Volume : ${letters[${used_letter}]} on node-${i} and node-${j}\n"
        gluster volume create gv${letters[${used_letter}]} replica 2 node-${i}:/data/sdc1/brick1/gv${letters[${used_letter}]} node-${j}:/data/sdc1/brick1/gv${letters[${used_letter}]}
        gluster volume start gv${letters[${used_letter}]}
      else
        printf " - skipping as it seems to be created.\n"
      fi
      used_letter=$(( used_letter + 1))
    done
  done
fi

