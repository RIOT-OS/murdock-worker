## About

This repo contains a docker-compose.yml that can be used to run a Murdock worker
for RIOT.

The stack will include the following containers:

- one or more container(s) using `riot/murdock-worker` that runs the dwq job runner
- one ssh_bridge that connects via ssh to the murdock control node and provides
  access to its disque and redis instances
- a cache keep-alive node, which mounts the same tmpfs cache volume as the worker
  container. this allows the tmpfs to survive worker restarts
- a watchtower instance keeping all containers up-to-date.

## Murdock Worker requirements

- _at least_ four fast cores
- 1.5GB RAM per worker + 8GB RAM for ccache

## Prerequisites

- docker-compose
- git
- tarball with ssh config and credentials. ping kaspar on Matrix to get it!

## Installation

- Clone this repository to a location of your choice.
  `/srv/murdock-worker` is what I use.
- Extract ssh credentials. (there should be a folder named "ssh").
  - for current Murdock production, extract `ssh-current.tgz`
  - for ci-staging.riot-os.org, extract `ssh-staging.tgz`
  - ensure correct permissions: `chown root:root ssh/*`
- Copy `.env.example` to `.env`
- Edit `.env`. Change _at least_ the hostname.
- For Murdock ci-staging, comment these values (so defaults are used):

        MURDOCK_REMOTE_DISQUE_HOST_PORT=localhost:7711
        MURDOCK_REMOTE_REDIS_HOST_PORT=localhost:6379

## Configuration

If the worker is dedicated to being a Murdock worker, one worker per physical
core each running 4 jobs ensures the CPUs keep busy.
If RAM is an issue, go down on workers to one per two cores.
