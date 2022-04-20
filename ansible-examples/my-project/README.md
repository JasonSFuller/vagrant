# My Project

An example Ansible project to highlight how roles work, passing arguments to
roles, and using surveys in Ansible Tower to pass arguments to Ansible plays.

## Ansible Tower surveys

Unfortunately (as of Tower 3.8.5), there is no convenient way of
import/exporting a single job template (and it's survey questions) from Ansible
Tower.  The JSON below is a capture of the survey questions used by the primary
job template in this project.  It was captured with:

```bash
awx export -k --job_templates
```

Regardless, you'll have to manually recreate these survey questions in Ansible
Tower.

```json
"survey_spec": {
      "name": "",
      "description": "",
      "spec": [
          {
                "question_name": "Virtual server - name",
                "question_description": "REQUIRED; ex: jfuller-test-virtual-server",
                "required": true,
                "type": "text",
                "variable": "ui_vs_name",
                "min": 0,
                "max": 1024,
                "default": "jfuller-test-virtual-server",
                "choices": ""
          },
          {
                "question_name": "Virtual server - destination",
                "question_description": "REQUIRED; ex: 172.23.20.40",
                "required": true,
                "type": "text",
                "variable": "ui_vs_destination",
                "min": 0,
                "max": 1024,
                "default": "172.23.20.40",
                "choices": ""
          },
          {
                "question_name": "Virtual server - port",
                "question_description": "REQUIRED; ex: 80",
                "required": true,
                "type": "integer",
                "variable": "ui_vs_port",
                "min": 1,
                "max": 65535,
                "default": 80,
                "choices": ""
          },
          {
                "question_name": "Virtual server - IP protocol",
                "question_description": "REQUIRED; ex: tcp",
                "required": true,
                "type": "multiplechoice",
                "variable": "ui_vs_ip_protocol",
                "min": null,
                "max": null,
                "default": "tcp",
                "choices": "ah\nany\nbna\nesp\netherip\ngre\nicmp\nipencap\nipv6\nipv6-auth\nipv6-crypt\nipv6-icmp\nisp-ip\nmux\nospf\nsctp\ntcp\nudp\nudplite"
          },
          {
                "question_name": "Pool - name",
                "question_description": "OPTIONAL: empty means pool creation and assignment to virtual server will be skipped; ex: jfuller-test-pool",
                "required": false,
                "type": "text",
                "variable": "ui_pool_name",
                "min": 0,
                "max": 1024,
                "default": "jfuller-test-pool",
                "choices": ""
          },
          {
                "question_name": "Profile HTTP - name",
                "question_description": "OPTIONAL: empty means profile creation and assignment to virtual server will be skipped; ex: jfuller-test-profile",
                "required": false,
                "type": "text",
                "variable": "ui_profile_name",
                "min": 0,
                "max": 1024,
                "default": "jfuller-test-profile",
                "choices": ""
          },
          {
                "question_name": "Profile HTTP - insert X-Forwarded-For",
                "question_description": "OPTIONAL: empty means X-Forwarded-For value is inherited from the parent profile",
                "required": false,
                "type": "multiplechoice",
                "variable": "ui_profile_insert_xforwarded_for",
                "min": null,
                "max": null,
                "default": "",
                "choices": "no\nyes"
          },
          {
                "question_name": "Profile HTTP - redirect rewrite",
                "question_description": "OPTIONAL: empty means redirect/rewrite value is inherited from the parent profile",
                "required": false,
                "type": "multiplechoice",
                "variable": "ui_profile_redirect_rewrite",
                "min": null,
                "max": null,
                "default": "",
                "choices": "none\nall\nmatching\nnodes",
                "new_question": true
          }
      ]
}
```

## Further reading

### Ansible

* [Using roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#using-roles)
* [F5 modules](https://docs.ansible.com/ansible/latest/collections/f5networks/f5_modules/)
  * [`bigip_virtual_server`](https://docs.ansible.com/ansible/latest/collections/f5networks/f5_modules/bigip_virtual_server_module.html)
  * [`bigip_pool`](https://docs.ansible.com/ansible/latest/collections/f5networks/f5_modules/bigip_pool_module.html)
  * [`bigip_profile_http`](https://docs.ansible.com/ansible/latest/collections/f5networks/f5_modules/bigip_profile_http_module.html)
* [Updating "active devices only" and syncing a device to a group](https://support.f5.com/csp/article/K10531487)
* [Making variables optional](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html#making-variables-optional)
* [Testing strings](https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html#testing-strings)

### Jinja

* [Built-in test](https://jinja.palletsprojects.com/en/latest/templates/#builtin-tests)
* [Built-in filters](https://jinja.palletsprojects.com/en/latest/templates/#builtin-filters)
