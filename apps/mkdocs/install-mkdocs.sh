#!/bin/bash

# Basic error handler and some pre-flight checks
function error { echo "ERROR: $*" >&2; exit 1; }
if [[ "$(id -nu)" != "vagrant" ]]; then error "re-run as the vagrant user"; fi
cd /vagrant || error "vagrant dir missing"

# We need Python, pip, and venv installed.
sudo apt-get -y install python3 python3-pip python3-venv

# Create virtual environment, just in case we need to separate things later.
python3 -m venv .venv --prompt mkdocs
# shellcheck source=/dev/null
source ./.venv/bin/activate

# Have the package installer for Python (pip) update itself.
pip install --upgrade pip

# Finally, install Material for MkDocs.
# * https://squidfunk.github.io/mkdocs-material/
pip install mkdocs-material

# Reminder for what to do next.
cat << 'EOF'

################################################################################

# Next steps

# ...after logging in, e.g. 'vagrant ssh'
cd /vagrant
source ./.venv/bin/activate
mkdocs serve -a 0.0.0.0:8000 --watch-theme

# Open site in browser:  http://<host_ip>:8000/
# NOTE:  Use the host's IP (the one running the VM), not the guest's IP.

################################################################################

EOF