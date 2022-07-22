#!/bin/bash

# NOTES:
#
#   * You should absolutely enforce passphrases, but I'm leaving them empty to
#     keep things simple.
#   * The keys do not need to be RSA; it could be another key type.  Consult
#     with your security staff for their requirements and/or recommendations.
#   * The key types do not have to match.  An ed25519 key can sign an RSA key,
#     and vice versa.
#   * SSH CA keys can be loaded into an `ssh-agent` to make an admin's live
#     easier when you have to do this manually, but typically, you'd automate
#     this entire process.
#   * When signing user public keys, the username (principal) is particularly
#     important.  It **MUST** match the username on the server they're
#     authenticating as.  Additionally, you can add multiple principals, 
#     (delimited with commas) to authorize users, example:  jdoe,oracle,root.
#   * Be cautious using '@example.com' usernames.  If you do, it should match
#     your actual DNS and Kerberos realm to avoid trouble with domain joined
#     hosts.
#   * Users should create their own private keys, and it should never leave
#     their possession.  They should only send their public key to be signed.



# Cleaning up after myself when re-running this script.
rm -f id_ed25519_jdoe* id_rsa_jsmith* ssh-host-ca.key* ssh-user-ca.key*



now=$(date +%F)

echo -e "\n----- Generating SSH CA for signing HOST public keys ------------\n"
ssh-keygen -t rsa -b 4096 -f ssh-host-ca.key -N '' -C "example.com SSH host CA ${now}" -V "+365d"

echo -e "\n----- Generating SSH CA for signing USER public keys ------------\n"
ssh-keygen -t rsa -b 4096 -f ssh-user-ca.key -N '' -C "example.com SSH user CA ${now}" -V "+365d"



fullname='John Smith'
username='jsmith'
email='jsmith@example.com'
key_type='rsa'

key_file="id_${key_type}_${username}"
key_id="${username} \"${fullname}\" <${email}> ${now}"
valid_from=$(date +%Y%m%d%H%M%S) # right now, e.g., "20220121204616"
valid_to=$(date +%Y%m%d%H%M%S -d 'next Thursday') # e.g., "20220127000000"

echo -e "\n----- Generating and signing keys for ${fullname} ------------\n"
ssh-keygen -t "${key_type}" -f "${key_file}" -N '' -C "${key_id}"
ssh-keygen -s ssh-user-ca.key -I "${key_id}" -n "${username}" -V "${valid_from}:${valid_to}" "${key_file}"



fullname='Jane Doe'
username='jdoe'
email='jdoe@example.com'
key_type='ed25519'

key_file="id_${key_type}_${username}"
key_id="${username} \"${fullname}\" <${email}> ${now}"
valid_from='-1m' # one minute ago
valid_to='+4w' # 4 weeks from now

echo -e "\n----- Generating and signing keys for ${fullname} ------------\n"
ssh-keygen -t "${key_type}" -f "${key_file}" -N '' -C "${key_id}"
# NOTE:  Sneakily adding ',root' to the principals.  Will allow root access to every host!
ssh-keygen -s ssh-user-ca.key -I "${key_id}" -n "${username},root" -V "${valid_from}:${valid_to}" "${key_file}"

echo -e "\nDONE!\n"
