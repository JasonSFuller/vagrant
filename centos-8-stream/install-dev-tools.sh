#!/bin/bash

# 2021-11-22 - Install the dev tools I prefer.  FYI, they are pretty safe for 
#   prod, but you may want to strip some of them for a MVP.

##### default packages #########################################################
# - '@base'                 # every system should have this group installed; too many important packages to name
# - '@core'                 # every system should have this group installed; too many important packages to name
# - ca-certificates         # required for cert ca-bundles and LOTS of other things
# - openssl                 # required for SSL support, plus tools
# - vim-enhanced            # regardless of _preference_, every competent admin knows how to use `vi`
# - wget                    # used by scripts; better for downloading binaries
# - rsync                   # used by scripts; efficiently copy whole directories
# - tmux                    # for admins; used for long running jobs
# - dstat                   # for admins; troubleshooting
# - git                     # used by scripts; interact with git repos
# - bind-utils              # used by scripts; mostly for `dig`
# - nfs-utils               # nfs support; tools also used by scripts
# - yum-utils               # used by scripts; mostly for `repoquery` and `yumdownloader`
# - rpm-build               # not strictly required, but `rpmbuild` is useful
# - rpmdevtools             # used by scripts; mostly for `rpmdev-vercmp`, `rpmdev-sort`, and `rpmdev-setuptree`
# - redhat-lsb              # used by scripts; mostly for the tools its _dependencies_ install (e.g. `lsb_release` from redhat-lsb-core)
# - bash-completion         # not strictly required, but VERY useful
# - bash-completion-extras  # not strictly required, but VERY useful (from EPEL!)
# - policycoreutils-python-utils  # used by scripts; for admins; lots of selinux tools
# - setroubleshoot-server   # used by scripts; for admins; decipher selinux messages
# - uuid                    # used by scripts; generate/decode uuids
# - nmap                    # used by scripts; for admins; network scanning
# - nmap-ncat               # used by scripts; for admins; mostly for `nc` (netcat)
# - telnet                  # for admins; troubleshooting; client only; for raw TCP connections
# - augeas                  # used by scripts; programmatically edit configs as if they're a tree
# - sg3_utils               # used by scripts; for admins; mostly for `rescan-scsi-bus.sh` when hot adding disks

##### domain join required packages ############################################
# - realmd                  # performs domain join heavy lifting
# - sssd                    # caches ldap and provides various **important** services
# - autofs                  # for automounting remote dirs, e.g. /home/$USER
# - krb5-workstation        # for kerberos support
# - oddjob                  # as the name implies, runs odd jobs; d-bus service
# - oddjob-mkhomedir        # creates a home dir for a user if it doesn't exist when they log in
# - adcli                   # used by scripts; additional tools for interacting with AD (required for constrained delegation/spn stuff)
# - nfs-utils               # u wnt sum f... NFS?!?  becky, lemme mount.
# - cifs-utils              # for mounting CIFS shares, becky.
# - samba-common            # pre-req (plus a little extra) for samba-common-tools
# - samba-common-tools      # mostly for the occasional use of `net`
# - sssd-client             # sssd libs for pam
# - sssd-libwbclient        # libs for smb/cifs support
# - sssd-tools              # used by scripts; mostly for `sssctl` and audit, but also provides many sss_* tools
# - ldb-tools               # used by scripts; for reading sssd database files; mostly `ldbsearch`
# - openldap-clients        # used by scripts; mostly for `ldapsearch`

if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: must run as root" >&2
  echo "HINT:  sudo $0"
  exit 1
fi

# install EPEL
dnf install -y epel-release

# update the OS
dnf update -y

# install default packages
dnf install -y \
  @base @core ca-certificates openssl vim-enhanced wget rsync screen dstat git \
  bind-utils nfs-utils yum-utils rpm-build rpmdevtools redhat-lsb \
  bash-completion policycoreutils-python-utils setroubleshoot-server uuid \
  nmap nmap-ncat telnet augeas sg3_utils

# install domain join required packages
dnf install -y \
  realmd sssd autofs krb5-workstation oddjob oddjob-mkhomedir adcli nfs-utils \
  cifs-utils samba-common samba-common-tools sssd-client sssd-libwbclient \
  sssd-tools ldb-tools openldap-clients




cat <<- 'EOF'

################################################################################
#                                                                              #
#   IMPORTANT:  A reboot is required if certain packages were updated,         #
#   particularly the kernel, glibc, etc.                                       #
#                                                                              #
################################################################################

EOF