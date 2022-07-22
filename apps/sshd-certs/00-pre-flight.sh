#!/bin/bash

# Normally, you'd use DNS, but for this demo...

# Make a backup copy.
cp -a /etc/hosts{,".$(date +%Y%m%d%H%M%S)"}

# Remove any entries, if this is re-run.
sed -i '/^192\.168\.56\./d' /etc/hosts

# Add the two test hosts.
cat << 'EOF' >> /etc/hosts
192.168.56.20 centos8a centos8a.example.com
192.168.56.21 centos8b centos8b.example.com
EOF

# Add two users, so we can test the ssh certs against their accounts.
useradd jsmith
useradd jdoe

echo -e "\nDONE!\n"
