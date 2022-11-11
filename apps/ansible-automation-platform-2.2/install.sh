#!/bin/bash

function error { echo "ERROR: $*" >&2; exit 1; }



################################################################################
#  Pre-flight checks
################################################################################

# We're making a few assumptions in this script (like password-less sudo
# access), so make sure we're logged in as the Vagrant user.
if [[ "$(id -un)" != "vagrant" ]]; then
  error "must run as the vagrant user"
fi

# Abort if vagrant-sshfs fails to mount /vagrant, since we need it to copy
# files.
if ! mountpoint /vagrant >/dev/null; then
  error 'could not find /vagrant mount point (check sshfs?)'
fi

# Abort if the '.env' or 'secrets.yaml' files are missing.
if [[ ! -f /vagrant/.env ]]; then
  error 'missing .env file (see README.md)'
fi
if [[ ! -f /vagrant/secrets.yaml ]]; then
  error 'missing secrets.yaml file (see README.md)'
fi


################################################################################
#  Install
################################################################################

# Copy the install bundle and checksum to the Vagrant user's home directory.
cd ~ || error 'could not find the vagrant home dir (uh, what?)'
cp /vagrant/ansible-automation-platform-setup-bundle-* .

# Validate the install bundle's checksum.
if ! sha256sum -c ansible-automation-platform-setup-bundle-*.sha256; then
  error "invalid checksum"
fi

# Extract the tarball.
tar xf ansible-automation-platform-setup-bundle-*.tar.gz
cd ansible-automation-platform-setup-bundle-*/ \
  || error "could not find the installation directory"

# Since the installer (setup.sh) is simply a wrapper for Ansible playbooks, it
# expects the inventory file to be in a specific location relative to itself and
# the other directories, so symlink it here.
if [[ ! -L inventory ]]; then
  if [[ -f inventory ]]; then mv inventory{,.orig}; fi
  ln -s /vagrant/inventory .
fi

# Validate Ansible can reach all the *.local hosts in the inventory.
# * NOTE: This step is important because it also creates the ~/.ssh/known_hosts
#   file to avoid typing "yes" to accept the SSH fingerprint over and over
#   during the install.
# * TODO: Grep'ing the inventory is a bit clumsy and error prone, but Ansible
#   has not been installed yet (by setup.sh).
sudo install -m 0755 -d "$HOME/.ssh/"
grep -oE '\b[A-Za-z0-9\-\.]*\.local\b' /vagrant/inventory \
  | sort -u \
  | ssh-keyscan -f - 2>/dev/null \
  | sudo install -m 0600 /dev/stdin "$HOME/.ssh/known_hosts"

# Run the installer (as root).
printf "Running setup.sh.  This may take a few minutes.  For progress, check:\n"
printf "  %s/%s\n" "$(realpath .)" "setup.out"
sudo ./setup.sh -e '@/vagrant/secrets.yaml' > setup.out
