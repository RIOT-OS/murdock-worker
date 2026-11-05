## About

This repo contains a docker-compose.yml that can be used to run a Murdock worker
for RIOT.

The stack will include the following containers:

- one or more container(s) using `riot/murdock-worker` that runs the dwq job runner
- one ssh_bridge that connects via ssh to the murdock control node and provides
  access to its disque and redis instances
- one redis instance acting as ccache storage backend
- a watchtower instance keeping all containers up-to-date.

## Murdock Worker requirements

- _at least_ four fast cores
- 2GB RAM per worker + 8GB RAM for ccache

## Prerequisites

- docker-compose
- git
- murdock worker ssh key. Ping kaspar on Matrix to get it!

## Installation

- Create a new user called `murdock`
  ```shell
  sudo useradd -r -d /srv/murdock-worker murdock
  ```
- Clone this repository to a location of your choice.
  `/srv/murdock-worker` is what I use. To make sure the directory belongs to
  the new user, run the following commands:
  ```shell
  sudo mkdir /srv/murdock-worker
  sudo chown murdock:murdock /srv/murdock-worker
  sudo -u murdock -s
  git clone https://github.com/RIOT-OS/murdock-worker /srv/murdock-worker
  ```
  The jobs and the ccache redis run as the owner of the `scripts/murdock-worker.sh`
  and `scripts/redis-ccache.sh` scripts (e.g. the dedicated `murdock` user).
  Make sure to perform checkouts and updates as `murdock` and not as `root`
  to avoid changing the owner.
  If the scripts are owned by root, the containers refuse to start.
- Copy `.env.example` to `.env`
- Edit `.env`. Change _at least_ the hostname.
- Copy the murdock worker ssh key to `ssh/id_rsa_murdock-slave`

By default, this will connect to "ci-staging", which is great for testing.
Once everything is working, change .env to connect to "ci-prod".

## Starting and Scaling

`docker compose up -d --scale worker=N`, with `N` being the number of concurrent
workers. Each worker will need at least 2GB RAM (`MURDOCK_BUILD_TMPFS_GIGS`)
for its tmpfs and one shared >=16GB `MURDOCK_CCACHE_MAXSIZE_GIGS` chunk
for the ccache buffer in the redis container.
The maximum depends on the amount of RAM that is available, but realistically
`N` should not exceed the number of physical CPU cores.
Each worker runs build tasks with 4 `make` jobs in parallel. You can change
that in the `.env` file.
If the RAM is limited but CPU resources remain available, you can increase
the number of concurrent `make` jobs to e.g. `MURDOCK_JOBS=8`.
Note that not all RIOT builds gain from much higher number of jobs.

### Inside an LXC container

Running docker inside LXC containers works very much out of the box. E.g. on Proxmox additionally
the fuse and the nesting capabilities need to be enabled and `fuse-overlayfs` needs to be installed.
The reason is that native `overlayfs` cannot be used for rootless operation (or when the user
launching the docker containers is only root within an LXC container namespace). Without
`fuse-overlayfs` the VFS storage driver is used instead, which performs a deep copy of all lower
layers into the upper layers. With a large number of layers, this increases storage consumption
too much to be practical.

**Note**: Expect that `fuse-overlayfs` will throttle the performance of your worker quite a bit.

**Also note**: The metrics reported by the vector service will include RAM and CPUs available to the
bare host (e.g. the Proxmox running the LXC container which runs the docker containers). To fix
that, filtered versions of various `/proc/` files can be provided by lxcfs that can be bind-mounted
into the docker container. To do so automatically, run
`docker compose -f docker-compose.yml -f docker-compose.lxc.yml up -d --scale worker=N` instead of
just `docker compose up -d --scale worker=N`.
