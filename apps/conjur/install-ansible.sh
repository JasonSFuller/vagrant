#!/bin/bash

echo
echo "#########################################################################"
echo "#                                                                       #"
echo "#   installing ansible (inside the conjur-quickstart project)           #"
echo "#                                                                       #"
echo "#########################################################################"
echo

function error { echo "ERROR: $*" >&2; exit 1; }

# install ansible (inside a virtual env) for the conjur project
# IMPORTANT:  this may or (most likely) may not be the right directory for this,
#   but... keeping it because we discussed it on the call.
cd ~/src/conjur-quickstart/ || error "could not cd to ~/src/conjur-quickstart/"

# install python and pip
sudo dnf install -y python3 python3-pip

# install the python virtual environment
python3 -m venv .venv --prompt "ansible"

# activate the python virtual environment
# shellcheck source=/dev/null
source ./.venv/bin/activate

# Upgrade pip and install the required Python packages.
python3 -m pip install --upgrade pip
python3 -m pip install ansible paramiko

