#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

# Flake output attributes (packages.<system>.<name>) to bump with nix-update.
# caddy-with-ovh is deliberately absent: its sources are go.mod/go.sum rather
# than a fetched tarball, so nix-update can't re-resolve the module graph, and
# bumping `version` alone would leave the binary on the old release. Bump it
# with packages/caddy-with-ovh/update.sh instead.
packages=(
    helium
    photocraft
    cadcraft
    filmcraft
    vectorcraft
)

nix flake update --commit-lock-file

if ! command -v nix-update >/dev/null 2>&1; then
    echo "error: nix-update not found on PATH (nix profile install nixpkgs#nix-update)" >&2
    exit 1
fi

# --quiet appears to be broken currently https://github.com/Mic92/nix-update/issues/483
# so just write to a file
commit_msg_file="$(mktemp)"
trap 'rm -f "$commit_msg_file"' EXIT

for pkg in "${packages[@]}"; do
    echo "==> $pkg"
    nix-update --flake "$pkg" --write-commit-message "$commit_msg_file"
    msg="$(cat "$commit_msg_file")"

    if git diff --quiet -- "packages/$pkg"; then
        echo "    already up to date; nothing to commit."
        continue
    fi

    git add "packages/$pkg"
    git commit -m "$msg"
done
