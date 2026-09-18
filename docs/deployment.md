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

## One command

```sh
just deploy jupiter                # NixOS + home-manager + checkout for one home host
just sys venus                     # NixOS only
just deploy saturn                 # stages the generation; reboot it when convenient
just deploy-hetzner                # the Hetzner box
just deploy-all                    # everything
```

`deploy` also rsyncs this checkout to `/home/barnabas/src/github.com/foldu/nixos-config/`
on the host, so every home host keeps a usable local copy of the flake.

Run it **from jupiter**. That's not a preference — jupiter is the only correct
root for this:

- A lot of this flake gets *compiled* (kernel, GPU/nvidia bits, packages absent from
the public caches), so each host that builds for itself pays that cost, and
`nh clean` / GC takes it back a couple of weeks later.
- Builds on jupiter land in the store that harmonia serves, so every other host
substitutes them instead. Builds on saturn/venus land *nowhere* anyone else can
see (cashewnix is pull-only) and eventually get collected → recompiled.
- `nix.gc.automatic = mkForce false` on jupiter, so its store is the durable cache.

Deploying from saturn or venus "works", it just moves the compile cost
onto venus and skips the cache. Don't. The flake is also evaluated on the driver,
which needs mesh access to the private inputs.

## Fallback: rsync + rebuild locally

Still the way to do the very first deploy on a machine. Sync to the target:
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
`lab.home.5kw.li` (it runs the netbird server itself) and cannot evaluate this flake, nor
substitute from jupiter's cache. It is built on one of the home hosts under qemu aarch64
emulation and the closure is pushed over ssh — `just deploy-hetzner` does exactly that:

```sh
nixos-rebuild switch --flake .#ubuntu-4gb-fsn1-3 \
  --target-host root@ubuntu-4gb-fsn1-3.5kw.li
```

Needed options for this to work on the build host:

- `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` - qemu user emulation
- `nix.settings.extra-platforms = [ "aarch64-linux" ]` - nix daemon schedules
  aarch64 builds locally
