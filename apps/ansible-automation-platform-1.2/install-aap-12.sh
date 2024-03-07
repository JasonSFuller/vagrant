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
# * NOTE: This step is important because it also creates the
#   /root/.ssh/known_hosts file to avoid typing "yes" to accept the SSH
#   fingerprint over and over during the install.
# * TODO: Grep'ing the inventory is a bit clumsy and error prone, but Ansible
#   has not been installed by setup.sh yet.
sudo install -m 0755 -d "/root/.ssh/"
grep -oE '\b[A-Za-z0-9\-\.]*\.local\b' /vagrant/inventory \
  | sort -u \
  | ssh-keyscan -f - 2>/dev/null \
  | sudo install -m 0600 /dev/stdin "/root/.ssh/known_hosts"

# Run the installer (as root).
printf "Running setup.sh.  This will take a few minutes.  To check progress, in another terminal:\n"
printf "  vagrant ssh tower\n"
printf "  sudo tail -F %s/%s\n" "$(realpath .)" "setup.out\n"
sudo ./setup.sh | tee setup.out

# The default Ansible venv in Tower is quite old, so lets create a few new ones.
# However, there are limits to this because RHEL 7 is EOL and only supports
# specific versions of Python, but we'll do our best with what we have.
printf "Installing a new venv (ansible-4)...\n"
sudo /vagrant/install-venv-ansible-4.sh
printf "Installing a new venv (ansible-6)...\n"
sudo /vagrant/install-venv-ansible-6.sh

# Give the services a bit to settle, backup/fix the original self-signed cert,
# otherwise Chrome based browsers will get an "ERR_SSL_KEY_USAGE_INCOMPATIBLE"
# error.
printf "Sleeping for 60 seconds for the services to settle...\n"
sleep 60
printf "Creating a new certificate...\n"
sudo cp -a /etc/tower/tower.cert{,.orig}
sudo openssl req -x509 -days 365 -subj /CN=localhost \
  -key /etc/tower/tower.key \
  -out /etc/tower/tower.cert
printf "Restarting the AAP service...\n"
sudo systemctl restart ansible-tower.service
