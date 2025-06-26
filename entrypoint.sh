#!/bin/bash

# Setup SSL certificates
mkdir -p /etc/nginx/certs
cd /etc/nginx/certs
mkcert -install
mkcert localhost

# Start nginx
nginx

# Start D-Bus and keyring for secret storage
mkdir -p /var/run/dbus
dbus-daemon --system --fork
export $(dbus-launch)
echo '' | gnome-keyring-daemon --unlock
echo '' | gnome-keyring-daemon --start

# Pass the token to openvscode-server user
if [ -n "$VSCODE_CONNECTION_TOKEN" ]; then
    # Run with specified token
    exec su openvscode-server -c "export DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS && cd /workspace && exec /home/.openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 3002 --connection-token='$VSCODE_CONNECTION_TOKEN'"
else
    # Run without token (will generate random token)
    exec su openvscode-server -c "export DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS && cd /workspace && exec /home/.openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 3002"
fi