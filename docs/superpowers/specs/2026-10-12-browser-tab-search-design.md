# Browser Tab Search in Quickshell Launcher — Design

Date: 2026-10-12
Status: Implemented (see Addendum)

## Goal

Extend the Quickshell app launcher (`shell.qml`) so that typing `tab ` in the
search field switches it into a "tab search" mode. In that mode the list shows
the user's currently open browser tabs across all installed browsers. Selecting
a tab focuses the existing tab (switching to its browser window) instead of
opening a new one.

## Environment

- Kubuntu, KDE Plasma 6 on Wayland.
- Browsers in use: Brave, Chrome/Chromium, Firefox, Zen.
- Quickshell 0.3.1. KWin supports `wlr-layer-shell`, which the launcher already
  uses.

## Chosen approach

Use **tabctl** (https://github.com/slastra/tabctl) as the tab backend. tabctl is
a WebExtension plus native-messaging host plus D-Bus mediator plus a CLI. It
supports Firefox, Zen, Chrome, Chromium and Brave simultaneously, exposes a JSON
list of tabs, and activates a tab (switching desktop if needed) by id.

Alternatives considered and rejected:

- **CDP remote-debugging ports** (per-browser `--remote-debugging-port`):
  requires launching every browser with a flag, flaky for Firefox/Zen, and opens
  a debug port. Rejected in favor of a uniform, live solution.
- **brotab / bruvtab** (pip/uv installable): viable, but the user chose tabctl
  for its D-Bus architecture, MV3 extension, and native multi-browser support.
- **Session-store file reading**: stale and fragile. Rejected.

## Prerequisites (one-time, outside the launcher)

tabctl is not packaged for Kubuntu, so it is built from source:

1. `git clone https://github.com/slastra/tabctl.git && cd tabctl && make build`
   (requires Go 1.19+ and a D-Bus session bus).
2. `./build/tabctl install` — installs the native-messaging host manifests.
3. Install the browser extension: AMO for Firefox/Zen, Chrome Web Store for
   Brave/Chrome/Chromium. Restart each browser.
4. Verify: `tabctl list --format json` returns the open tabs.

Snap-packaged browsers sandbox native messaging; if any target browser is a snap
build, its manifest must land in the snap's config dir. `.deb`/Flatpak browsers
are unaffected. This is an install concern, not a launcher concern.

The launcher assumes `tabctl` is on `PATH` and working. If it is missing or the
mediator is down, `tabctl list` returns nothing and the launcher shows a hint
row (see Error handling).

## tabctl interface used

- List: `tabctl list --format json` → array of objects:
  `{ "id": "firefox.1.2", "title": "...", "url": "...", "favIconUrl": "..." }`.
  `id` has the form `<browser>.<window_id>.<tab_id>`. `favIconUrl` may be empty.
- Activate: `tabctl activate <id>` — focuses the tab and switches desktop if
  needed.

No search command exists in tabctl; filtering is done client-side in the
launcher.

## Launcher changes (shell.qml only)

### Mode detection

- A read-only `tabMode` property is true when the input text is `tab` or starts
  with `tab ` (case-insensitive).
- A `query` property is the text after the `tab ` prefix in tab mode, otherwise
  the existing app search string.
- Backspacing the prefix returns to app mode. The existing Up/Down/Enter/Escape
  key handling is reused unchanged.

### Listing tabs

- A `Quickshell.Io` `Process` runs `tabctl list --format json` with a
  `StdioCollector` capturing stdout.
- On entering tab mode (and on re-entering), the process is started. When it
  finishes, stdout is `JSON.parse`d into a `tabs` property (array of
  `{id, title, url, favIconUrl}`).
- The displayed model is filtered client-side: tabs whose title or url contains
  `query` (case-insensitive substring). An empty query shows all tabs.
- The `ListView` model is `tabMode ? filteredTabs : apps`.

### Activating a tab

- On Enter or click in tab mode, a `Process` runs `tabctl activate <id>` for the
  selected tab's id, then the launcher calls `Qt.quit()`.
- tabctl focuses the tab and raises/switches to its window. No KWin raise is
  implemented in v1.
- Back-pocket fallback (not v1): if KWin focus-stealing-prevention leaves the
  window un-raised, add a KWin D-Bus script (`org.kde.KWin /Scripting`) that
  matches the window by caption and sets `workspace.activeWindow`.

### Tab row UI

- Icon: `Image` sourced from `favIconUrl`, falling back to a themed
  `web-browser` icon when `favIconUrl` is empty or fails to load.
- Primary text: tab title (elided).
- Secondary text: url, dimmed (elided).

### Error / empty handling

- If `tabctl list` yields no tabs (tool missing, mediator down, or genuinely no
  tabs), the list shows a single non-selectable hint row:
  "No tabs — is tabctl running?".

## Components and responsibilities

- `shell.qml`:
  - Mode logic (`tabMode`, `query`, model switching).
  - `Process` for listing tabs and parsing JSON.
  - `Process` for activating a tab.
  - Tab-row delegate and the hint row.
  - Reused keyboard handling and window/quit behavior.
- `tabctl` (external binary): all browser IPC (list and activate).

No shell script or helper file is needed; the launcher calls `tabctl` directly.

## Accepted limitations (v1)

- Depends on tabctl and its extensions being installed and running.
- Tab ids are ephemeral; the launcher always re-lists before acting, so this is
  fine.
- Edge is not supported by tabctl.
- No KWin raise backstop in v1.
- Snap browsers may need extra native-messaging setup.

## Testing

- With tabctl installed and tabs open in at least two browsers:
  - Type `tab` and confirm the list switches to browser tabs.
  - Type `tab git` and confirm filtering by title/url.
  - Select a tab and confirm the existing tab is focused (correct browser window
    comes forward), no new tab opens, and the launcher quits.
  - Backspace to remove the prefix and confirm app mode returns.
- With tabctl absent, confirm the hint row appears and app mode still works.

## Addendum (2026-10-12): implemented changes

Two things landed beyond the original v1 scope above.

### Tab window raise (was "back-pocket")

The original design deferred raising the browser window, assuming `tabctl
activate` would bring it forward. On KDE Plasma 6 Wayland it does not —
focus-stealing prevention keeps the window back. So the raise is now
implemented and shipped.

Tab activation runs the helper `activate-tab.sh <tabctl-id> <title>`:

1. `tabctl activate <id>` switches to the tab inside the browser.
2. After a short delay (for the window caption to update), a KWin script loaded
   over D-Bus (`org.kde.KWin /Scripting`) scans `workspace.windowList()` and
   activates the window whose `caption` contains the tab title.

`shell.qml` calls this script instead of `tabctl` directly; its `Process`
`onExited` quits the launcher.

### App mode: launch-or-raise

New behavior: selecting an app in app mode raises its existing window if the app
is already running, and only launches a new instance otherwise.

- Match key: `DesktopEntry.startupClass` (StartupWMClass) if present, else the
  desktop `id` (guarded with try/catch since not all builds expose
  `startupClass`).
- Helper `app-raise.sh <key>`:
  - Loads a KWin script that scans windows and matches `<key>` case-insensitively
    against `resourceClass` / `resourceName` (exact match first, then substring).
    If matched, it activates the window and `print`s a unique nonce plus
    `FOUND` / `NOTFOUND`.
  - bash reads that line from the user journal (`journalctl --user`, short retry
    loop) and exits `0` when a window was raised, `10` otherwise (also `10` if
    KWin is unreachable or the journal is unreadable, so the caller falls back to
    launching).
- `shell.qml` `launch()` runs `app-raise.sh` via a `Process`; in `onExited`, a
  non-zero exit code triggers `app.execute()` (native launch, preserving systemd
  scope and Exec field codes). Either way the launcher then quits.

Known limitations: depends on correct `StartupWMClass`/`id` (a few apps whose
window class differs will launch a new instance instead of raising — fixable with
a per-app key override); multi-window apps raise the first match; relies on KWin
journal readback (observed reliable on this system).

### Files (final)

- `shell.qml` — mode logic, tab list/activate, app launch-or-raise.
- `activate-tab.sh` — tab activate + KWin window raise.
- `app-raise.sh` — detect running app window + KWin raise; exit code signals
  whether the caller should launch.

The original "shell.qml only, no shell script" note is superseded: the KWin
scripting dance (temp-file load/run/stop over D-Bus, journal readback) is far
cleaner in bash than embedded in QML, so two small helper scripts live next to
`shell.qml`.

## Addendum (2026-10-13): kitty terminal tabs in `tab ` mode

`tab ` mode now searches kitty terminal tabs alongside browser tabs.

### Why only kitty

Ghostty (the user's previous primary terminal) has no external API to list or
switch tabs on Linux as of v1.3.x — tab actions are keybind-only, titles never
leave the app, and terminal tabs share one OS window so KWin can't see them.
tmux/zellij would work but the user runs neither. The user chose to adopt kitty,
whose remote-control protocol (`kitty @ ls` / `kitty @ focus-tab`) exposes tabs
cleanly. Terminal support is therefore kitty-only by design.

### Prerequisite (kitty.conf)

```
allow_remote_control yes
listen_on unix:/tmp/kitty
```

kitty appends `-<pid>` to the socket path, so the actual socket is
`/tmp/kitty-<pid>`. Run kitty single-instance (`kitty --single-instance`) so all
tabs/windows share one socket; multiple plain instances each create their own
socket and only the first-globbed one is reached.

### Listing

`list-tabs.sh` replaces the direct `tabctl list` call and emits one merged JSON
array of `{ id, title, url, favIconUrl, source }`, `source` ∈ {`browser`,
`kitty`}:

- Browser: `tabctl list --format json`, tagged `source:"browser"`.
- kitty: socket resolved by glob `/tmp/kitty-*` (first match); `kitty @ --to
  unix:<sock> ls` flattened over `.[].tabs[]` → `id` (stringified kitty tab id),
  `title` (tab title), `url` (focused window's cwd, fallback first window's cwd),
  empty `favIconUrl`, `source:"kitty"`.

Each source is queried independently; an unavailable source contributes `[]` and
never breaks the other. `shell.qml` runs `bash list-tabs.sh` in `tabLister`.

### Activation

`activate-tab.sh` now takes `<source> <id> [title]`:

- `browser` → `tabctl activate <id>`.
- `kitty` → `kitty @ --to unix:<sock> focus-tab --match id:<id>` (socket by glob).
- Then the shared KWin raise: match a window whose caption contains the title;
  for kitty, also fall back to a window whose `resourceClass` contains `kitty`.

`shell.qml` `activateTab()` passes `t.source`. kitty rows show a
`utilities-terminal` icon fallback instead of `web-browser`.

### Known limitation (kitty window raise)

Observed on this system: the kitty OS-window title does not track the active tab
title (custom title template in the user's kitty.conf), so the title match fails
and the `resourceClass=kitty` fallback does the raise. Consequences:

- Single kitty window: correct window raised.
- Multiple kitty OS windows: the fallback raises the first kitty window, which
  may not hold the target tab. Future fix: match the specific OS-window id from
  `kitty @ ls`, or set a tab-tracking window title in kitty.conf.

### Files (final, this addendum)

- `shell.qml` — tab list via `list-tabs.sh`; activate passes `source`; kitty icon.
- `list-tabs.sh` — merge browser (tabctl) + kitty (`kitty @ ls`) tabs.
- `activate-tab.sh` — source-dispatched activate + KWin raise.
- `app-raise.sh` — unchanged (app launch-or-raise).
- `kitty.conf` — remote control enabled (`allow_remote_control`, `listen_on`).

## Addendum (2026-10-13): power actions (Sleep / Shut Down / Restart / Log Out)

The launcher gains four power actions, reachable two ways: a button row pinned at
the bottom, and as selectable list rows when the input matches.

### Actions and backends (KDE Plasma 6)

| Action | Backend | Behavior |
|---|---|---|
| Sleep | `systemctl suspend` | Immediate (reversible). |
| Shut Down | `qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptShutDown` | KDE native confirm screen. |
| Restart | `qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptReboot` | KDE native confirm screen. |
| Log Out | `qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptLogout` | KDE native confirm screen. |

The user chose the confirm-screen variant (`org.kde.LogoutPrompt`) over immediate
execution (`org.kde.Shutdown`) so a mis-select is cancelable. Sleep has no prompt
variant and is harmless, so it runs immediately.

### UI and behavior

- `powerActions` is a list of `{ isPower, key, name, icon, keywords, cmd }`.
  Icons use themed names (`system-suspend`, `system-shutdown`, `system-reboot`,
  `system-log-out`).
- **Button row**: a `RowLayout` + `Repeater` at the bottom of the main
  `ColumnLayout`, always visible, one button per action (icon over label, hover
  highlight). Clicking calls `invokePower(modelData)`.
- **Typeable rows**: in app mode, `appMatches` prepends any `powerActions` whose
  `name` or a `keyword` contains the query, ahead of the matching apps. So typing
  `shut`, `reboot`, `logout`, `sleep`, etc. surfaces the action as a selectable
  list row (keyboard or click). Empty query shows apps only.
- `accept(i)` dispatches on the selected item: tab mode → `activateTab`; power
  item (`isPower`) → `invokePower`; otherwise → `launchApp`.
- `invokePower(action)` runs `action.cmd` via a `Process` (`powerProc`), then the
  launcher quits on exit.

### Refactor note

Because the app-mode list is now heterogeneous (power actions + apps), the old
`launch(i)` that indexed `apps[i]` was replaced by `launchApp(app)` taking the
resolved model item, avoiding an index mismatch between `appMatches` and `apps`.

### Files (final, this addendum)

- `shell.qml` — `powerActions`, `appMatches`, `accept()` dispatch, `invokePower()`
  + `powerProc`, bottom button `Repeater`; `launch(i)` → `launchApp(app)`.
