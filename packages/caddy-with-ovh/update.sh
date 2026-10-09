#!/usr/bin/env bash
# Bump the caddy release this package is pinned to:
#
#   ./packages/caddy-with-ovh/update.sh 2.12.0
#
# nix-update can't do this one, which is why the package is not in the
# `packages` array in scripts/update.sh: the sources are go.mod/go.sum rather
# than a fetched tarball, so a version bump has to re-resolve the module graph
# before vendorHash means anything. Bumping `version` alone would leave the
# binary on the old release - versionCheckHook catches that and fails the
# build rather than shipping a mislabelled caddy.
#
# The caddy-dns/ovh plugin is pinned in the same two files; bump it by hand
# with `go get github.com/caddy-dns/ovh@vX.Y.Z` and re-run this script.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/caddy-with-ovh"

version="${1:?usage: update.sh <caddy version, e.g. 2.12.0>}"
version="${version#v}"
old_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' default.nix)"

echo "==> pinning caddy v${version}"
go get "github.com/caddyserver/caddy/v2@v${version}"
go mod tidy

sed -i "s|^  version = \".*\";$|  version = \"${version}\";|" default.nix
sed -i "s|^  vendorHash = \".*\";$|  vendorHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";|" default.nix

echo "==> resolving vendorHash"
build="$(cd "$repo_root" && nix build --no-link ".#caddy-with-ovh" 2>&1 || true)"
got="$(printf '%s\n' "$build" | sed -n 's/^ *got: *\(sha256-[A-Za-z0-9+/=]*\)$/\1/p' | head -n1)"

if [ -z "$got" ]; then
    printf '%s\n' "$build" >&2
    echo "error: no vendorHash in the build output above" >&2
    exit 1
fi

sed -i "s|^  vendorHash = \".*\";$|  vendorHash = \"${got}\";|" default.nix
echo "==> vendorHash ${got}"

cd "$repo_root"
nix build --no-link ".#caddy-with-ovh"

echo "==> caddy ${version} builds"
echo "    suggested commit message: caddy-with-ovh: ${old_version} -> ${version}"
