#!/bin/bash

# NOTES:
#
#   * This script is not elegant.  Ideally, you'd use a better tool for this
#     (like Ansible), but I'm trying to keep the dependencies to a minimum.
#   * You can specify multiple entries in the TrustedUserCAKeys file (in this
#     case, /etc/ssh/trusted_user_ca_keys).  Think of it as the CA version of an
#     authorized_keys file, except instead of an individual's public keys, it
#     contains the public keys of all the CAs you trust.  This is useful when
#     your CA expires and you need to rotate keys beforehand.  You can add the
#     new key, wait a period of time, and then remove the old key for a seemless
#     transition.
#   * Local (non-server) OpenSSH clients will also want to trust sshd keys
#     signed by your SSH host CA, so they aren't prompted by fingerprint
#     mismatches when keys are rotated.  Simply add this line to the user's
#     ~/.ssh/known_hosts:
#                           vvvvvvvvvvvvvvv
#         @cert-authority * ssh-rsa AAAA... 
#                           ^^^^^^^^^^^^^^^
#     ...where "ssh-rsa AAAA..." is the contents of ssh-host-ca.key.pub.
#     IMPORTANT:  '*' should really be '*.example.com' for your domain.  This
#     doesn't effect you so much as an admin/organization, since you should
#     always trust every certificate you sign, but that doesn't mean your users
#     should.
#   * If a user previously logged into a server and it's old fingerprint is in
#     their ~/.ssh/known_hosts, it should be removed (`ssh-keygen -R server01`)
#     to avoid man-in-the-middle warnings.
#   * Authenticated users logins look like this in the logs:
#         Jan 22 05:59:44 centos8a sshd[24600]: Accepted publickey for jdoe from
#           192.168.56.21 port 40266 ssh2: ED25519-CERT SHA256:cJIsU2RG1RCLsigQ5
#           ouN8yWRn/vrWBDaybkb2oDevd4 ID jdoe "Jane Doe" <jdoe@example.com> 
#           2022-01-21 (serial 0) CA RSA SHA256:EorFMNtTF3KtHvfTwPXITCh9UQmxGn4+
#           simIwdBQ7Uw
#         Jan 22 05:59:44 centos8a sshd[24600]: pam_unix(sshd:session): session
#           opened for user jdoe by (uid=0)
#         Jan 22 06:00:16 centos8a sshd[24651]: Accepted publickey for jsmith 
#           from 192.168.56.21 port 40268 ssh2: RSA-CERT SHA256:5GXPpsT6p5Vt4aA3
#           uMEqdvHKTjaCPzVBsMXLH45WWnM ID jsmith "John Smith" 
#           <jsmith@example.com> 2022-01-21 (serial 0) CA RSA SHA256:EorFMNtTF3K
#           tHvfTwPXITCh9UQmxGn4+simIwdBQ7Uw
#         Jan 22 06:00:16 centos8a sshd[24651]: pam_unix(sshd:session): session
#           opened for user jsmith by (uid=0)

if [[ ! -r ssh-host-ca.key || ! -r ssh-user-ca.key.pub ]]; then
  echo "ERROR:  SSH CA files are missing." >&2
  echo "  Run 01-create-ssh-cert-examples.sh first." >&2
  exit 1
fi

if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR:  You must run this as root." >&2
  exit 1
fi

if [[ ! -w /etc/ssh/sshd_config ]]; then
  echo "ERROR:  /etc/ssh/sshd_config is missing or not writable." >&2
  exit 1
fi



# Make a temp file to hold our sshd_config settings.  We'll use it later.
tmp=$(mktemp)

# Loop over all the sshd host keys and sign them with our SSH host CA.
while IFS= read -r -d $'\0' file; do

  key='ssh-host-ca.key'
  key_id=$(cut -d ' ' -f3- < ssh-host-ca.key.pub) # remove first two fields ("ssh-rsa AAAA...")
    
  ip=$(ip -4 -o a | sed -r 's/.*inet ([0-9\.]*).*/\1/' | grep -F '192.168.56.')
  host_short=$(hostname -s)
  host_full=$(hostname -f)
  principals="${ip},${host_short},${host_full}"

  valid_to="+35d" # 35 day from now
  valid_to_desc=$(date -d '35 days')

  printf "\n----- Found sshd key file: %s -----\n" "${file}"
  printf "CA key:          %s\n" "${key}"
  printf "Key identifier:  %s\n" "${key_id}"
  printf "Cert valid to:   %s (%s)\n" "${valid_to}" "${valid_to_desc}"
  printf "Hostname:        %s\n\n" "${principals}"

  ssh-keygen -s "${key}" -I "${key_id}" -V "${valid_to}" -h -n "${principals}" "${file}"

  # Write a few sshd_config settings.  Generally, these should be at the top of
  # your sshd_config, so I'm writing these to separate file to be used later.
  # NOTE:  Order matters!  HostKey must be before HostCertificate.
  echo "HostKey         ${file}"          >> "${tmp}"
  echo "HostCertificate ${file}-cert.pub" >> "${tmp}"

done < <(find /etc/ssh/ -type f -name 'ssh_host_*_key' -print0)

echo



# Now, we need to modify the sshd_config to use the new certificates.

# Make a backup copy of the config before we do anything, just in case.
cp -a /etc/ssh/sshd_config{,".$(date +%Y%m%d%H%M%S)"}

# Configure sshd to allow users with certificates signed by your SSH user CA.
install -o root -g root -m 0644 ssh-user-ca.key.pub /etc/ssh/trusted_user_ca_keys
echo 'TrustedUserCAKeys /etc/ssh/trusted_user_ca_keys' >> "${tmp}"

# Copy the current config, minus the HostKey and HostCertificate settings. Also,
# I'm disabling ShellCheck's "useless use of cat" warning because... yeah, YEAH,
# I know, but this form makes the transformations more readable. 
#   shellcheck disable=SC2002
cat /etc/ssh/sshd_config \
| sed '/^HostKey /d' \
| sed '/^HostCertificate /d' \
| sed '/^TrustedUserCAKeys /d' \
>> "${tmp}"



# Finally, we need to modify the system-wide ssh_config to also trust the new
# certificates.
echo "INFO:  Writing the SSH host CA's public key to /etc/ssh/ssh_known_hosts."
echo -n "@cert-authority * " >  /etc/ssh/ssh_known_hosts
cat ssh-host-ca.key.pub      >> /etc/ssh/ssh_known_hosts

echo -e "\nDONE!\n"



# Test the temp config, and if it passes, write it and reload sshd.
if sshd -t -T -f "${tmp}" > /dev/null; then
  echo "INFO:  Writing a new sshd_config and reloading sshd."
  cat "${tmp}" > /etc/ssh/sshd_config
  systemctl reload sshd \
  && rm -f "${tmp}"
else
  echo "ERROR:  sshd config validation failed" >&2
  exit 1
fi
