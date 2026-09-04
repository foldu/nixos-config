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

### `hassctl.yml` — deploy the hassctl control endpoint (netbird-gw)

Installs the static `hassctl` binary, its systemd unit, and `/etc/hassctl/`
(config + poweroff key) on the `debian` hosts (currently netbird-gw). The
binary is built from the flake; config and key are extracted from sops into
local temp files (see `../packages/hassctl/README.md` for the config schema
and HA wiring).

The `hassctl` section in `secrets/secrets.yaml` looks like:

```yaml
hassctl:
    token: <random hex — shared secret, X-Token header / HA wiring>
    ssh-key: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        …
        -----END OPENSSH PRIVATE KEY-----
    config: |
        listen: "172.25.74.230:8080"
        token: "<same as token above>"
        poweroff:
            user: powerctl
            sshKey: /etc/hassctl/keys/poweroff
            timeout: 5s
        devices:
            jupiter:
                mac: "9c:6b:00:98:ea:03"
                status: "192.168.8.107:22"
                poweroff:
                    addr: "192.168.8.107:22"
```

(wake defaults — `192.168.8.116` as source, `192.168.8.255` as directed
broadcast — are baked into the binary, so they can stay out of the config.)

```sh
# build the static binary
nix build .#hassctl -o result

# extract the multi-line values from sops (single-line env-var injection
# would mangle the SSH key, hence the temp files)
mkdir -m 0700 -p /tmp/hassctl-deploy
sops -d secrets/secrets.yaml --extract '["hassctl"]["config"]'  > /tmp/hassctl-deploy/config.yaml
sops -d secrets/secrets.yaml --extract '["hassctl"]["ssh-key"]' > /tmp/hassctl-deploy/poweroff
chmod 0600 /tmp/hassctl-deploy/config.yaml /tmp/hassctl-deploy/poweroff

# deploy (binary path must be absolute — ansible copy follows the result symlink)
HASSCTL_BINARY=$(readlink -f result/bin/hassctl) \
  HASSCTL_CONFIG_FILE=/tmp/hassctl-deploy/config.yaml \
  HASSCTL_SSH_KEY_FILE=/tmp/hassctl-deploy/poweroff \
  ansible-playbook playbooks/hassctl.yml

# clean up
rm -rf /tmp/hassctl-deploy
```

The `token` is not needed during deploy (it lives inside the config file);
it's referenced later when wiring up Home Assistant (`!secret hassctl_token`).
