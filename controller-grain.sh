#!/bin/bash
cat > /etc/salt/grains <<EOL
roles:
  - controller
EOL
