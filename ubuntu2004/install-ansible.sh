#!/bin/bash

# PURPOSE
#
# Distros need to maintain stability between releases, so they typically lock OS
# packages to specific major/minor versions that they support long-term.
# However, that necessarily means that they lag behind the rest of open-source
# projects.  Ansible has progressed quickly in the past few months (as of Mar
# 2022) with the introduction of Ansible 5.x and Red Hat's new Ansible
# Automation Platform spuring these changes along--not to mention the speed at
# which Ansible Galaxy modules are produced/updated.  Depending on the maturity
# of the project, these modules often only consider the compatibility with the
# latest versions of Ansible, and when you mix in the various dependencies,
# things can get out of hand quickly.
#
# Below is _one_ way you might control these changes in a pipeline.
#
# jfuller: tested 2022-03-09 on Ubuntu 20.04.4 LTS
#   https://app.vagrantup.com/ubuntu/boxes/focal64/versions/20220308.0.0
# Official Ansible installation instructions
#   https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html



# Basic error handler and some pre-flight checks
function error { echo "ERROR: $*" >&2; exit 1; }
if [[ "$(id -nu)" != "vagrant" ]]; then error "run as the vagrant user"; fi

# Be default in Ubuntu 20.04.4 LTS, you only get Python 3.8 w/o pip or venv, so
# we need to install them.  These should be stable, so you shouldn't need to pin
# versions here.  Likely, you will want the updates from the distro's vendor.
sudo apt -y install python3-pip python3-venv

# Create an Ansible folder for testing and create a Python virtual environment,
# so we don't disturb other Python dependencies elsewhere for the OS (or for the
# user's other projects).
mkdir -p "$HOME/src/ansible-example"
cd "$_" || error "failed to create dir"
python3 -m venv .venv
# shellcheck source=/dev/null
source ./.venv/bin/activate

# Have the package installer for Python (pip) updated itself inside the venv.
# * IMPORTANT:  Don't run this as root or mess with the OS installed versions.
#   Modules installed by the package manager (`apt`) should only be updated by
#   the package manager (and not pip).
pip install -U pip

# Install Ansible and other required modules. 
pip install -r /vagrant/requirements.txt

# ...and some optional modules:
pip install azure-cli

# Install the Ansible Galaxy modules and collections you want.  Typically,
# they're installed under $HOME/.ansible/, but most of the time you want to
# control version updates, so it's recommended to add/update them in your code
# base as necessary (after functional testing is completed).

### Install Ansible roles
#ansible-galaxy install -p ./modules example.example

### Install Ansible collections
ansible-galaxy collection install -p . \
  azure.azcollection

# * TODO add ansible.cfg (maybe?)
# * TODO pull a public repo (maybe?)

# Point the user in the right direction
cat << EOF
################################################################################

# Next steps
   
cd "$PWD/"
source ./.venv/bin/activate
ansible -m setup localhost

################################################################################
EOF