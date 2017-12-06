#!/bin/bash
vagrant ssh master -c "runuser -l heketi -c '/opt/bin/heketi/heketi-cli -s http://localhost:9090 topology load --json /home/ubuntu/heketi/topology.json'"
