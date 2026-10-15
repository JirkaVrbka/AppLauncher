#!/usr/bin/env bash
# Print a JSON array of the open normal windows on KDE Wayland, one per window:
#   [{ "id": "<internalId>", "class": "<resourceClass>", "title": "<caption>" }, ...]
# `id` is KWin's stable per-window internalId, used to raise that exact window.
set -u

nonce="winlist_${$}_${RANDOM}"

tmp="$(mktemp --suffix=.js)"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" <<EOF
const out = [];
const wins = (typeof workspace.windowList === "function") ? workspace.windowList() : workspace.clientList();
for (let i = 0; i < wins.length; i++) {
    const w = wins[i];
    if (w.specialWindow) continue;
    if (w.normalWindow === false) continue;
    const rc = (w.resourceClass || "").toLowerCase();
    if (rc.length === 0) continue;
    out.push({ id: "" + w.internalId, class: rc, title: "" + (w.caption || "") });
}
print("$nonce " + JSON.stringify(out));
EOF

sid="$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$tmp" 2>/dev/null)"
if [ -z "$sid" ]; then
    echo "[]"
    exit 0
fi
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run  >/dev/null 2>&1
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.stop >/dev/null 2>&1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$tmp" >/dev/null 2>&1

line=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    line="$(journalctl --user -b --since "-5 seconds" 2>/dev/null | grep "$nonce" | tail -1)"
    [ -n "$line" ] && break
    sleep 0.05
done

json="$(printf '%s' "$line" | sed -E "s/.*${nonce} //")"
case "$json" in
    \[*\]) printf '%s\n' "$json" ;;
    *)     echo "[]" ;;
esac
