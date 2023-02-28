#!/bin/sh

mkdir -p /root/.ssh
cp /ssh/* /root/.ssh
chown root:root /root/.ssh
chmod 0600 /root/.ssh/id_*

exec /usr/bin/autossh \
      -M 0 -C -N -o ServerAliveInterval=60 -o ServerAliveCountMax=2 \
      -Lssh_bridge:7711:${MURDOCK_REMOTE_DISQUE_HOST_PORT:-disque:7711} \
      -Lssh_bridge:6379:${MURDOCK_REMOTE_REDIS_HOST_PORT:-redis:6379} \
      -Lssh_bridge:8687:${MURDOCK_REMOTE_VECTOR_HOST_PORT:-vector:8687} \
      ${MURDOCK_SSH_HOST}
