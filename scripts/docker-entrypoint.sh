#!/bin/sh
set -e

# If not root, Kubernetes already applied the correct runAsUser — exec directly
if [ "$(id -u)" -ne 0 ]; then
    exec "$@"
fi

# Running as root: remap node UID/GID to match host user if needed
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

exec gosu node "$@"
