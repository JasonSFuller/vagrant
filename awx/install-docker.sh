#!/bin/bash

# https://docs.docker.com/engine/install/fedora/

function msg   { echo "$*"; }
function info  { msg "INFO: $*"; }
function warn  { msg "WARNING: $*" >&2; }
function error { msg "ERROR: $*" >&2; exit 1; }

if [[ "$(id -u)" != "0" ]]; then error "must run as root"; fi

# remove any old versions, if they exist
dnf -y remove \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

# make sure the core dnf plugins are installed, particularly config-manager
dnf -y install dnf-plugins-core

# install the docker repo for fedora
dnf config-manager --add-repo \
    'https://download.docker.com/linux/fedora/docker-ce.repo'

# install docker
dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

# enable and start the docker systemd service
systemctl enable --now docker

# if the vagrant user exists, add them to the docker group.
usermod -aG docker vagrant \
  || warn "could not add vagrant user to docker group"

# smoke test
if ! docker run hello-world \
  | GREP_COLORS='ms=0;30;102' grep -iE 'hello from docker!|$'
then
  echo 'ERROR: docker "hello-world" smoke test failed' >&2
  exit 1
fi
