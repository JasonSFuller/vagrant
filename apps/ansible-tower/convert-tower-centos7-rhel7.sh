#!/bin/bash

# Source: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/converting_from_an_rpm-based_linux_distribution_to_rhel/index

function error { echo "ERROR: $*" >&2; exit 1; }

# Provides two env vars:
# - RED_HAT_SUBSCRIPTION_MGR_USER
# - RED_HAT_SUBSCRIPTION_MGR_PASS
if [[ ! -f /vagrant/.env ]]; then
  error "environment file missing (check /vagrant/.env exists and /vagrant is sshfs mounted inside the tower guest)"
fi
source /vagrant/.env

# If using Centos 8 (waaay EOL and moved to Stream), then modify the yum 
# repos.  However, this particular host is CentOS 7, so we're skipping it.
#sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#sed -i 's|#baseurl=http://mirror.centos.org|baseurl=https://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release https://www.redhat.com/security/data/fd431d51.txt
curl --create-dirs -o /etc/rhsm/ca/redhat-uep.pem https://ftp.redhat.com/redhat/convert2rhel/redhat-uep.pem
curl -o /etc/yum.repos.d/convert2rhel.repo https://ftp.redhat.com/redhat/convert2rhel/7/convert2rhel.repo

install -o root -g root -m 0600 \
  <(echo -e "[subscription_manager]\npassword = ${RED_HAT_SUBSCRIPTION_MGR_PASS}\n") \
  /etc/convert2rhel.ini

yum -y install convert2rhel
convert2rhel -y -r --username "${RED_HAT_SUBSCRIPTION_MGR_USER}"
