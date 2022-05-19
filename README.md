# Vagrant

> :orange_book: **IMPORTANT** -- These are my personal vagrant files for...
> random things.  Many are a WIP and may or may not be in a useful or even
> functional state.  Use at your own risk.

## Install Vagrant

[Vagrant](https://www.vagrantup.com/) is an easy way for developers to spin up
new hosts for testing.  It relies upon an underlying "provider" to actually
perform the virtualization and networking for a guest VM, but Vagrant helps by
providing a convenient and somewhat consistent interface for managing these
resources quickly.

Typically, [VirtualBox](https://www.virtualbox.org/) is the go-to provider,
since it's fairly cross-platform and offers a Windows, Mac, and Linux installer,
but the backend provider could be Hyper-V on Windows, KVM (libvirt) on Linux, or
even a cloud provider like AWS--though there aren't always images on
[app.vagrantup.com](https://app.vagrantup.com) for other providers, so use
VirtualBox if you can.

Follow the VirtualBox and Vagrant installation guides appropriate for your
environment:

* <https://www.virtualbox.org/manual/ch02.html>
* <https://www.vagrantup.com/docs/installation>



## Vagrant plugins

Vagrant offers
[plugins](https://github.com/hashicorp/vagrant/wiki/Available-Vagrant-Plugins)
to extend it's functionality.  These are the ones I use.

* **vagrant-reload** -- Normally, when a guest reboots during the provisioning
  process, it will cause the `vagrant up` or `vagrant reload` to fail, or it
  will ignore any steps afterwards.  This allows you to insert a reboot in the
  provisioning process to: (1) pause, (2) wait for the guest to reboot, and (3)
  continue.  It's especially useful for Windows guests.
* **vagrant-scp** -- Adds support for `vagrant scp <src> <dest>`, which IMHO
  should be included in Vagrant by default.  You _can_ do this with stock
  Vagrant, in the same way you can use plain `ssh` vs `vagrant ssh`, but it's a
  giant pain to calculate/resolve the guest name to ip/port due to all the port
  forwarding.
* **vagrant-sshfs** -- Normally, when adding a `synced_folder` in your
  `Vagrantfile`, it falls back to either a one-way copy of the files or, worse
  yet, advises you to use a CIFS share (SMBv1? yikes!) unless the guest has the
  appropriate tools installed.  Getting the tools installed on the guest is
  particularly troublesome for older Linux distros.  If using VirtualBox, it
  requires VBoxGuestAdditions to be installed (or a compatible equivalent),
  since it uses `vboxsf` under the hood when available.  Regardless, SSH is more
  ubiquitous and is almost always present anyway, so `sshfs` provides a
  convenient solution and works with the OS of your choice.
* **vagrant-vbguest** -- If you're using VirtualBox as the provider (the most
  common), this will auto-install the VBoxGuestAdditions during the provisioning
  process, which helps with all manner of things (better folder sync support,
  graphics compatibility, convenient console GUI fixes, _etc_).
  * NOTE:  Use this plugin with care.  It can cause builds to be slower and can
    sometimes cause issues.

Install these with:

```bash
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-scp
vagrant plugin install vagrant-sshfs
vagrant plugin install vagrant-vbguest # use with care
```
