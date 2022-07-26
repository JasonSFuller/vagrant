#!/usr/bin/env bash

echo
echo "#########################################################################"
echo "#                                                                       #"
echo "#   installing docker                                                   #"
echo "#                                                                       #"
echo "#########################################################################"
echo

function msg   { echo "$*"; }
function info  { msg "INFO: $*"; }
function warn  { msg "WARNING: $*" >&2; }
function error { msg "ERROR: $*" >&2; exit 1; }

if [[ "$(id -u)" != "0" ]]; then error "must run as root"; fi

# Update the OS
dnf -y update

# Install packages to make ourselves comfortable.
packages=(
  vim                           # need a good editor (plus, muscle memory)
  bind-utils                    # dns lookups, mostly `host` and `dig`
  bash-completion               # typing is hard, plus `kubectl` completion
  policycoreutils-python-utils  # for selinux utils, because you never know
  @development-tools            # group install dev tools, mostly `git` and `make`
  @core                         # just in case any other "normal" stuff is missing
)
dnf -y install "${packages[@]}"



################################################################################
# https://docs.docker.com/engine/install/centos/
################################################################################

# remove any old versions, if they exist
yum -y remove \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine

# yum-config-manager makes adding the docker repo easy
yum -y install yum-utils
yum-config-manager \
  --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# install docker
yum -y install \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

# enable and start the docker systemd service
systemctl enable --now docker

# if the vagrant user exists, add them to the docker group.
usermod -aG docker vagrant \
  || error "could not add vagrant user to docker group"

# smoke test
docker run hello-world \
  | GREP_COLORS='ms=0;30;102' grep -iE 'hello from docker!|$'

if [[ ${PIPESTATUS[0]} != "0" || ${PIPESTATUS[1]} != "0" ]]; then
  error 'docker "hello-world" smoke test failed'
fi
