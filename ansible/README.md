# Ansible

Ansible management for the non-NixOS hosts in the home network.

## Playbooks

### `update-apt.yml` — update Debian/Proxmox hosts

Runs `apt update` + `dist-upgrade` on all `proxmox` and `debian` hosts, then
reports whether a reboot is required.

Options (via `group_vars/all.yml` or `-e`):

| Variable               | Default | Description                                                                  |
| ---------------------- | ------- | ---------------------------------------------------------------------------- |
| `apt_cleanup`          | `false` | also run `autoremove` + `autoclean`                                          |
| `apt_cache_valid_time` | `3600`  | skip `apt update` if cache is fresher than this (s)                          |
| `apt_hold_packages`    | `""`    | comma-separated packages to `apt-mark hold` (e.g. `pve-kernel-*,proxmox-ve`) |

Example with a hold and cleanup:

```sh
ansible-playbook -e 'apt_hold_packages=pve-kernel-*,proxmox-ve apt_cleanup=true' playbooks/update-apt.yml
```

### `telegraf.yml` — deploy telegraf on proxmox hosts

```sh
# the token comes from the sops secrets (secrets/secrets.yaml -> telegraf/env)
VM_AUTH_TOKEN=$(sops -d ../secrets/secrets.yaml | awk '/^telegraf:/{f=1;next} /^[a-z]/{f=0} f && /VM_AUTH_TOKEN/{print}' | cut -d= -f2-)
VM_AUTH_TOKEN=$VM_AUTH_TOKEN ansible-playbook playbooks/telegraf.yml
```
