#!/usr/bin/env bash
# Build every NixOS and home-manager configuration in one pass.
#
#   ./scripts/build-all.sh                  # all seven targets
#   ./scripts/build-all.sh nixos:saturn     # one target
#   ./scripts/build-all.sh home:jupiter nixos:venus
#
# A bare host means both of its configurations where a home one exists. Every
# target is attempted even after a failure, logs are kept for the failures, and
# the exit status is nonzero if anything failed. Run this on jupiter: builds
# there land in the store the other hosts substitute from (docs/deployment.md).
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

nixos_hosts=(jupiter saturn venus ubuntu-4gb-fsn1-3)
home_hosts=(jupiter saturn venus)

targets=()
if (($# == 0)); then
    for host in "${nixos_hosts[@]}"; do targets+=("nixos:$host"); done
    for host in "${home_hosts[@]}"; do targets+=("home:$host"); done
else
    for arg in "$@"; do
        case "$arg" in
            nixos:*|home:*)
                targets+=("$arg")
                ;;
            *)
                if [[ " ${nixos_hosts[*]} " == *" $arg "* ]]; then
                    targets+=("nixos:$arg")
                fi
                if [[ " ${home_hosts[*]} " == *" $arg "* ]]; then
                    targets+=("home:$arg")
                fi
                if [[ " ${nixos_hosts[*]} " != *" $arg "* && " ${home_hosts[*]} " != *" $arg "* ]]; then
                    echo "build-all: unknown target: $arg" >&2
                    echo "  expected nixos:<host>, home:<host>, or one of: ${nixos_hosts[*]} ${home_hosts[*]}" >&2
                    exit 2
                fi
                ;;
        esac
    done
fi

# Validate explicit prefixes and drop duplicates while preserving order.
declare -A seen=()
unique=()
for target in "${targets[@]}"; do
    kind="${target%%:*}"
    host="${target#*:}"
    case "$kind" in
        nixos)
            if [[ " ${nixos_hosts[*]} " != *" $host "* ]]; then
                echo "build-all: no such NixOS configuration: $host" >&2
                exit 2
            fi
            ;;
        home)
            if [[ " ${home_hosts[*]} " != *" $host "* ]]; then
                echo "build-all: no home configuration: $host" >&2
                exit 2
            fi
            ;;
    esac
    if [[ -n "${seen[$target]:-}" ]]; then continue; fi
    seen[$target]=1
    unique+=("$target")
done
targets=("${unique[@]}")

log_dir="$(mktemp -d "${TMPDIR:-/tmp}/nixos-config-build.XXXXXX")"
declare -A result=()
failed=0

for target in "${targets[@]}"; do
    kind="${target%%:*}"
    host="${target#*:}"
    case "$kind" in
        nixos) attr=".#nixosConfigurations.${host}.config.system.build.toplevel" ;;
        home) attr=".#homeConfigurations.\"barnabas@${host}\".activationPackage" ;;
    esac
    log="${log_dir}/${kind}-${host}.log"

    printf '==> %s\n' "$target"
    started=$SECONDS
    if nix build --no-link --print-out-paths --log-format raw "$attr" 2>&1 | tee "$log"; then
        result[$target]="ok ($((SECONDS - started))s)"
    else
        result[$target]="FAILED ($((SECONDS - started))s)"
        failed=$((failed + 1))
    fi
done

printf '\n==> summary\n'
for target in "${targets[@]}"; do
    printf '  %-28s %s\n' "$target" "${result[$target]}"
done

if ((failed > 0)); then
    printf '\n%d target(s) failed; logs kept in %s\n' "$failed" "$log_dir"
    exit 1
fi

rm -rf "$log_dir"
printf '\nall %d targets built\n' "${#targets[@]}"
