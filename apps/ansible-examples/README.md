# Ansible examples

Need to quickly setup a development environment to test Ansible playbooks and
make calls to Ansible Tower?

Included are a set of examples to do just that.  This is useful for demo and
development purposes.  Likewise, a few examples are included: a simple "hello
world" Ansible playbook, and scripts to make REST API calls to Tower.



&nbsp;

## One-time setup - install VirtualBox and Vagrant

> :orange_book: **IMPORTANT** -- To get started, install
> [VirtualBox](https://www.virtualbox.org/manual/UserManual.html#installation)
> and
> [Vagrant](https://www.vagrantup.com/docs/installation) first.  

Then, open your favorite terminal, `cd` to the same directory as the
`Vagrantfile`, and create/provision the guest machines:

```bash
cd ~/src/ansible-examples/ # or wherever
vagrant up
```

This process will take several minutes.  Go get a cup of coffee.

### Add a license to Ansible Tower

Ansible Tower requires a license to use.  The easiest solution is to [create a
 free Red Hat Developer account](https://developers.redhat.com/register), which
 comes with a no-cost subscription to nearly all their products.  There are
 [limits to this subscription](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux),
 but most development work is generally in-scope, hence the name.

Once you have an account and subscription, [create a new
**subscription allocation**](https://access.redhat.com/management/subscription_allocations/new):

* Name = _USERNAME_-rh-dev-sub
* Type = Satellite 6.10

Open the new **subscription allocation** (if it isn't open already), and:

* Click **Subscriptions** (tab) and **Add new subscriptions** (button).
* Find the **Red Hat Developer Subscription for Individuals** row, and
* Type `4` in the **Entitlements** box.
* Click **Submit** (button), wait for it to complete, and then
* Click **Export Manifest** (button) to download the manifest `.zip` file.

Once you have the manifest, open the Tower web interface, log in, and follow the
licensing instructions (browse for the manifest, accept the EULA, _etc_).

> :blue_book: **NOTE** -- The admin credentials for the Tower web interface can
> be found by simply `ssh`ing to the guest VM  with `vagrant ssh tower`.  The
> MOTD will automatically display the credentials, or you can manually examine
> the `/etc/profile.d/ansible-tower.sh` file.



&nbsp;

## Jinja example

Login to the "ansible" guest VM and run the Ansible playbook:

```bash
# SSH to the VM labeled "ansible."
vagrant ssh ansible

# Run the demo playbook.
cd /vagrant/jinja
ansible-playbook playbook.yml
cat output.txt

# Disconnect from the "ansible" VM.
exit
```

&nbsp;

## Ansible Tower REST API examples

Login to the "ansible" guest VM and run the shell scripts:

```bash
# SSH to the VM labeled "ansible."
vagrant ssh ansible

# The Ansible Tower credentials should have been added to an
# environment file.  Examine it to see if any of the values 
# need to be adjusted.
cat /vagrant/.tower.env

# List all the job templates accessible to TOWER_USERNAME.
/vagrant/curl/list-job-templates.sh

# Create a job (from a job template), monitor it's status, and
# display the job's Ansible output when done.
/vagrant/curl/run-job-template.sh

# To see more detail when running these scripts, use Bash's 
# "xtrace" mode.  It shows every command executed by the shell,
# with the shell variable values inserted:
bash -x /vagrant/curl/run-job-template.sh |& grep curl

# Disconnect from the "ansible" VM.
exit
```

### Further reading

* <https://docs.ansible.com/ansible-tower/3.8.5/html/towerapi/>
* <https://docs.ansible.com/ansible-tower/3.8.5/html/towerapi/pagination.html>
* <https://docs.ansible.com/ansible-tower/3.8.5/html/userguide/jobs.html#id3>


&nbsp;

## Ansible network module examples

See [f5/README.md](f5/README.md).

## Ansible Tower using roles in playbook

See [my-project/README.md](my-project/README.md).
