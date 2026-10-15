#!/usr/bin/env bash
# Emit a merged JSON array of open "tabs" for the launcher: browser tabs (via
# tabctl) plus kitty terminal tabs (via kitty remote control).
#
# Output: [{ "id", "title", "url", "favIconUrl", "source" }, ...]
#   source = "browser" | "kitty"
#
# Each source is queried independently; if one is unavailable it contributes an
# empty list rather than failing the whole command.
set -u

# Browser tabs from tabctl.
browser="$(tabctl list --format json 2>/dev/null \
    | jq -c '[.[] | {id, title, url, favIconUrl, source: "browser", socket: ""}]' 2>/dev/null)"
[ -z "$browser" ] && browser="[]"

# kitty tabs: kitty appends "-<pid>" to the listen_on socket path and creates one
# socket per running instance, so iterate over every /tmp/kitty-* socket and
# merge their tabs. Each tab carries its own socket so activation can target the
# right instance (tab ids are only unique within one instance). Flatten every OS
# window's tabs; title from the tab, url from the focused window's cwd (fallback
# to the first window's cwd). A dead/unresponsive socket yields nothing.
kitty_tabs="[]"
for sock in /tmp/kitty-*; do
    [ -S "$sock" ] || continue
    part="$(kitty @ --to "unix:$sock" ls 2>/dev/null \
        | jq -c --arg sock "$sock" '[.[] | .tabs[] | {
            id: (.id | tostring),
            title: .title,
            url: ((.windows[]? | select(.is_focused) | .cwd) // (.windows[0].cwd) // ""),
            favIconUrl: "",
            source: "kitty",
            socket: $sock
        }]' 2>/dev/null)"
    [ -z "$part" ] && continue
    kitty_tabs="$(jq -cn --argjson a "$kitty_tabs" --argjson b "$part" '$a + $b')"
done

jq -cn --argjson b "$browser" --argjson k "$kitty_tabs" '$b + $k'
