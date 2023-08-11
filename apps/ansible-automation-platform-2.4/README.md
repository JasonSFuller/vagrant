# Ansible Automation Platform 2.4

* [Red Hat Ansible Automation Platform 2.4 Installation Guide](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4/html/red_hat_ansible_automation_platform_installation_guide/index)



## Prerequisites

* A working [VirtualBox] and [Vagrant] installation, preferably on a Linux host
* A [Red Hat developer account] for registering the RHEL guests
* A [subscription allocation] (manifest) for AAP licensing
* A [registry service account] for downloading the required containers
* Enough resources on the host to run 3 fairly large guests:
  | Hostname   | Description           | Required resources           |
  | ---------- | --------------------- | ---------------------------- |
  | ctl.local  | Automation controller | 4 CPU, 16 Gb RAM, 20 Gb disk |
  | hub.local  | Automation hub        | 4 CPU, 16 Gb RAM, 20 Gb disk |
  | mgmt.local | Management node       | 2 CPU, 4 Gb RAM, 20 Gb disk  |

[VirtualBox]: https://www.virtualbox.org/
[Vagrant]: https://www.vagrantup.com/
[Red Hat developer account]: https://developers.redhat.com/
[subscription allocation]: https://access.redhat.com/management/subscription_allocations
[registry service account]: https://access.redhat.com/terms-based-registry/



## Installation

Download the **bundle** and save it to the same directory as the [`Vagrantfile`](Vagrantfile):

* <https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.4/x86_64/product-software>

Your directory should look like this:

```text
$ ls -lad ansible-automation-platform-setup-bundle-* Vagrantfile
-rwxrwxr-x 1 jfuller jfuller 2054136318 Aug 10 13:59 ansible-automation-platform-setup-bundle-2.4-1.2-x86_64.tar.gz
-rw-rw-r-- 1 jfuller jfuller        129 Aug 10 14:01 ansible-automation-platform-setup-bundle-2.4-1.2-x86_64.tar.gz.sha256
-rw-rw-r-- 1 jfuller jfuller       2575 Aug 10 13:45 Vagrantfile
```

Create a `.env` file.  

> :pencil2: **NOTE:** This is used by the vagrant-registration plugin to
> register the RHEL boxes (for licensing, repository access, etc).

```bash
cp .env.sample.txt .env
vim .env
```

Create a `secrets.yaml` file.

> :pencil2: **NOTE:** This is used by `setup.sh` (the AAP installer) and
> separates your secret values from non-secret config--which is safe to store in
> source control.

```bash
cp secrets.yaml.sample.txt secrets.yaml
vim secrets.yaml
```

Bring up the Vagrant machines:

```bash
vagrant up
```

This will take ~20 minutes.  Once complete, login to the web UI:

* <https://localhost:8443>, or
* <https://lab3.example.com:8443>, etc.

And finally, for licensing/registration, use a manifest from your [subscription allocation]
to add 3 or 4 entitlements from your developer subscription, so AAP can manage a
few hosts.

> :blue_book: **TIP** -- If you've never created a manifest, it's similar to
> [the process for Satellite](https://www.redhat.com/en/blog/how-create-and-use-red-hat-satellite-manifest),
> except you're using a few entitlements from your developer subscription
> instead of "smart management" (or whatever they're calling it now-a-days).



## Troubleshooting

From the management node, validate Ansible can log in to all inventory hosts.

```bash
# vagrant ssh mgmt # if you haven't already
cd /home/vagrant/ansible-automation-platform-setup-bundle-*/
sudo ansible -m ping -i ./inventory all
```

Re-run the installation script manually.

```bash
cd /home/vagrant/ansible-automation-platform-setup-bundle-*/
sudo ./setup.sh -e '@/vagrant/secrets.yaml' -i ./inventory
```
