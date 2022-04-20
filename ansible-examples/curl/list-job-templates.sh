#!/bin/bash

# IMPORTANT:  For all the `curl` commands below, remove the `-k` (or
#   `--insecure`) flag when in production.  For this demo, we're disabling
#   certificate checks since they're all self-signed.

# Cowardly refuse to run if we can't find our Tower creds.
if [[ ! -r /vagrant/.tower.env ]]; then
  echo "ERROR:  Tower env vars missing (/vagrant/.tower.env)" >&2
  exit 1
fi
# shellcheck source=/dev/null
source /vagrant/.tower.env

# Query Ansible Tower via the REST API and store the output in $json.
url="${TOWER_HOST}/api/v2/job_templates/?page_size=200"
json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${url}")

# Use `jq` to filter (and format) the output.
echo -e "ID\tJob Template Name\n--\t-----------------"
jq -r "(.results | .[] | [.id, .name]) | @tsv" <<< "${json}"

# By default (set in Tower), the maximum number of results that can be returned
# at one time is 200.  You'll need to recursively query 'next' to get all the
# results. I'm not bothering for this simple demo (just displaying a simple
# warning), but for more info, see:
#   https://docs.ansible.com/ansible-tower/3.8.5/html/towerapi/pagination.html
next=$(jq -r '.next' <<< "${json}")
if [[ ! "${next}" =~ ^null.?$ ]]; then
  echo "WARNING:  The page_size was exceeded.  Not all results are shown." >&2
  echo "  next=${next}" >&2
fi
