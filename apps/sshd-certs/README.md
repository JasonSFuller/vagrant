# SSH CA/cert testing

Configure sshd to allow auth from signed user certificates, and likewise,
configure ssh clients to trust signed server public keys (and skip the
fingerprint approval/warnings).

## Prerequisites

Install Vagrant.

* <https://www.vagrantup.com/downloads>

Install the `sshfs` Vagrant plugin.

```bash
vagrant plugin install vagrant-sshfs
```
