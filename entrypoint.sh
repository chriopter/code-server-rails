#!/bin/bash
set -e

# Ensure workspace directory exists
mkdir -p /home/coder/workspace
chown coder:coder /home/coder/workspace

# Start code-server as coder user
cd /home/coder
exec sudo -u coder env PASSWORD="$PASSWORD" PWD="/home/coder" code-server \
  --bind-addr 0.0.0.0:8443 \
  --cert /home/coder/certs/code-server.crt \
  --cert-key /home/coder/certs/code-server.key \
  --auth password \
  --user-data-dir /home/coder/.local/share/code-server \
  --disable-workspace-trust \
  /home/coder