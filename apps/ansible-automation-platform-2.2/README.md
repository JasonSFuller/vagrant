# Ansible Automation Platform 2.2

* [Red Hat Ansible Automation Platform 2.2 Installation Guide](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.2/html/red_hat_ansible_automation_platform_installation_guide/index)



## Prerequisites

* A working [VirtualBox] and [Vagrant] installation, preferably on a Linux host
* A [Red Hat developer account] for registering the RHEL guests
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
[registry service account]: https://access.redhat.com/terms-based-registry/



## Installation

Download the **bundle** and save it to the same directory as the [`Vagrantfile`](Vagrantfile):

* <https://access.redhat.com/downloads/content/480/ver=2.2/rhel---9/2.2/x86_64/product-software>

Your directory should look like this:

```text
$ ls -lad ansible-automation-platform-setup-bundle-* Vagrantfile
-rw-r--r--. 1 vagrant vagrant 1472877795 Nov 10 14:06 ansible-automation-platform-setup-bundle-2.2.1-1.1.tar.gz
-rw-r--r--. 1 vagrant vagrant        124 Nov 10 14:09 ansible-automation-platform-setup-bundle-2.2.1-1.1.tar.gz.sha256
-rw-r--r--. 1 vagrant vagrant       2290 Nov 10 19:36 Vagrantfile
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

## Testing and troubleshooting

From the management node, validate Ansible can log in to all inventory hosts.

```bash
vagrant ssh mgmt
ansible -m ping -i /vagrant/inventory all
```
