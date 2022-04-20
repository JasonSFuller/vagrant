#!/bin/bash

# Fix the UseDNS defaults ("yes") in the ssh daemon's config, because it makes
# building the guest VM _painfully_ slow, at least on my system.  This fix won't
# help at build time, but it will speed up ssh logins afterward.
sudo sed -i 's/.*UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Fix the default timezone and locale.  Not really important, just a nit-pick.
sudo timedatectl set-local-rtc 0
sudo timedatectl set-timezone US/Eastern
sudo localectl set-locale LANG=en_US.utf8
sudo localectl set-keymap us
sudo localectl set-x11-keymap us

# Get the Tower's login creds and save it so we can use them later.
pass=$(sed -rn 's/.*Password:\s*([a-zA-Z0-9]+)\s*\"/\1/p' /etc/profile.d/ansible-tower.sh)
echo "TOWER_PASSWORD='$pass'"

if [[ ! -d /vagrant ]]; then
  echo "WARNING:  /vagrant dir missing; unable to write .tower.env or" >&2
  echo "  symlink f5 project.  Is the vagrant-sshfs plugin installed?" >&2
  echo "  If not, install it:  vagrant plugin install vagrant-sshfs" >&2
  exit 1
fi

# Symlink the local F5 project to a place Tower can pick it up later.
ln -sf /vagrant/f5 /var/lib/awx/projects/f5

# Write Tower config/creds to an easy to reach location.
cat <<- EOF > /vagrant/.tower.env
export TOWER_HOST='https://10.42.0.42'
export TOWER_USERNAME='admin'
export TOWER_PASSWORD='$pass'
export TOWER_VERIFY_SSL='false'
export TOWER_COLOR='false'
EOF
