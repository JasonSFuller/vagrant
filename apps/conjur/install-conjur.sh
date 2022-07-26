#!/bin/bash

echo
echo "#########################################################################"
echo "#                                                                       #"
echo "#   installing conjur (via docker and the conjur-quickstart project)    #"
echo "#                                                                       #"
echo "#########################################################################"
echo

function error { echo "ERROR: $*" >&2; exit 1; }

# basic setup
sudo dnf install -y vim git
install -m 0755 -d ~/src/
cd ~/src/ || error "could not cd to ~/src"

# ------------------------------------------------------------------------------
# Based on instructions from:
#   https://www.conjur.org/get-started/quick-start/oss-environment/
# ------------------------------------------------------------------------------

# step 0
git clone https://github.com/cyberark/conjur-quickstart.git
cd conjur-quickstart/ || error "could not cd to conjur-quickstart/"

# step 1
docker compose pull

# step 2
docker compose run --no-deps --rm conjur data-key generate > data_key

# step 3
export CONJUR_DATA_KEY="$(< data_key)"

# step 4
docker compose up -d
# verification
docker ps -a
# wait for the containers to get started before trying the next steps...
sleep 10

# step 5
docker compose exec conjur conjurctl account create myConjurAccount > admin_data

# step 6
docker compose exec client conjur init -u conjur -a myConjurAccount

# IMPORTANT:  The rest of the install is an exercise left to the reader, but
# to get started, continue on to the "Define Policy" section in the Quick Start:
#   https://www.conjur.org/get-started/quick-start/define-policy/
