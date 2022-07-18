#!/usr/bin/env bash
set -euo pipefail

setup_resolve() {
    echo "Setting resolvers for nm-home"
    resolvectl domain nm-home '~home.5kw.li'
    resolvectl dns nm-home 10.20.30.3
}

setup_resolve

exists=1
ip monitor link |
    while read -r line; do
        if echo "$line" | grep -Eq '^Deleted.+nm-home'; then
            exists=0
        elif test "$exists" -eq 0 && echo "$line" | grep -q 'nm-home' && ! echo "$line" | grep -q DOWN; then
            exists=1
            echo "Change detected"
            setup_resolve
        fi
    done
