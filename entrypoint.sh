#!/bin/bash
set -e

# Ensure workspace directory exists
mkdir -p /home/coder/workspace
chown coder:coder /home/coder/workspace

# Create certificates if they don't exist
if [ ! -f /home/coder/certs/code-server.crt ] || [ ! -f /home/coder/certs/code-server.key ]; then
    echo "Generating self-signed certificates..."
    mkdir -p /home/coder/certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /home/coder/certs/code-server.key \
        -out /home/coder/certs/code-server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
        2>/dev/null
    chown -R coder:coder /home/coder/certs
    echo "Certificates generated successfully"
fi

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