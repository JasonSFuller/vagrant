# Install Ansible venvs for AAP 1.2

Installing extra Ansible virtual environments in AAP 1.2 comes with a few
challenges on RHEL 7, namely all of the software is end of life and no longer
supported.

Having said that, the first challenge is that Python 2.7 is the OS default (i.e.
python-2.7.5-94.el7_9.x86_64), and Python 3.6 is the last version in the
_default_ OS yum repos (i.e. python3-3.6.8-21.el7_9.x86_64). In both cases,
Ansible 4.10.0 is the last release supporting either of these older Python
versions.

You can install Python 3.8 via the SCL, but this only gets you up to Ansible
6.7.0.

As of Feb 2024:

| Ansible | Core | Core Python req.    | Status                                         |
| ------- | ---- | ------------------- | ---------------------------------------------- |
| 10.0.0  | 2.17 | ?                   | In development (unreleased)                    |
| 9.x     | 2.16 | Python 3.10-3.12    | Current                                        |
| 8.x     | 2.15 | Python 3.9-3.11     | Unmaintained (end of life) after Ansible 8.7.0 |
| 7.x     | 2.14 | Python 3.9-3.11     | Unmaintained (end of life)                     |
| 6.x     | 2.13 | Python 3.8-3.10     | Unmaintained (end of life)                     |
| 5.x     | 2.12 | Python 3.8-3.10     | Unmaintained (end of life)                     |
| 4.x     | 2.11 | Python 2.7, 3.5-3.9 | Unmaintained (end of life)                     |
| 3.x     | 2.10 | Python 2.7, 3.5-3.9 | Unmaintained (end of life)                     |
| 2.10    | 2.10 | Python 2.7, 3.5-3.9 | Unmaintained (end of life)                     |

## SOURCES

- [Using virtualenv with Ansible Tower](https://docs.ansible.com/ansible-tower/latest/html/upgrade-migration-guide/virtualenv.html)
- [Ansible community changelogs](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-community-changelogs)
- [Ansible core support matrix](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix)
- [Ansible release history on PyPI](https://pypi.org/project/ansible/#history)
