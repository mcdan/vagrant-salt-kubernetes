#!/bin/bash
cat > /etc/salt/grains <<EOL
roles:
  - worker
EOL
