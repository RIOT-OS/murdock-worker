#!/bin/sh

# When started as root, run the jobs as the owner of this script on the host
# (i.e. the owner of the murdock-worker checkout). Refuse to run the jobs as
# root if the checkout is owned by root.
if [ "$(id -u)" = 0 ]; then
    uid=$(stat -c %u "$0")
    gid=$(stat -c %g "$0")
    if [ "$uid" = 0 ]; then
        echo "murdock-worker.sh: error: scripts/murdock-worker.sh is owned by" \
             "root on the host, refusing to run the jobs as root." \
             "The jobs run as the owner of the murdock-worker checkout," \
             "make sure it belongs to a dedicated user (e.g. murdock) (see README.md)" >&2
        exit 1
    fi

    # fix ownership of caches created by a previous uid (e.g. ccache, git
    # cache, dlcache). /cache/redis is a separate volume owned by redis.
    # The migration started in November 2026, this code can be removed after
    # a reasonable amount of time (or everyone with murdock workers has migrated
    # them).
    for dir in /cache/* /cache/.[!.]*; do
        [ -e "$dir" ] || continue
        [ "$dir" != /cache/redis ] || continue
        if [ "$(stat -c %u:%g "$dir")" != "$uid:$gid" ]; then
            chown -R "$uid:$gid" "$dir"
        fi
    done

    exec setpriv --reuid="$uid" --regid="$gid" --clear-groups "$0" "$@"
fi

# create passwd entry for current uid, fix HOME variable
# only execute, if the current uid does not exist.
if ! id $(id -u) >/dev/null 2>/dev/null; then
    # create_user ignores the exit codes of groupadd/useradd, so check the
    # result instead of its exit code.
    # `create_user` is defined in `riotdocker-base/create_user.c`.
    create_user $(id -u) $(id -g)
    if ! id $(id -u) >/dev/null 2>/dev/null; then
        echo "murdock-worker.sh: warning: could not create a passwd entry for" \
             "uid $(id -u) (gid $(id -g)); tools that look up the user name" \
             "may fail" >&2
    fi
fi

export HOME=/data/riotbuild

# Check that the git cache directory can be used. `git-cache init` does not
# actually check if the directory exists and would fail at the first clone.
if [ -z "${GIT_CACHE_DIR}" ]; then
    echo "murdock-worker.sh: GIT_CACHE_DIR is not set (expected a directory in /cache)" >&2
    exit 1
fi

if ! mkdir -p "${GIT_CACHE_DIR}" 2>/dev/null || [ ! -w "${GIT_CACHE_DIR}" ]; then
    echo "murdock-worker.sh: git cache directory ${GIT_CACHE_DIR} is not" \
         "writable for uid $(id -u); check the permissions of the cache volume" >&2
    exit 1
fi

# use https instead of ssh for git.riot-os.org
git config --global url.https://git.riot-os.org/.insteadOf ssh://git.riot-os.org:3333/

exec $*
