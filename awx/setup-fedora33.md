# Fedora 33 setup notes

Enable [RPM Fusion](https://rpmfusion.org/Configuration) if you haven't already.

    sudo dnf install -y \
      https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
      https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

Update your system.

    sudo dnf update -y
    sudo reboot

Install [VirtualBox](https://www.virtualbox.org/) and add your username to the
`vboxusers` group.

    sudo dnf install VirtualBox
    sudo usermod -a -G vboxusers "$USER"

> **IMPORTANT:**  If you have Secure Boot enabled, you'll have to disable it in
> the BIOS.  Otherwise, the unsigned VirtualBox kernel drivers won't load, and
> you'll see errors in `journalctl -u vboxdrv`:
>
> Oct 28 12:43:34 nuc10 modprobe[334939]: modprobe: ERROR: could not insert
> 'vboxdrv': Key was rejected by service

Install [Vagrant](https://www.vagrantup.com).

    sudo dnf install -y vagrant


