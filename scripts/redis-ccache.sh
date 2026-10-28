#!/bin/sh

# Run redis as the owner of this script on the host (i.e. the owner of the
# murdock-worker checkout), so the unix socket belongs to the same user as the
# murdock workers (see murdock-worker.sh).
uid=$(stat -c %u "$0")
gid=$(stat -c %g "$0")
if [ "$uid" = 0 ]; then
    echo "redis-ccache.sh: error: scripts/redis-ccache.sh is owned by root" \
         "on the host, refusing to run redis as root." \
         "The ccache redis runs as the owner of the murdock-worker checkout," \
         "make sure it belongs to a dedicated user (e.g. murdock) (see README.md)" >&2
    exit 1
fi

if [ "$(stat -c %u:%g /data)" != "$uid:$gid" ]; then
    chown -R "$uid:$gid" /data
fi

exec setpriv --reuid="$uid" --regid="$gid" --clear-groups docker-entrypoint.sh "$@"
