#!/usr/bin/env bash
# Raise/activate a specific window on KDE Wayland by its KWin internalId.
# Usage: raise-window.sh "<internalId>"   (as printed by list-windows.sh)
set -u

want="${1:-}"
[ -z "$want" ] && exit 1

# Wait for the launcher overlay to close first; otherwise KWin restores focus to
# the previous window when it unmaps, overriding our activation.
sleep 0.3

tmp="$(mktemp --suffix=.js)"
trap 'rm -f "$tmp"' EXIT

esc="$(printf '%s' "$want" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

cat > "$tmp" <<EOF
const want = "$esc";
const wins = (typeof workspace.windowList === "function") ? workspace.windowList() : workspace.clientList();
for (let i = 0; i < wins.length; i++) {
    const w = wins[i];
    if (("" + w.internalId) === want) {
        if ("activeWindow" in workspace) workspace.activeWindow = w;
        else workspace.activeClient = w;
        break;
    }
}
EOF

sid="$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$tmp" 2>/dev/null)"
[ -z "$sid" ] && exit 0
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run  >/dev/null 2>&1
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.stop >/dev/null 2>&1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$tmp" >/dev/null 2>&1
