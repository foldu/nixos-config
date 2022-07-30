#!/usr/bin/env bash
set -euo pipefail
window_class="Floating Term"
pid_file="/run/user/$UID/floating_term.pid"
session=$(
    cat <<EOF
cd ~/nixos-config/
launch fish
new_tab
cd ~/
launch fish
EOF
)

pid=$(xdotool search --class "$window_class" || true)
if test -z "$pid"; then
    echo "$session" | kitty --class "$window_class" --session -
    exit 0
fi

if test -f "$pid_file"; then
    old_pid=$(cat "$pid_file")
    # if it crashed or something "$pid" != "$old_pid"
    # so it makes sense just to fall through and overwrite
    # the pid file
    if [[ "$old_pid" -eq "$pid" ]]; then
        xdotool windowmap "$pid"
        rm "$pid_file"
        exit 0
    fi
fi

echo "$pid" >"$pid_file"
xdotool windowunmap "$pid"
