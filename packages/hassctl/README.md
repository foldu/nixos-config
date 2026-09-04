# hassctl — HA control endpoint for LAN devices

`hassctl` is a small static Go binary that lets Home Assistant (or anything
else on the netbird mesh) wake, power off, and check the liveness of devices
on the home LAN.

Use case for this repo: home assistant and my other computers are on separate networks,
but I still want to control my PCs through the UI.

## Architecture

Concrete:
```
hass (IoT, mesh 172.25.74.192)
  │  HTTP over netbird mesh, X-Token auth
  ▼
netbird-gw (mesh 172.25.74.230, eth0 @ 192.168.8.116 on home L2)
  ├─ UDP magic packet broadcast on the home LAN to wake up PC
  ├─ SSH (x/crypto) → poweroff
  └─ TCP connect to the target's sshd (liveness)
```

## Config

File: `/etc/hassctl/config.yaml` (mode 0600, deployed by ansible from sops).
Every key can be overridden with a `HASSCTL_*` environment variable
(`HASSCTL_TOKEN`, `HASSCTL_WAKE_BROADCAST`, `HASSCTL_DEVICES_JUPITER_MAC`, …).

```yaml
token: "shared-secret"        # required (or env HASSCTL_TOKEN); X-Token header
listen: "172.25.74.230:8080"  # bind to the mesh address — do NOT bind 0.0.0.0

# defaults, overridable per-device
wake:
  localAddr: "192.168.8.116"  # source IP for the magic packet (eth0)
  broadcast: "192.168.8.255"  # directed broadcast of the home subnet
poweroff:
  user: "powerctl"
  sshKey: "/etc/hassctl/keys/poweroff"
  timeout: "5s"

devices:
  jupiter:
    mac: "xx:xx:xx:xx:xx:xx"
    status: "192.168.8.107:22"
    poweroff:
      addr: "192.168.8.107:22"
      # user / sshKey / timeout / wake.* can all be overridden per device
```

## Endpoints

Interactive docs (ReDoc) for this are at: [**`/docs`**](/docs).

| Endpoint                 | Method | Auth  | Response |
| ------------------------ | ------ | ----- | -------- |
| `/`                      | GET    | no    | HTML page: this README rendered |
| `/docs`                  | GET    | no    | Interactive API docs (ReDoc) |
| `/openapi.yaml`          | GET    | no    | The OpenAPI spec (consumed by ReDoc) |
| `/api/devices`           | GET    | yes   | `{"ok": true, "devices": {…}}` — all devices with live state |
| `/api/devices/{id}`      | GET    | yes   | `{"ok": true, "device": {…}}` — one device with live state |
| `/api/devices/{id}/wake` | POST   | yes   | `{"ok": true}` — magic packet sent |
| `/api/devices/{id}/off`  | POST   | yes   | `{"ok": true}` — poweroff triggered (idempotent) |


## Home Assistant wiring

Concrete config example for my jupiter PC. Everything is proxied
through hassctl.

```yaml
rest_command:
  wake_jupiter:
    url: "http://172.25.74.230:8080/api/devices/jupiter/wake"
    method: POST
    headers:
      X-Token: !secret hassctl_token
  off_jupiter:
    url: "http://172.25.74.230:8080/api/devices/jupiter/off"
    method: POST
    headers:
      X-Token: !secret hassctl_token

binary_sensor:
  - platform: rest
    name: "Jupiter up"
    resource: "http://172.25.74.230:8080/api/devices/jupiter"
    method: GET
    headers:
      X-Token: !secret hassctl_token
    value_template: "{{ value_json.device.state == 'on' }}"
    device_class: connectivity

switch:
  - platform: template
    switches:
      jupiter:
        friendly_name: "Jupiter"
        value_template: "{{ is_state('binary_sensor.jupiter_up', 'on') }}"
        turn_on:
          action: rest_command.wake_jupiter
        turn_off:
          action: rest_command.off_jupiter
```

The REST binary sensor polls `GET /api/devices/jupiter` on the binary_sensor
platform interval (30s); the probe itself is a 1s-timeout TCP connect.

## PC side (NixOS)

Of course, wol needs to be enabled.

The sudo rule targets a stable-path wrapper (`/etc/hassctl/poweroff`) on
purpose: sudo-rs canonicalizes command paths by resolving *directory*
symlinks but never the command itself, so a forced command via
`/run/current-system/sw/bin/poweroff` would canonicalize to an unstable
system-path store path that a `${pkgs.systemd}`-style store-path rule never
matches (and whose hash churns on every rebuild). The `/etc` wrapper
canonicalizes identically on both the sudoers and the request side, so the
rule always matches.

```nix
environment.etc."hassctl/poweroff".source = pkgs.writeShellScript "hassctl-poweroff" ''
  exec ${pkgs.systemd}/bin/poweroff
'';

users.users.powerctl = {
  isSystemUser = true;
  group = "powerctl";
  shell = pkgs.bash; # forced commands run via $SHELL -c; nologin would reject them
  extraGroups = [ "wheel" ]; # sudo-rs execWheelOnly = true
  openssh.authorizedKeys.keys = [
    # forced command + restrict: this key can do nothing but run sudo
    # /etc/hassctl/poweroff as root
    "command=\"/run/wrappers/bin/sudo /etc/hassctl/poweroff\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlajkEqswqSxvleHVtZEFOv9OTCInqHpRch43/iL6LV"
  ];
};

users.groups.powerctl = { };

# passwordless sudo for exactly this one wrapper (powerctl has no password,
# and the key is forced-command restricted to this anyway)
security.sudo-rs.extraRules = [{
  users = [ "powerctl" ];
  commands = [{ command = "/etc/hassctl/poweroff"; options = [ "NOPASSWD" ]; }];
}];
```

## Secrets & deploy

The token, the poweroff SSH private key, and the config file live in the
sops-encrypted `secrets/secrets.yaml` under `hassctl:` (`token`, `ssh-key`,
`config`). The deploy playbook extracts the config and key into local temp
files (multi-line values don't survive env-var injection), then copies the
binary, config, key, and systemd unit to netbird-gw:

```sh
nix build .#hassctl -o result
mkdir -m 0700 -p /tmp/hassctl-deploy
sops -d secrets/secrets.yaml --extract '["hassctl"]["config"]'  > /tmp/hassctl-deploy/config.yaml
sops -d secrets/secrets.yaml --extract '["hassctl"]["ssh-key"]' > /tmp/hassctl-deploy/poweroff
chmod 0600 /tmp/hassctl-deploy/config.yaml /tmp/hassctl-deploy/poweroff

HASSCTL_BINARY=$(readlink -f result/bin/hassctl) \
  HASSCTL_CONFIG_FILE=/tmp/hassctl-deploy/config.yaml \
  HASSCTL_SSH_KEY_FILE=/tmp/hassctl-deploy/poweroff \
  ansible-playbook playbooks/hassctl.yml

rm -rf /tmp/hassctl-deploy
```

## Development

```sh
cd packages/hassctl
go test ./
nix build .#hassctl
```
