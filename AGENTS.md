# AGENTS.md — nixos-config

One flake, four NixOS hosts, home-manager config in the same repo. Private flake
inputs (lab.home.5kw.li) are only reachable from the home mesh — see
`docs/deployment.md` before evaluating on a machine you're unsure about.

## Checking your work

```sh
nix fmt                                         # treefmt via the flake formatter, formats the repo
nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel.drvPath
nix build .#homeConfigurations."barnabas@venus".activationPackage
```

Eval is enough to catch most mistakes and is safe for any host. **Never build
the Hetzner config on the Hetzner box** — it can't reach the private inputs and
is aarch64, so it gets built on a home host under qemu emulation.

## Layout

- `flake.nix` — hosts, home configs, `specialArgs` (`inputs`, `outputs`,
  `home-network`, `getSettings`).
- `nixos/<host>/default.nix` — imports a profile plus host services.
- `nixos/common/{generic,profiles,home,graphical}` — shared modules.
- `home/<host>/` → `home/common/{generic,dev,terminal,graphical,gnome}`.
- `settings.nix` — fonts and default apps, consumed as `getSettings pkgs`. Add an
  app/browser/font here, not as a second literal somewhere else.
- `home-network.toml` — devices/IPs/DNS, available as the `home-network` arg.
- `packages/<name>/` + `overlays/extra.nix` for local derivations,
  `overlays/customizations.nix` for overriding upstream ones, `lib/default.nix`
  for tiny helpers (`btrfsSubvolOn`, `mkPrometheusRules`).
- `ansible/` manages the non-NixOS boxes (Proxmox/Debian).

## Where does a change go?

- Home machines only → `nixos/common/home`. jupiter/venus get it via their
  profile, saturn imports it explicitly; the Hetzner box doesn't.
- Every host → `nixos/common/generic` (this includes the Hetzner box: keep it to
  cheap, cached packages, since anything uncached is compiled under emulation).
- `profiles/server.nix` is _not_ a home-vs-remote discriminator — saturn uses it.

## Secrets

sops-nix. `secrets/secrets.yaml` belongs to the home hosts + admin,
`secrets/hetzner.yaml` to the Hetzner host; each host sets `sops.defaultSopsFile`.
Do not touch it. Only read it. You can't touch it anyway.

## Gotchas

- `hardware-configuration.nix` is generated; touch it only for real hardware changes.
- quadlet containers use `:latest` when the image publishes that tag, and always set
  `autoUpdate = "registry"`. A pinned tag is for a tag that carries meaning: a major
  channel (`gluetun:v3`), a variant (`llama.cpp:server-rocm`), a database version
  (`postgres:16-alpine`) — not a version number to bump by hand.

## Commits

Imperative mood, area prefix, no body unless the why is non-obvious:

```
venus: Use regular linux kernel
helium: 0.16.5.1 -> 0.17.0.1
flake.lock: Update
Add hassctl power controller
```
