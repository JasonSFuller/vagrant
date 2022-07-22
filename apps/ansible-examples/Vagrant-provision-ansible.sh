#!/bin/bash

# This is the path to the Tower env vars from the 'ansible' VM's perspective.
if [[ ! -r /vagrant/.tower.env ]]; then
  # You _should_ never see this, but just in case...
  cat <<- EOF >&2
	#####################################################################

	    WARNING:  Tower env vars missing (/vagrant/.tower.env)

	    Once you've logged into the 'ansible' VM, create the env file
	    (see Vagrant-provision-tower.sh for details on how to do this)
	    and then run:
	        sudo /vagrant/Vagrant-provision-ansible.sh

	#####################################################################
	EOF
  exit
fi

# Fix the default timezone and locale.  Not really important, just a nit-pick.
sudo timedatectl set-local-rtc 0
sudo timedatectl set-timezone US/Eastern
sudo localectl set-locale LANG=en_US.utf8
sudo localectl set-keymap us
sudo localectl set-x11-keymap us

# Since this host is a stock CentOS 8 box, make sure `ansible` is installed,
# along with a few other tools you'll need, particularly `curl`, `jq` and `git`.
sudo yum install -q -y epel-release
sudo yum erase -q -y ansible-core
sudo yum install -q -y ansible-2.9.27-1.el8.noarch python3-netaddr
sudo yum install -q -y curl jq git vim wget

# Install the `awx` cli tool (system-wide), and import the env vars we created
# on the 'tower' VM, so we can add the demo project and job template.
sudo pip3 install awxkit==17.1.0
# shellcheck source=/dev/null
source /vagrant/.tower.env
export PATH="/usr/local/bin:$PATH"



### Setup done, now do interesting things ######################################

# Create a new project in Tower and get it's ID.  The `awx` output will be JSON.
project_json=$(awx projects create --name "F5 demo project" --local_path "f5")
project_id=$(jq '.id' <<< "$project_json")
echo "project_id=$project_id"

# Get Tower's built-in "Demo Inventory" ID.  We're reusing it simply for the
# convenience.
inventory_id=$(awx inventory list --name "Demo Inventory" | jq '.results[0].id')
echo "inventory_id=$inventory_id"

# Create the f5-lookup.yml job template.  Again, the output will be JSON.
job_template_json=$(
  awx job_template create \
  --name "DEMO Job Template - F5 lookup" \
	--job_type run \
	--inventory "$inventory_id" \
	--project "$project_id" \
	--playbook "f5-lookup.yml" \
  --ask_variables_on_launch 'true' \
  --extra_vars '{ "app_ip": "10.10.10.10" }'
)
job_template_id=$(jq '.id' <<< "$job_template_json")
echo "Created job_template_id=$job_template_id"

# Create the f5-report.yml job template.  Again, the output will be JSON.
job_template_json=$(
  awx job_template create \
  --name "DEMO Job Template - F5 report" \
	--job_type run \
	--inventory "$inventory_id" \
	--project "$project_id" \
	--playbook "f5-report.yml" \
  --ask_variables_on_launch 'true' \
  --extra_vars '{ "nodes": [ "f5-mgmt-10-10-10a", "f5-mgmt-10-10-10b" ], "app_ip": "10.10.10.10" }'
)
job_template_id=$(jq '.id' <<< "$job_template_json")
echo "Created job_template_id=$job_template_id"

# Print some more useful info:
echo -e "\nID\tProject Name\n--\t------------"
awx project list | jq -r '.results[] | [.id, .name] | @tsv'
echo -e "\nID\tInventory Name\n--\t--------------"
awx inventory list | jq -r '.results[] | [.id, .name] | @tsv'
echo -e "\nID\tJob Template Name\n--\t-----------------"
awx job_template list | jq -r '.results[] | [.id, .name] | @tsv'
echo

cat << EOF
####[   Tower info   ]######################################

$(cat /vagrant/.tower.env)

####[   Next steps   ]######################################

1.  Tower needs a subscription to launch jobs.  Log in to 
    the Tower web GUI and upload your Red Hat Developer 
    Subscription manifest to complete the installation.
    Details are in the README.md.

2.  SSH to the 'ansible' VM, and...
        vagrant ssh ansible

3.  Run the examples:
        /vagrant/curl/list-job-templates.sh
        /vagrant/curl/run-job-template.sh

        cd /vagrant/f5/
        ansible-playbook f5-lookup.yml -e 'app_ip=1.1.1.1'
        ansible-playbook f5-report.yml -e 'app_ip=1.1.1.1' \\
          -e 'nodes=f5-mgmt-1a'

        /vagrant/f5/remote-client.sh 1.1.1.1
        /vagrant/f5/remote-client.sh 10.134.96.44

EOF