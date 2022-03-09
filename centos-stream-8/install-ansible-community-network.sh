#!/bin/bash


# install a virtual environment so we don't disturb other python dependencies 
# elsewhere for the OS (or for the user)
#python3 -m venv ./venv
#source ./venv/bin/activate

# when done...
#deactivate

# update pip3, as per the ansible doc recommendations
pip3 install --user --upgrade pip

# install ansible
#pip3 install ansible paramiko

# install the exact ftd_install requirements
# NOTE: installs an old version of ansible.  recommend using ansible galaxy instead.
#pip3 install firepower-kickstart
#pip3 install -r requirements.txt

pip3 install --user ansible ansible-lint paramiko firepower-kickstart


# install the ansible galaxy community network collection
# NOTE: this installs locally for $USER (and not in the venv)
# NOTE: Ansible versions before 2.9.10 are not supported.
ansible-galaxy collection install community.network


docker pull ciscodevnet/ftd-ansible:release-v0.3.1


