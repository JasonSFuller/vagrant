# Ansible Automation Platform 1.2 (a.k.a. Tower)

This is the old version of Tower and not recommended, but sometimes I need it
for testing and/or upgrading.

## Installation

- Add your Red Hat developer credentials to the `.env` file.
- Create a [subscription allocation] w/ 1 or 2 entitlements.
- Download [ansible-automation-platform-setup-bundle-1.2.7-2.tar.gz] and copy it
  to this directory.
  - _Note: The RHEL 7 version will work on RHEL 8._
- Run `vagrant up`.
- Go to `https://YOUR_HOST:8443` and login with `admin` and `password`.

[subscription allocation]: https://access.redhat.com/management/subscription_allocations
[ansible-automation-platform-setup-bundle-1.2.7-2.tar.gz]: https://access.redhat.com/downloads/content/480/ver=1.2/rhel---7/1.2/x86_64/product-software
