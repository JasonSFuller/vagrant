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

# ------------------------------------------------------------------------------
# Launch $job_template_id by POSTing to the Ansible Tower REST API
# ------------------------------------------------------------------------------

job_template_id=7 # default job template built into the ansible/tower:3.8.5 image
url="${TOWER_HOST}/api/v2/job_templates/${job_template_id}/launch/"

echo "Launching job template (id: ${job_template_id})..."
json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" -X POST "${url}")
ret=$?
if [[ "${ret}" != "0" ]]; then
  echo "ERROR: job launch curl failed ($ret)" >&2
  exit 1
fi
if [[ "${json}" =~ "License is missing" ]]; then
  echo "ERROR: Tower license is missing" >&2
  exit 1
fi

job_id=$(jq -r '.id' <<< "$json")
job_template_name=$(jq -r '.name' <<< "$json")
job_path=$(jq -r '.url' <<< "$json")
job_url="${TOWER_HOST}${job_path}"
echo "Job (id: ${job_id}) created from \"${job_template_name}\" job template (id: ${job_template_id})"

# ------------------------------------------------------------------------------
# Monitor the running job
# ------------------------------------------------------------------------------

# Possible job statuses ($job_status)
# * Pending - The playbook run has been created, but not queued or started yet.
#   Any job, not just playbook runs, will stay in pending until it’s actually
#   ready to be run by the system. Reasons for playbook runs not being ready
#   include dependencies that are currently running (all dependencies must be
#   completed before the next step can execute), or there is not enough capacity
#   to run in the locations it is configured to.
# * Waiting - The playbook run is in the queue waiting to be executed.
# * Running - The playbook run is currently in progress.
# * Successful - The last playbook run succeeded.
# * Failed - The last playbook run failed. 
# Source:  https://docs.ansible.com/ansible-tower/3.8.5/html/userguide/jobs.html

job_status='pending'
while [[ "${job_status}" =~ pending|waiting|running ]];
do
  sleep 1 # NOTE:  1 second might be too fast for production.
  job_json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${job_url}")
  ret=$?
  if [[ "${ret}" != "0" ]]; then
    echo "ERROR: job status curl failed (${ret})" >&2
    exit 1
  fi
  job_status=$(jq -r '.status | ascii_downcase' <<< "${job_json}")
  now=$(date '+%F %T %Z')
  printf "%s -- template(%s)=\"%s\" job=\"%s\" status=\"%s\"\n" \
    "${now}" "${job_template_id}" "${job_template_name}" "${job_id}" "${job_status}"
done

# ------------------------------------------------------------------------------
# Show the results (stdout)
# ------------------------------------------------------------------------------

curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${job_url}stdout/?format=txt"
