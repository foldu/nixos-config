#!/usr/bin/env bash
set -euo pipefail
# stolen and adapted from https://github.com/niri-wm/niri/issues/3177#issuecomment-3901690273

# 1. Wait until the dms‑tray shows up on D‑Bus.
timeout 10s sh -c '
  until dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep -q "org.kde.StatusNotifierWatcher"; do
   sleep 0.5
  done
'

exec bitwarden
