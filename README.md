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
- murdock worker ssh key. ping kaspar on Matrix to get it!

## Installation

- Clone this repository to a location of your choice.
  `/srv/murdock-worker` is what I use.
- Copy `.env.example` to `.env`
- Edit `.env`. Change _at least_ the hostname.
- copy murdock worker ssh key to `ssh/`

By default, this will connect to "ci-staging", which is great for testing.
Once everything is working, change .env to connect to "ci-prod".

## Starting

`docker-compose up -d --scale worker=N`, with `N` being the number of concurrent
jobs. Each worker will need 2GB RAM (in addition to the 8GB for the shared tmpfs
for ccache).
Start with half the number of *physical* cores.

## Configuration

If the worker is dedicated to being a Murdock worker, one worker per physical
core each running 4 jobs ensures the CPUs keep busy, if enough RAM is available.
If RAM is an issue, go down on workers to one per two cores, possible increasing
`MURDOCK_JOBS` (to e.g., `8`).
