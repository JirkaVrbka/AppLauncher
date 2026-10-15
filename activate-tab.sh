#!/usr/bin/env bash
# Activate a tab (browser via tabctl, or kitty via remote control), then raise
# its window on KDE Wayland.
#
# Usage: activate-tab.sh <source> <id> [window-title] [kitty-socket]
#   source = "browser" | "kitty"
#
# Switching the tab inside the app does not bring its window forward on KDE
# Wayland (focus-stealing prevention), so we raise it with a KWin script.
#   - kitty: matched by PROCESS ID. Each kitty instance is one process whose pid
#     is the socket-name suffix (/tmp/kitty-<pid>), and KWin exposes w.pid, so we
#     activate that exact window. Caption is only used to pick between that same
#     instance's OS windows. (Matching by caption/title alone is unreliable — a
#     tab literally titled "Obsidian" would otherwise match the Obsidian app.)
#   - browser: matched by the window whose caption contains the tab title.
set -u

source="${1:-}"
id="${2:-}"
title="${3:-}"
sock="${4:-}"

# The caller passes the kitty instance's socket (one per running instance, since
# kitty appends "-<pid>" to the listen_on path). Fall back to the first socket by
# glob only when no socket was given.
[ -z "$sock" ] && sock="$(ls -1 /tmp/kitty-* 2>/dev/null | head -1)"

[ -z "$id" ] && exit 1

kpid=0
case "$source" in
    kitty)
        [ -n "$sock" ] && kitty @ --to "unix:$sock" focus-tab --match "id:$id" >/dev/null 2>&1
        klass="kitty"
        # pid = numeric suffix of the socket name (kitty-<pid>).
        num="${sock##*-}"
        case "$num" in
            ''|*[!0-9]*) kpid=0 ;;
            *) kpid="$num" ;;
        esac
        ;;
    browser|*)
        tabctl activate "$id"
        klass=""
        ;;
esac

# Nothing to match on: best effort done.
[ -z "$title" ] && [ -z "$klass" ] && [ "$kpid" = 0 ] && exit 0

# Give the launcher overlay a moment to close (otherwise KWin restores focus to
# the previous window when it unmaps, overriding our activation) and the app a
# moment to switch tab + update its window caption.
sleep 0.3

tmp="$(mktemp --suffix=.js)"
trap 'rm -f "$tmp"' EXIT

esc_title="$(printf '%s' "$title" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
esc_klass="$(printf '%s' "$klass" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

cat > "$tmp" <<EOF
const want = "$esc_title";
const klass = "$esc_klass".toLowerCase();
const pid = $kpid;
const wins = (typeof workspace.windowList === "function") ? workspace.windowList() : workspace.clientList();
let pidTitle = null, pidAny = null, captionHit = null, classFb = null;
for (let i = 0; i < wins.length; i++) {
    const w = wins[i];
    if (w.specialWindow) continue;
    if (pid > 0 && w.pid === pid) {
        // Exact process (kitty instance). Prefer the OS window whose caption
        // tracks the focused tab; else take any window of this instance.
        if (pidAny === null) pidAny = w;
        if (want.length > 0 && w.caption && w.caption.indexOf(want) !== -1) { pidTitle = w; break; }
        continue;
    }
    if (pid <= 0) {
        if (want.length > 0 && w.caption && w.caption.indexOf(want) !== -1) { captionHit = w; break; }
        if (klass.length > 0 && classFb === null && (w.resourceClass || "").toLowerCase().indexOf(klass) !== -1) classFb = w;
    }
}
const target = pidTitle || pidAny || captionHit || classFb;
if (target) {
    if ("activeWindow" in workspace) workspace.activeWindow = target;
    else workspace.activeClient = target;
}
EOF

sid="$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$tmp" 2>/dev/null)"
[ -z "$sid" ] && exit 0
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run  >/dev/null 2>&1
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.stop >/dev/null 2>&1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$tmp" >/dev/null 2>&1
