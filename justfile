# Deploy this flake. Run from jupiter: it has mesh access to the private flake
# inputs, and its store backs the cashewnix cache — a lot of this flake compiles,
# so builds done anywhere else are stranded (and GC'd) instead of substituted.
# See docs/deployment.md.

flake := "."

# system + home-manager + local checkout for one home host
deploy host: (sync host) (sys host) (home host)

# put the flake back at its canonical path on the host, so the machine has a
# checkout to rebuild from locally
sync host:
    rsync -az --filter=':- .gitignore' ./ barnabas@{{host}}:/home/barnabas/src/github.com/foldu/nixos-config/

# NixOS only. saturn stages with `nh os boot` instead of switching live — it runs
# too many services to have them restarted under the running system — so the new
# generation lands there and activates on the next reboot.
sys host:
    #!/usr/bin/env bash
    set -euo pipefail
    mode=switch
    [[ {{host}} == saturn ]] && mode=boot
    nh os "$mode" -H {{host}} --target-host barnabas@{{host}} {{flake}}

# home-manager only: standalone config, so build here, copy, activate there
# (the generation's activate script does the profile bookkeeping itself)
home host:
    #!/usr/bin/env bash
    set -euo pipefail
    gen=$(nix build --no-link --print-out-paths {{flake}}#homeConfigurations."barnabas@{{host}}".activationPackage)
    nix copy --to ssh://barnabas@{{host}} "$gen"
    ssh -t barnabas@{{host}} "$gen/activate"

# Hetzner box: no barnabas user (root-only ssh) and a FQDN
deploy-hetzner:
    nh os switch -H ubuntu-4gb-fsn1-3 --target-host root@ubuntu-4gb-fsn1-3.5kw.li {{flake}}

# every machine
deploy-all: (deploy "jupiter") (deploy "saturn") (deploy "venus") deploy-hetzner
