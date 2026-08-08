#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

# Flake output attributes (packages.<system>.<name>) to bump with nix-update.
packages=(
    helium
)

nix flake update --commit-lock-file

if ! command -v nix-update >/dev/null 2>&1; then
    echo "error: nix-update not found on PATH (nix profile install nixpkgs#nix-update)" >&2
    exit 1
fi

for pkg in "${packages[@]}"; do
    echo "==> $pkg"
    msg="$(nix-update --flake "$pkg" --print-commit-message)"

    if git diff --quiet -- "packages/$pkg"; then
        echo "    already up to date; nothing to commit."
        continue
    fi

    git add "packages/$pkg"
    git commit -m "$msg"
done
