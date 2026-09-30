#!/bin/sh

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
