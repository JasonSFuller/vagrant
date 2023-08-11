#!/bin/bash

set -ex

podman login --tls-verify=false hub.local

podman pull  --tls-verify=false hub.local/ee-minimal-rhel8:latest
podman pull  --tls-verify=false hub.local/ee-supported-rhel8:latest

ansible-builder build -v3 -t packer-ee

podman push --tls-verify=false localhost/packer-ee hub.local/packer-ee

