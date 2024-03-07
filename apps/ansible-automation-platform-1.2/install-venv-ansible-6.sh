#!/bin/bash

# Source:  https://docs.ansible.com/ansible-tower/latest/html/upgrade-migration-guide/virtualenv.html

# IMPORTANT:
# - Ansible 6.x is no longer maintained.
# - See install-venv-ansible.README.md for details.

# base dir for the venv; eventually creates "${venv_dir}/ansible-6"
venv_dir="/opt/my-envs"

################################################################################

function init {
  if [[ "$(id -u)" != "0" ]]; then error "must be run as root"; fi
  if [[ ! -r /etc/os-release ]]; then
    error "Could not read /etc/os-release"
  fi
  # shellcheck source=/dev/null
  source /etc/os-release
  if [[ "$ID" != 'rhel' || ! "$VERSION_ID" =~ ^7\. ]]; then
    error "This script is intended for a RHEL 7 distro."
  fi
  if tty -s; then       # only use color if stdin is a terminal
    blu=$(tput setaf 4) # color foreground blue
    red=$(tput setaf 1) # color foreground red
    yel=$(tput setaf 3) # color foreground yellow
    rst=$(tput sgr0)    # color reset
  fi
}

function info  { echo "${blu}INFO:${rst}  $*"; }
function warn  { echo "${yel}WARN:${rst}  $*" >&2; }
function error { echo "${red}ERROR:${rst} $*" >&2; exit 1; }

function add_custom_venv_path_to_aap {
  # TODO: remove hardcoded AAP user, pass, and host
  custom_venv=$(
    curl -fsSLk 'https://admin:password@localhost/api/v2/settings/system/' \
      | grep -oP '(?<="CUSTOM_VENV_PATHS":\[).*(?=(\],"|\]}))'
  )
  info "Current custom venv path(s): ${custom_venv}"

  # TODO: This grep is not perfect (the SERVER's list of paths may not be
  # canonical or absolute), but it's good enough for most cases by checking
  # for quotes as boundaries.
  if grep -qF "\"${venv_dir}\"" <<< "${custom_venv}"; then
    info "Skipping addition of \"${venv_dir}\" (already exists)"
  else
    info "Adding '${venv_dir}' to Tower's custom venv paths"
    # if there are existing paths, append the new one to the end
    if [[ -z "${custom_venv}" ]]; then
      printf -v custom_venv '"%s"' "${venv_dir}"
    else
      printf -v custom_venv '%s,"%s"' "${custom_venv}" "${venv_dir}"
    fi
    printf -v custom_venv '{"CUSTOM_VENV_PATHS": [%s]}' "${custom_venv}"
  # TODO: remove hardcoded AAP user, pass, and host
    curl -fsSLk \
      -X PATCH 'https://admin:password@localhost/api/v2/settings/system/' \
      -H 'Content-Type:application/json' \
      -d "$custom_venv" >/dev/null 2>&1 \
      || error "could not update CUSTOM_VENV_PATHS"
  fi
}

################################################################################

init

# Ansible 6.x dropped support for Python 3.6 and requires Python 3.8-3.10
# RHEL 7 only includes up to Python 3.8, and even then, only from the SCL
# Note: the Python package psutils requires gcc rh-python38-python-devel
yum install -y gcc rh-python38 rh-python38-python-devel --enablerepo=rhel-server-rhscl-7-rpms

# create base venv dir
install -m 0755 -o awx -g awx -d "${venv_dir}"

# gets both canonical and absolute path, AND removes trailing slash if exists
venv_dir=$(realpath "${venv_dir}")

# create venv dir
install -m 0755 -o root -g root -d "${venv_dir}/ansible-6"

# IMPORTANT - mask the permissions to disallow writes for anyone but root
umask 0022

# enable Python 3.8
if [[ ! -r /opt/rh/rh-python38/enable ]]; then
  error "could not enable rh-python38 (file missing or unreadable)"
fi
# shellcheck source=/dev/null
source /opt/rh/rh-python38/enable
if ! python3 --version | grep -qF 'Python 3.8'; then
  error 'python 3.8 not detected'
fi

# create the venv if it doesn't exist
if [[ ! -f "${venv_dir}/ansible-6/bin/activate" ]]; then
  python3 -m venv "${venv_dir}/ansible-6"
fi

# activate the venv
# shellcheck source=/dev/null
source "${venv_dir}/ansible-6/bin/activate" \
  || error 'failed to activate venv'

# install/upgrade pip and THEN psutil, ansible, etc
pip install --upgrade pip
pip install --upgrade psutil 'ansible<7'

add_custom_venv_path_to_aap
