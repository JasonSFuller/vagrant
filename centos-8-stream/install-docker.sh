#!/bin/bash

# 2021-11-22 - Install docker-ce [mostly] according to the docker instructions:
#   https://docs.docker.com/engine/install/centos/

if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: must run as root" >&2
  echo "HINT:  sudo $0"
  exit 1
fi

dnf remove -y \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine

dnf install -y yum-utils

yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y docker-ce docker-ce-cli containerd.io

systemctl enable --now docker

usermod -a -G docker vagrant

cat <<- 'MESSAGE'

################################################################################
#                                                                              #
#   IMPORTANT:  You must log out/in for the Linux group permissions to take    #
#   effect.  Otherwise, you might not have access to the local Docker socket   #
#   to issue commands and receive these types of errors:                       #
#                                                                              #
#     $ docker ps                                                              #
#     Got permission denied while trying to connect to the Docker daemon       #
#     socket at unix:///var/run/docker.sock: Get                               #
#     "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json": dial unix     #
#     /var/run/docker.sock: connect: permission denied                         #
#                                                                              #
################################################################################

MESSAGE
