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
# versions here.  Likely, you will _want_ the updates from the distro's vendor.
sudo apt -y install python3-pip python3-venv

# Create an Ansible folder for testing and create a Python virtual environment,
# so we don't disturb other Python dependencies elsewhere on the OS (or for the
# user's other projects).
mkdir -p "$HOME/src/ansible-example"
cd "$_" || error "failed to create dir"
python3 -m venv .venv
# shellcheck source=/dev/null
source ./.venv/bin/activate

# Have the package installer for Python (pip) update itself inside the venv.
# * IMPORTANT:  Don't run this as root or mess with the OS installed versions.
#   Modules _installed_ by the package manager (`apt`) should **only** be
#   _updated_ by the package manager (and not pip).
pip install -U pip

# Install Ansible and other required modules. 
pip install -r /vagrant/requirements.txt

# Create a barebones Ansible config for this project.
cat << 'EOF' > ansible.cfg
[defaults]
collections_paths = ./ansible_collections
EOF

# Install the Ansible Galaxy collections you want.  Typically, they're installed
# under $HOME/.ansible/, but most of the time you want to control version
# updates, so it's recommended to add/update them in your code base as necessary
# (after functional testing is completed).
#ansible-galaxy install -p ./roles -r /vagrant/requirements-ansible-roles.yml
ansible-galaxy collection install -p . -r /vagrant/requirements-ansible-collections.yml

# The azure.azcollection Ansible collection requires additional Python modules.
# See the installation instructions for more detail:
# * https://galaxy.ansible.com/azure/azcollection
pip install -r ./ansible_collections/azure/azcollection/requirements-azure.txt

# IMPORTANT:  Installing the azure-cli Python module in the same venv as the
# azure.azcollection Ansible collection is a giant mess.  The Python
# dependencies in the collection are very old and are stomped all over by
# azure-cli.  So as a workaround, we're installing azure-cli outside of the venv
# since we're mostly using as a command-line tool anyway (and not part of a code
# base).  See the Github issue for more detail:
# * https://github.com/ansible-collections/azure/issues/477

# Exit the venv
deactivate
# Update the user's pip.
pip install --user --upgrade pip
# Install az (you'll find it in $HOME/.local/bin). 
# * NOTE:  You will have to logout/in of your current terminal session for $PATH
#   to be updated.
pip install --user azure-cli

# * TODO pull a public repo (maybe?)

# Point the user in the right direction
cat << EOF
################################################################################

# NOTE:  If \`echo "\$PATH\` does not contain \$HOME/.local/bin, you will need 
#   to logout/in for it to be updated.  Otherwise, some tools may not be found.

# Next steps
   
cd "$PWD/"
source ./.venv/bin/activate
ansible -m setup localhost

################################################################################
EOF