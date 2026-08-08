# Deployment

The private flake inputs live on `lab.home.5kw.li`, so any machine that evaluates the flake must 
normally reach the home mesh. Machines that can't - e.g. a fresh install before it's on the mesh -
need the bootstrap dance below.

## Bootstrapping a new machine

Bundle the flake and all its inputs (private ones included) into a binary cache
on any machine that can reach them:

```sh
nix flake archive --to file:///tmp/deploy-cache .
```

Transfer the cache to the new machine (USB stick, scp, ...), populate the store
from it, and bring the repo checkout along (rsync, git bundle, ...):

```sh
nix copy --from file:///tmp/deploy-cache --all
nixos-rebuild switch --flake .
```

The locked inputs resolve from the store, so no network access to the mesh is
needed. The cache for this flake is a few hundred MB.

## Home hosts

Deployment is entirely manual. To sync to other machines, do:
```sh
rsync -azvP --filter=':- .gitignore' ./ <host_fqdn>:src/github.com/foldu/nixos-config/
```

Then on the remote machine, cd into the folder and do the usual.

```sh
sudo nixos-rebuild switch --flake .
```

And

```sh
home-manager switch --flake .
```

## External host (ubuntu-4gb-fsn1-3)

The Hetzner server deliberately can't reach
`lab.home.5kw.li` and cannot evaluate this flake itself. It is built on
one of the home hosts under qemu aarch64 emulation and the closure is pushed over ssh:

```sh
nixos-rebuild switch --flake .#ubuntu-4gb-fsn1-3 \
  --target-host root@ubuntu-4gb-fsn1-3.5kw.li
```

Needed options for this to work on the build host:

- `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` - qemu user emulation
- `nix.settings.extra-platforms = [ "aarch64-linux" ]` - nix daemon schedules
  aarch64 builds locally
