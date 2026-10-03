#!/usr/bin/env bash
set -euo pipefail
# Start an app only once DMS's tray is on the bus. Apps launched before
# org.kde.StatusNotifierWatcher appears never get a tray icon, which is why a
# plain spawn-at-startup isn't enough for them.
# stolen and adapted from https://github.com/niri-wm/niri/issues/3177#issuecomment-3901690273

if [ "$#" -eq 0 ]; then
  echo "usage: ${0##*/} <command> [args...]" >&2
  exit 2
fi

# 1. Wait until the dms-tray shows up on D-Bus.
timeout 10s sh -c '
  until dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep -q "org.kde.StatusNotifierWatcher"; do
   sleep 0.5
  done
'

exec "$@"
