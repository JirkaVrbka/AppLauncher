#!/usr/bin/env bash
# List Obsidian notes from the active vault as a JSON array for the launcher.
#
# Each item: { "title": "<basename, no .md>", "file": "<vault-relative path, no
# .md>", "vault": "<vault name>" }. `file` + `vault` build the open URI
# (obsidian://open?vault=..&file=..); `title` + `file` are what the launcher
# searches and shows.
#
# The vault is auto-detected from Obsidian's own registry (obsidian.json): the
# vault marked "open", else the first one. Both the Flatpak config path and the
# native path are checked. On any failure we print "[]" and exit 0 so the
# launcher just shows its empty-state hint instead of breaking.
set -euo pipefail

emit_empty() { echo "[]"; exit 0; }

command -v jq >/dev/null 2>&1 || emit_empty

# obsidian.json location: Flatpak first, then a native install.
CONFIG=""
for c in \
    "$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json" \
    "$HOME/.config/obsidian/obsidian.json"; do
    if [[ -f "$c" ]]; then CONFIG="$c"; break; fi
done
[[ -n "$CONFIG" ]] || emit_empty

# Pick the open vault's path, else the first vault's path.
VAULT_PATH="$(jq -r '
    .vaults // {} | to_entries
    | (map(select(.value.open == true)) + .) | .[0].value.path // empty
' "$CONFIG" 2>/dev/null || true)"
[[ -n "$VAULT_PATH" && -d "$VAULT_PATH" ]] || emit_empty

# Obsidian's default vault name (used by the obsidian:// vault= param) is the
# vault folder's basename.
VAULT_NAME="$(basename "$VAULT_PATH")"

# All .md files, excluding Obsidian's own dirs. Each vault-relative path with
# the .md suffix stripped is `file`; its basename is `title`. find -print0 +
# mapfile -d '' keep paths with spaces/newlines intact; the relative paths are
# then handed to jq as positional --args (no NUL/newline parsing in jq).
files=()
while IFS= read -r -d '' f; do
    rel="${f#"$VAULT_PATH"/}"
    files+=("${rel%.md}")
done < <(find "$VAULT_PATH" -type f -name '*.md' \
    -not -path '*/.obsidian/*' -not -path '*/.trash/*' -print0 2>/dev/null)

jq -n --arg vault "$VAULT_NAME" '
    $ARGS.positional
    | map({ title: (split("/") | last), file: ., vault: $vault })
' --args "${files[@]+"${files[@]}"}" || emit_empty
