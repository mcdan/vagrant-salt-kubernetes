#!/bin/bash
vagrant ssh master -c "sudo runuser -l heketi -c '/opt/bin/heketi/heketi-cli -s http://localhost:9090 topology load --json /opt/conf/heketi/topology.json'"
