#!/usr/bin/env bash

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

# Turns out, getting the CWD is actually much more nuanced than you'd think.
# To keep things short (and since I only care about Linux and GNU coreutils), 
# I'm not getting fancy.  However, here's a real solution if you need it:
#   * https://stackoverflow.com/a/246128
DIR=$(realpath -e -- "${BASH_SOURCE[0]}")
DIR=$(dirname "$DIR")
cd "$DIR" || error "could not resolve script dir"

# Install Docker CE, minikube, and AWX
./install-docker.sh   || error "docker ce installation failed"
./install-minikube.sh || error "minikube installation failed"
./install-awx.sh      || error "awx installation failed"
