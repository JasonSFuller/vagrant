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

app_ip="$1" # first arg passed in from command line
if [[ -z "$app_ip" ]]; then
  echo "USAGE: $0 <ip_address>"
  exit 1
fi

# IMPORTANT:  Always validate your input!  We're passing it to the shell below,
#   and sloppy validation could allow a malicious user to do terrible things.
#   Also, we're only covering the bare minimum (mostly to avoid shell escaping);
#   in prod, you'd tighten up this regex to remove edge cases, e.g. 999.9.9.9.
if [[ ! "$app_ip" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
  echo "ERROR: invalid ip" >&2
  exit 1
fi

extra_vars_json=$(
  jq -n \
    --arg a "$app_ip" \
    '{ extra_vars: { app_ip: $a } }'
)
echo "Extra vars JSON needed in Phase 1:"
echo "$extra_vars_json"


################################################################################

echo "-------------------------------------------------------------------------"
echo "Phase 1 - Convert the app VIP to F5 mgmt interface"
echo "-------------------------------------------------------------------------"

# Normally, you'd staticly set the job_template_id, since it doesn't change once
# it's created in Tower, but since this is a demo and we're experimenting, let's
# grab the ID dynamically based on it's name.
# IMPORTANT:  Results capped at 200, see notes in curl/list-job-templates.sh
#   for more detail.
job_templates_json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${TOWER_HOST}/api/v2/job_templates/?page_size=200&search=f5")
job_template_id=$(jq -r '.results[] | select(.name | contains("DEMO Job Template - F5 lookup")) | .id' <<< "${job_templates_json}")
if [[ ! "${job_template_id}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: could not find job template ID for the 'DEMO Job Template - F5 lookup'" >&2
  exit 1
fi

# Now that we have a job_template_id, launch a new job.
echo "Launching job template (id: ${job_template_id})..."
job_launch_json=$(
  curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" \
    -X POST -H "Content-type: application/json" -d "$extra_vars_json" \
    "${TOWER_HOST}/api/v2/job_templates/${job_template_id}/launch/"
)
ret=$?
if [[ "${ret}" != "0" ]]; then echo "ERROR: job launch curl failed ($ret)" >&2; exit 1; fi
if [[ "${job_launch_json}" =~ "License is missing" ]]; then echo "ERROR: Tower license is missing" >&2; exit 1; fi

# Gather some details about the job.
job_id=$(jq -r '.id' <<< "$job_launch_json")
job_template_name=$(jq -r '.name' <<< "$job_launch_json")
job_path=$(jq -r '.url' <<< "$job_launch_json")
job_url="${TOWER_HOST}${job_path}"
echo "Job (id: ${job_id}) created from \"${job_template_name}\" job template (id: ${job_template_id})"

# Now wait for the job to complete.
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

# This `curl` command (or the URI, rather) is a little different than the
# `curl/run-job-template.sh` example, where we were showing the output of the
# _Ansible playbook_.  For most jobs, the default level of detail is fine.
# However in this case, we need to get at the stdout from a command we ran
# inside the playbook (`cat`), which doesn't show by default.
#
# On the command line, we can accomplish this by changing stdout_callback (in
# ansible.cfg) to "minimal."  However, Tower records everything about a job,
# though it may not be obvious at first.  Find a playbook run of the "DEMO Job
# Template - F5 report" under the "Jobs" view in Tower.  The standard out pane
# (righthand side) shows what you'd typically see when running `ansible-playbook
# f5-report.yml` from the command line, but if you click on the "changed" line
# below "TASK [Read report]" (line 28), a modal window will pop up showing the
# full output of that task.  Also, notice the "JSON," "STANDARD OUT," and
# "STANDARD ERROR" buttons.  They show the information we're querying in the
# command below, and these details can be found under "job_events" in the
# Ansible Tower REST API.

# Get info from job events.
job_events_json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${TOWER_HOST}/api/v2/jobs/${job_id}/job_events/")
job_event_out=$(jq -r '.results[].event_data.res | select(.cmd) | .stdout' <<< "${job_events_json}")

# Show the output.
if [[ -z "$job_event_out" ]]; then echo 'ERROR: job_event_out empty'; exit 1; fi
echo "F5 management interfaces:"
echo "$job_event_out"

extra_vars_json=$(
  jq -n \
    --arg a "$app_ip" \
    --arg n "$job_event_out" \
    '{ extra_vars: { app_ip: $a, nodes: $n | split("\n") } }'
)
echo "Extra vars JSON needed in Phase 2:"
echo "$extra_vars_json"



################################################################################

# This repeats many of the exact same steps in Phase 1, but with a new job
# template (and id) and by passing different parameters (info from Phase 1) into
# extra_vars when launching the job.  Normally, you'd turn many of these steps
# into functions to avoid copy pasta and help abstract some of the nitty-gritty
# details, but I'm keeping it simple for learning purposes.

echo "-------------------------------------------------------------------------"
echo "Phase 2 - Get the F5 report"
echo "-------------------------------------------------------------------------"

# Lookup the job template's ID based on a name.
job_templates_json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${TOWER_HOST}/api/v2/job_templates/?page_size=200&search=f5")
job_template_id=$(jq -r '.results[] | select(.name | contains("DEMO Job Template - F5 report")) | .id' <<< "${job_templates_json}")
if [[ ! "${job_template_id}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: could not find job template ID for the 'DEMO Job Template - F5 report'" >&2
  exit 1
fi

# Now that we have a job_template_id and the extra_vars_json from Phase 1,
# launch a new job.
echo "Launching job template (id: ${job_template_id})..."
job_launch_json=$(
  curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" \
    -X POST -H "Content-type: application/json" -d "$extra_vars_json" \
    "${TOWER_HOST}/api/v2/job_templates/${job_template_id}/launch/"
)
ret=$?
if [[ "${ret}" != "0" ]]; then echo "ERROR: job launch curl failed ($ret)" >&2; exit 1; fi
if [[ "${job_launch_json}" =~ "License is missing" ]]; then echo "ERROR: Tower license is missing" >&2; exit 1; fi

# Gather some details about the job.
job_id=$(jq -r '.id' <<< "$job_launch_json")
job_template_name=$(jq -r '.name' <<< "$job_launch_json")
job_path=$(jq -r '.url' <<< "$job_launch_json")
job_url="${TOWER_HOST}${job_path}"
echo "Job (id: ${job_id}) created from \"${job_template_name}\" job template (id: ${job_template_id})"

# Now wait for the job to complete.
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

# Get info from job events.
job_events_json=$(curl -sS -k -u "${TOWER_USERNAME}:${TOWER_PASSWORD}" "${TOWER_HOST}/api/v2/jobs/${job_id}/job_events/")
f5_report=$(jq -r '.results[].event_data.res | select(.cmd) | .stdout' <<< "${job_events_json}")

# Show the output.
echo "$f5_report"
