# Fedora CoreOS

## TODO

- No logins created by default.  Need to add `vagrant` user and default SSH key.
- Update the script to pull vars automatically from
  [stable.json](https://builds.coreos.fedoraproject.org/streams/stable.json)
  instead of hardcoding.

```shell
jq -r '.architectures.x86_64.artifacts.virtualbox' \
  <(curl -sSL https://builds.coreos.fedoraproject.org/streams/stable.json)
```

Example output:

```text
{
  "release": "38.20230625.3.0",
  "formats": {
    "ova": {
      "disk": {
        "location": "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230625.3.0/x86_64/fedora-coreos-38.20230625.3.0-virtualbox.x86_64.ova",
        "signature": "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230625.3.0/x86_64/fedora-coreos-38.20230625.3.0-virtualbox.x86_64.ova.sig",
        "sha256": "2ad09f2412840d368f49e35fe419247fd561d47209ab0380cb42672bb8d6d878"
      }
    }
  }
}
```
