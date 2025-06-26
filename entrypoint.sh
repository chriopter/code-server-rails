#!/bin/bash

# Setup SSL certificates
mkdir -p /etc/nginx/certs
cd /etc/nginx/certs
mkcert -install
mkcert localhost

# Start nginx
nginx

# Pass the token to openvscode-server user
if [ -n "$VSCODE_CONNECTION_TOKEN" ]; then
    # Run with specified token
    exec su openvscode-server -c "cd /workspace && exec /home/.openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 3002 --connection-token='$VSCODE_CONNECTION_TOKEN'"
else
    # Run without token (will generate random token)
    exec su openvscode-server -c "cd /workspace && exec /home/.openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 3002"
fi