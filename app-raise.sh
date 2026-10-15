#!/usr/bin/env bash
# Raise an already-running app's window on KDE Wayland, matched by window class.
#
# Usage: app-raise.sh <match-key>
#
# Exit 0  -> a matching window was found and activated (caller should NOT launch)
# Exit 10 -> no matching window found (caller SHOULD launch a new instance)
#
# <match-key> is typically the app's StartupWMClass or desktop id. Matching is
# case-insensitive against each window's resourceClass / resourceName: exact
# match first, then substring. First match wins.
set -u

key="${1:-}"
[ -z "$key" ] && exit 10

nonce="appraise_${$}_${RANDOM}"

tmp="$(mktemp --suffix=.js)"
trap 'rm -f "$tmp"' EXIT

esc="$(printf '%s' "$key" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

cat > "$tmp" <<EOF
const want = "$esc".toLowerCase();
const wins = (typeof workspace.windowList === "function") ? workspace.windowList() : workspace.clientList();
let exact = null, partial = null;
for (let i = 0; i < wins.length; i++) {
    const w = wins[i];
    if (w.specialWindow) continue;
    const rc = (w.resourceClass || "").toLowerCase();
    const rn = (w.resourceName || "").toLowerCase();
    if (rc === want || rn === want) { exact = w; break; }
    if (partial === null && (rc.indexOf(want) !== -1 || rn.indexOf(want) !== -1 || want.indexOf(rc) !== -1)) {
        if (rc.length > 0) partial = w;
    }
}
const hit = exact || partial;
if (hit) {
    if ("activeWindow" in workspace) workspace.activeWindow = hit;
    else workspace.activeClient = hit;
    print("$nonce FOUND");
} else {
    print("$nonce NOTFOUND");
}
EOF

sid="$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$tmp" 2>/dev/null)"
if [ -z "$sid" ]; then
    exit 10   # can't reach KWin -> let caller launch
fi
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run  >/dev/null 2>&1
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.stop >/dev/null 2>&1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$tmp" >/dev/null 2>&1

# Read the result line from the user journal, with a short retry.
res=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    res="$(journalctl --user -b --since "-5 seconds" 2>/dev/null | grep "$nonce" | tail -1)"
    [ -n "$res" ] && break
    sleep 0.05
done

case "$res" in
    *NOTFOUND*) exit 10 ;;   # check NOTFOUND first: it contains "FOUND"
    *FOUND*)    exit 0  ;;
    *)          exit 10 ;;   # journal unreadable -> caller launches
esac
