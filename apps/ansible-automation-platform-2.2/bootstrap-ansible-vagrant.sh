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

# Abort if vagrant-sshfs fails to mount /vagrant, since we need it to distribute
# the SSH key pairs.
if ! mountpoint /vagrant >/dev/null; then
  error 'could not find /vagrant mount point (check sshfs?)'
fi

# Create a shared SSH key pair, if it doesn't already exist, i.e. the first
# provisioned guest to run this script.
if [[ ! -f /vagrant/.ansible/id_rsa ]]; then
  mkdir /vagrant/.ansible/ || error "could not create /vagrant/.ansible/"
  ssh-keygen -t rsa -f /vagrant/.ansible/id_rsa -N '' -C Ansible
fi

# Abort if the SSH key files don't exist by now.
if [[ ! -f /vagrant/.ansible/id_rsa.pub ]]; then
  error 'missing ssh keys'
fi



################################################################################
#  Vagrant user config
################################################################################

# Copy the SSH key pair to the Vagrant user's SSH directory.
install -m 0755 -d "$HOME/.ssh"
install -m 0600 /vagrant/.ansible/id_rsa     "$HOME/.ssh/id_rsa"
install -m 0644 /vagrant/.ansible/id_rsa.pub "$HOME/.ssh/id_rsa.pub"

# Append the public key to the Vagrant user's authorized_keys file.
# * NOTE: This file should already exist in the Vagrant image, but the Vagrant
#   provisioner will typically replace it with a new locally generated key, but
#   we're being careful here not to overwrite it.
touch "$HOME/.ssh/authorized_keys"
sed -i '/Ansible/d' "$HOME/.ssh/authorized_keys"
cat /vagrant/.ansible/id_rsa.pub >> "$HOME/.ssh/authorized_keys"
chmod 0644 "$HOME/.ssh/authorized_keys"
restorecon -R "$HOME/.ssh/"

# When you connect to hosts for the first time, the SSH client will prompt you
# to accept/reject host server's fingerprint.  This auto-accepts it the very
# first time, and then validates afterward.
install -m 0644 \
  <(echo -e "Host *\n  StrictHostKeyChecking accept-new") \
  "$HOME/.ssh/config"



################################################################################
#  Ansible user config
################################################################################

# Create an Ansible system user and group (locally).
sudo useradd ansible \
  --system \
  --user-group \
  --create-home \
  --home-dir /var/lib/ansible \
  --comment "Ansible" \
  --shell /bin/bash

# Allow the Ansible user to sudo without a password.
echo 'ansible ALL=(ALL:ALL) NOPASSWD: ALL' \
  | sudo install -o root -g root -m 0440 /dev/stdin /etc/sudoers.d/ansible

# Create the Ansible user's SSH config directory and authorized_keys file.
sudo install -o ansible -g ansible -m 0755 -d ~ansible/.ssh
sudo install -o ansible -g ansible -m 0644 /vagrant/.ansible/id_rsa.pub ~ansible/.ssh/authorized_keys



################################################################################
#  Setup mDNS
################################################################################

# Install the Avahi daemon to allow mDNS queries.
sudo dnf install --assumeyes --quiet nss-mdns avahi

# Allow the mDNS service through the firewall.
sudo firewall-offline-cmd --add-service=mdns
sudo firewall-cmd --reload

# Enable the service at boot-time, and start it right now.
sudo systemctl enable --now avahi-daemon.service
