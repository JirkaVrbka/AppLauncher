#!/usr/bin/env bash
# Emit JSON for the top bar bits that aren't covered by Quickshell services:
#   { "layout": "EN", "wsCount": 2, "wsActive": 0 }
# (keyboard layout + KWin virtual desktops via gdbus). Wi-Fi lives in netinfo.sh.
set -u

KB=org.kde.keyboard
KW=org.kde.KWin

gd() { gdbus call --session "$@" 2>/dev/null; }

# --- keyboard layout ---
idx="$(gd --dest "$KB" --object-path /Layouts --method org.kde.KeyboardLayouts.getLayout | sed 's/uint32//g' | grep -oE '[0-9]+' | head -1)"
[ -z "$idx" ] && idx=0
codes="$(gd --dest "$KB" --object-path /Layouts --method org.kde.KeyboardLayouts.getLayoutsList | grep -oP "\('\K[a-z]+")"
code="$(printf '%s\n' "$codes" | sed -n "$((idx + 1))p")"
case "$code" in
    us|en|"") layout="EN" ;;
    *) layout="$(printf '%s' "$code" | tr '[:lower:]' '[:upper:]')" ;;
esac

# --- virtual desktops ---
count="$(gd --dest "$KW" --object-path /VirtualDesktopManager --method org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager count | sed 's/uint32//g' | grep -oE '[0-9]+' | head -1)"
[ -z "$count" ] && count=1
cur="$(gd --dest "$KW" --object-path /VirtualDesktopManager --method org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager current | grep -oE '[0-9a-f]{8}-[0-9a-f-]+' | head -1)"
desks="$(gd --dest "$KW" --object-path /VirtualDesktopManager --method org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager desktops)"
active="$(printf '%s' "$desks" | sed 's/), (/\n/g' | grep -F "$cur" | sed 's/uint32//g' | grep -oE '[0-9]+' | head -1)"
[ -z "$active" ] && active=0

printf '{"layout":"%s","wsCount":%s,"wsActive":%s}\n' "$layout" "$count" "$active"
