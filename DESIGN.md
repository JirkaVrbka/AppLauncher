# Launcher Design System — Everforest

The visual language for the quickshell launcher. Any new view, widget, or state
must follow this so the UI stays unified. Values here are the source of truth;
they live as `readonly property` tokens in the **`Theme` singleton**
(`Theme.qml`) — reference `Theme.bg`, `Theme.green`, `Theme.mono`, … never a raw
hex.

### File structure

The launcher is split into singletons + components so the design is reusable:

- `Theme.qml` *(singleton)* — color tokens, `mono` font, `hl()`/`escapeHtml()`.
- `PowerActions.qml` *(singleton)* — the power-action data list.
- `ScopeInput.qml` — the search capsule (mode chip, field, count chip); owns
  scope entry/exit, emits navigation/submit signals.
- `ResultRow.qml` — one pill-style result row; the `ListView` delegate.
- `StatusBar.qml` — the bottom command bar: hint + round power-action icon
  buttons; emits `invoked(action)`.
- `ClockPill.qml` — `HH:mm` capsule (used in the top bar center).
- `VolumeControl.qml` — volume pill + a hover flyout (same style as the other
  pills): a **horizontal** volume slider + mute, and an output-device switcher
  listing `Pipewire` sinks. Click the pill to mute; writes
  `sink.audio.volume`/`muted` and `Pipewire.preferredDefaultAudioSink`.
- `Pill.qml` — rounded dark capsule (`Theme.bgDark`) with a tinted `glyph`
  (`Icons.*` path drawn by `Icon.qml`, recolored to `accent`) + light mono label.
  Used by the simple bar pills (clock, keyboard, battery); the interactive
  hover-flyout pills use `FlyoutPill` instead.
- `Icons.qml` *(singleton)* — SVG path data (24×24) for every line/solid glyph,
  lifted from the mockups. Single source of truth for icon shapes.
- `Icon.qml` — draws one `Icons.*` path via `QtQuick.Shapes`, recolorable
  (`color`), sizable (`size`), stroked or `filled`.
- `FlyoutPill.qml` — the capsule + hover-flyout shell every interactive pill is
  built on: the glyph/label capsule (+ optional `trailing`), the behind
  hover-zone, and the dropdown surface (fade+slide reveal) whose body is the
  component's default content. `side` aligns it left or right. See §4.
- `FlyoutRow.qml` — one flyout row (hover+tap, optional `active` fill and bottom
  `progress` line). `FlyoutHeader.qml` / `FlyoutDivider.qml` — section label /
  1px separator. `FlyoutToggle.qml` — the small pill toggle.
- `SignalBars.qml` — four ascending wifi-strength bars (`level` 0–4).
- `MediaButton.qml` — transparent prev/play/next control for the media flyout.
- `BluetoothPill.qml` — bluetooth pill + devices flyout (multi-connect, scan).
- `WifiVpnPill.qml` — wifi pill + networks/VPN flyout (data via `netinfo.sh`).
- `MediaPill.qml` — media pill + players flyout (all `Mpris` players).
- `TopBar.qml` — full-width top bar: media + keyboard layout (left), clock +
  workspaces (center), volume + battery + bluetooth + wifi (right). Live data
  from Quickshell services (`Mpris`, `Pipewire`, `UPower`, `Bluetooth`);
  layout/workspaces/wifi come from `topinfo.sh` (gdbus + nmcli), polled into
  `root.topInfo` every 2s.
- `shell.qml` — controller: state (apps/tabs/query/scope), filtering, the
  activate/launch/raise/power processes, and composition of the above.

Theme: **Everforest (dark, soft)** — a warm, low-contrast, cosy editor look.
Layout metaphor: a **fuzzy-finder / command palette** — one text box that is both
a search field and a command line.

---

## 1. Color tokens

Mirrored in `shell.qml` as `cBg`, `cBg1`, … Use the token name in code.

| Token | Hex | Role |
|-------|-----|------|
| `bgDark` | `#232a2e` | Darker surface — top-bar pills |
| `cBg` | `#2d353b` | Panel background (the main surface) |
| `cBg1` | `#343f44` | Raised bars: input bar, status bar |
| `cBg2` | `#3d484d` | Selection fill, borders, divider lines |
| `cBg3` | `#475258` | Faint elements: inactive line numbers |
| `cFg` | `#d3c6aa` | Primary text (names, input) |
| `cGrey` | `#859289` | Secondary text: paths, urls, counts, placeholder |
| `cGreen` | `#a7c080` | Primary accent: prompt, active line number, mode chip, browser tag |
| `cOrange` | `#e69875` | Match highlight (the typed substring) |
| `cBlue` | `#7fbbb3` | Command links (`:sleep`, `:restart`, `:logout`) |
| `cRed` | `#e67e80` | Destructive accent (`:shutdown`, errors) |
| `cAqua` | `#83c092` | Terminal / kitty source tag |
| `purple` | `#d699b6` | Top-bar accent (clock, wifi) |

Scrim over the desktop: `Qt.rgba(0.09, 0.11, 0.12, 0.55)` — soft, slightly warm.

**Rules**
- Accents are used sparingly on a dominant `cBg`/`cBg1` field. Do not tint large
  areas with accent colors.
- Only one thing is green-accented per row (the active line number). The matched
  substring is the only orange on screen.
- Destructive actions are always `cRed` and never share styling with safe ones.

---

## 2. Typography

- **One typeface: `Hack`** (monospace), referenced via the `mono` token. The
  whole UI is monospaced — this is the "programming, cosy" signature. Do not
  introduce a second family.
- If `Hack` is ever unavailable, swap the `mono` token to another installed mono
  (e.g. `IBM Plex Mono`, `DejaVu Sans Mono`); never fall back to a sans/system UI
  font.

| Use | Size (px) | Color | Weight |
|-----|-----------|-------|--------|
| Prompt `❯` | 18 | `cGreen` | bold |
| Input text | 16 | `cFg` | regular |
| Match count | 13 | `cGrey` | regular |
| Row — name | 14 | `cFg` (match = `cOrange` bold) | regular |
| Row — subtitle (path/url) | 11 | `cGrey` | regular |
| Row — line number | 12 | `cBg3` / `cGreen` (active) | regular |
| Row — source tag | 11 | `cGreen` / `cAqua` | regular |
| Mode chip | 11 | `cBg` on `cGreen` | bold |
| Command links | 13 | `cBlue` / `cRed` | regular |
| Empty / hint text | 14 | `cGrey` | regular |

Match highlighting is produced by `root.hl(text)` (Text `textFormat:
StyledText`), which bolds + colors the typed substring in `cOrange`. Reuse this
helper anywhere a query is reflected in a label.

---

## 3. Layout & spacing

The panel is **pill-styled**, echoing the top-bar pills + hover cards: a padded
`cBg` card holding a dark search capsule, the result list, and a command bar —
not edge-to-edge bars.

- **Panel**: 576 × 520 px, `radius: 20`, `color: cBg`, `border: cBg2 / 1px`,
  `clip: true`, centered. Full-screen dim scrim behind it.
- **Vertical structure** (a `ColumnLayout`, `anchors.margins: 14`, `spacing: 12`):
  search capsule → results list → command bar. Everything is inset from the
  rounded panel edge by the 14px margin; nothing is full-bleed.
- **Search capsule**: a `cBgDark` pill, height 54, `radius: 15`, inner margins
  16/14, element spacing 12.
- **Command bar**: height 46, a 1px `cBg2` divider along its top edge, hint text
  left + round icon buttons right.
- **Row**: height 48, left/right margin 14, element spacing 13, `radius: 12`.
  Number gutter is a fixed 18px right-aligned column. Icons are 22px.
- List padding: `topMargin`/`bottomMargin` 2.

---

## 4. Components

### Search capsule (input)
The whole input is one `cBgDark` capsule (`ScopeInput.qml`): a **mode chip** on
the left, a transparent `TextField` (mono, `cFg`, placeholder `cGrey`, selection
`cGreen`, selected text `cBgDark`) that fills the middle, and a right-aligned
**count chip** showing the match number. The input is the only focused element.

### Mode chip
A fully-rounded `cGreen` pill with `cBgDark` bold mono text (12px) at the left of
the capsule. It shows the active mode — `APPS` normally, or the scope name when
one is active (`TAB` / `TERM` / `OPEN` / `POWER` / `NEW` / `CMD`). It replaces
the old separate scope pill + status mode chip (one indicator, driven by
`root.modeLabel`). The count chip on the right is a small `cBg2` pill.

Scopes are generic (`ScopeInput.scope` string; known scopes in
`root.knownScopes`). Current scopes: **`tab`** (open browser/kitty tabs),
**`open`** (open windows — one row per window from `list-windows.sh`'s KWin
query, grouped by app and sorted, each showing the app name + that window's
current title; selecting raises that exact window by its KWin internalId via
`raise-window.sh`), **`power`**
(power actions), **`new`** (applications only — selecting one always spawns a
fresh instance via `DesktopEntry.execute()`, skipping the raise-existing path
that plain app search uses), **`term`** (the `tab` list filtered to kitty
terminal tabs only — `source === "kitty"` — activated the same way as `tab`), and
**`google`** (a single synthetic row for the typed query; Enter opens a Google
search — `https://www.google.com/search?q=` + `encodeURIComponent(query)` — in the
default browser via `setsid -f xdg-open`, no lister, accent `cBlue`).
Interaction contract, identical for every scope:
- Typing the scope keyword followed by a space (`tab `, `power `) swallows that
  prefix into the mode chip and sets `scope`; the query that follows is "clean".
- **Backspace on an empty query clears the scope** (mode chip returns to `APPS`).
- The placeholder adapts to the active scope.
- A scope can also be entered from the `:` command palette.
- **A query that is only digits is a 1-based position selector**, not a search
  term: the list stays unfiltered and that row is preselected (Enter still
  acts). Works in every mode — e.g. `tab 3` preselects the third tab, `:2` the
  second command. Driven by `root.posMode`/`posNumber`, which blank the filter
  query (`filterQuery`) and preselect the row via `applyPreselect()` (deferred
  with `Qt.callLater` so it reads the list's fresh `count` after async loads).

New scopes just add their keyword to `knownScopes`, a result source, and an
`accept` branch — the pill, prefix entry, and empty-backspace exit come for free.

### Result row
`[number] [icon] [name / subtitle] [trailing pill]`

- **Number gutter**: the row's 1-based position (18px, `cBg3`, turning `cGreen`
  on the selected row) — also the target of the type-a-number position selector.
- **Icon**: app/power/command → themed `IconImage` via `Quickshell.iconPath(icon,
  fallback)` (real app icons); tab → favicon `Image` from `favIconUrl`, falling
  back to `utilities-terminal` (kitty) or `web-browser` (browser).
- **Name**: `root.hl(...)` with the matched substring highlighted.
- **Subtitle**: app `comment` or tab `url`, hidden when empty.
- **Trailing pill**: a `cBgDark` capsule — tab/term source (`cGreen` browser /
  `cAqua` kitty), or in command mode the keyword (`:tab`, `cBlue`). None for
  plain app rows.

### Item icons — apps vs. non-app items
Two icon sources, chosen per item by `ResultRow`:

- **Apps** (real `DesktopEntry` objects) use their **real themed icon** —
  `IconImage` via `Quickshell.iconPath(modelData.icon, "application-x-executable")`.
  Do **not** give apps a glyph; the system icon is always better.
- **Non-app items** (the `:` commands/scopes, power actions, built-in actions —
  anything that is a plain JS object, not a `DesktopEntry`) use a **line glyph**
  from the `Icons` singleton, tinted to an accent, drawn by `Icon.qml`.

`ResultRow` prefers a glyph when the item has one: if `modelData.glyph` is set it
renders `Icon { path: modelData.glyph; color: modelData.accent }` (22px); else it
falls back to the themed `IconImage`. Tabs are the exception (favicon `Image`).

**To add a new non-app item** (a command, action, future entry), give its object:
```js
{ …, glyph: Icons.cmdTab, accent: Theme.blue }   // glyph = an Icons.* path, accent = a Theme color
```
and nothing else is needed — the row picks it up. **To add a new glyph**, add a
`readonly property string` to `Icons.qml` holding a 24×24 SVG path (sharp rects
are fine, round caps/joins soften them; see `cmdTab`/`terminal`/`cmdOpen`), and
reference it as `Icons.<name>`. This is the same glyph system the top-bar pills
and flyouts use, so the whole UI stays unified. Current command accents: `tab`
green, `term` aqua, `open` blue, `new` purple, `power` red, `google` blue (globe
glyph); power actions are `cBlue` (shutdown `cRed`); Print Screen is `cOrange`.
Plain app search also appends a `google` row (blue globe) as the always-last
fallback once any text is typed.

### Selection
A soft **green wash** (`cGreen` at 15%→3% horizontal gradient) with an inset 2px
`cGreen` left bar, `radius: 12`, drawn by the ListView highlight behind the row
(90ms glide, `highlightMoveDuration: 90`, no resize animation). The active row's
number turns `cGreen`. Hover fills a non-selected row with `cBg1` (color only).

### Command bar
The bottom bar (`StatusBar.qml`): a left-aligned `cGrey` hint
(`type a number to jump · ↩ launch`) and, on the right, a `Repeater` of round
**icon buttons** for the power actions — a `cBgDark` circle (hover `cBg1`) with a
tinted `Icon` glyph each (`moon` sleep, `lock`, `power` shutdown = `cRed`,
`restart`, `logout`); default tint `cBlue`, hover `cFg`. Each click emits
`invoked(action)`; the actions are still reachable via the `:power` scope, the
`:power` command, and plain app search.

### Command mode (`:`)
Typing `:` (when no scope is active) opens a command palette listing the
**scopes** — `tab`, `open`, `power`, `new`, and `term` — filtered by the text after `:`.
Selecting one enters that scope (clears input, updates the mode chip). The mode
chip reads `CMD`.
Commands render with the standard result row (themed icon + name), highlighted
against the post-`:` query.

### Power actions
The power actions (`sleep`, `lock`, `shutdown`, `restart`, `logout`) live in the
`PowerActions` singleton and are reached four ways: the **`power` scope**
(pick one), the `:power` command, the **bottom command-bar icon buttons** (always
visible), and **plain app search** — a matching power action is prepended above
the app results when you type its name/keyword. Shut Down / Restart / Log Out go
through KDE's confirm screen; Sleep and Lock act immediately.

### Built-in actions
Beyond power, `root.extraActions` holds utility actions surfaced in plain app
search by name/keyword (prepended above apps, like power actions). Currently:
**Print Screen** → launches the system screenshot tool (`setsid -f spectacle`,
detached so the launcher can close). Both power and extra actions carry a `cmd`
and are run via `runCommand()` (fire the command, then quit).

### Empty / error state
Centered `cGrey` mono line (e.g. `no tabs — is tabctl running?`). Lowercase,
terse, no punctuation drama.

### Top-bar pills
`Pill.qml` — a fully-rounded (`radius: height/2`) `bgDark` capsule, height 30,
holding a **tinted 15px icon** (recolored to the pill's `accent` via
`MultiEffect`) + a 13px `mono` label (`labelColor`, default `cFg`). One accent
per pill: media = `cFg`, keyboard = `cOrange`, clock/workspaces/wifi = `purple`,
battery = `cGreen`/`cAqua`/`cRed`, bluetooth = `cBlue`. Pills sit in `TopBar.qml`
(left / center / right rows, 10px gaps). Use `reserve` to fix a label's width so
a changing value (e.g. `muted`/`100%`) does not shift the pill.

Small in-pill adornments:
- **Count badge** — a `cBlue` chip (`bgDark` text, 11px, `radius: height/2`) after
  the label when a pill represents several items (e.g. bluetooth: N connected).
- **Accent wash tag** — a sub-pill using a 16%-alpha accent fill
  (`rgba(167,192,128,.16)` for green) + accent text, for an inline status flag
  (e.g. a `vpn` tag inside the wifi pill when a VPN is up). This is the only
  place an accent tints a fill; keep it tiny.

### Hover flyouts (top-bar)
Pattern established by `VolumeControl.qml`: hovering a top-bar pill opens a
panel directly beneath it. Shared spec for every flyout:
- Surface: `bgDark`, `border: cBg2 / 1px`, `radius: 12`, inner padding 6, dropped
  5px below the pill, aligned to the pill's nearest screen edge (left pills open
  left-aligned, right pills right-aligned). Soft shadow only (no glow/border
  accent). Stay-open hover zone spans pill + gap + panel so there is no dead zone.
- **Section header**: `cGrey` 11px lowercase (`networks`, `vpn`, `players`,
  `connected`, `paired`); optional right-aligned on/off control.
- **Row**: height ~34, padding `8px 10px`, `radius: 9`, 11px gap; hover =
  `cBg1` fill (color only). Leading 16px line-icon in `cGrey`, promoted to the
  pill's accent when that row is the active/connected one. Name 13px `cFg`
  (inactive = `cGrey`), optional 11px `cGrey` subtitle. Trailing meta: the accent
  for connected state (dot / check / battery%), or a `cGrey` verb (`connect`,
  `join`) that brightens to `cFg` on hover.
- **Toggle**: 26×15 track, `bg3` off / accent on, `bgDark` knob — for VPN
  profiles and the master on/off.
- **Divider**: 1px `cBg2`, 5px vertical margin, between sections.

The four live flyouts (mockups in `mockups/pill-*.html`):
- **Sound** — a **horizontal** volume slider (track + fill + knob) + a `mute`
  control in the header, then an `output` section listing sinks (active one
  blue-checked, tap to switch). The one flyout that is not a plain row list.
- **Bluetooth** — lists all devices; `connected` section supports **multiple**
  connected devices (each with battery% + `cBlue` dot), then `paired` (connect),
  then a `scanning…` line. Pill shows the primary device + a count badge.
- **Wi-Fi + VPN** — `networks` section (connected network has signal bars +
  `cGreen`/`purple` check + `secured` lock glyph; others show signal + `join`),
  then a divider and a `vpn` section of profiles (active one toggled on in
  `cGreen`). Pill carries the green `vpn` wash-tag while a VPN is connected.
- **Media** — `players` section, one row per MPRIS player (app art + track +
  `playing`/`paused` state + prev/play-pause/next controls); the playing one is
  `cBg1`-filled with a 2px `cGreen` progress line.

---

## 5. Motion

Restrained. Only the selection glide (90ms) animates. No row fades, no entrance
animations, no hover scaling. The cosy feel comes from color and spacing, not
movement. Hover changes color only — **except** a top-bar hover flyout, which may
use one short reveal (≤120ms fade + small downward slide) as it opens, matching
the volume slider's appearance. Rows inside the flyout still only change color.

---

## 6. Voice

Lowercase, terse, developer-flavoured. Prompts and hints read like a shell
(`search apps…`, `no tabs — is tabctl running?`, `:shutdown`). Avoid sentence
case, exclamation marks, and marketing tone.

---

## 7. Adding new UI — checklist

1. Use `mono` for every text element; pick a size from §2.
2. Use color **tokens**, never raw hex. New role? add a token, document it here.
3. Surfaces: `cBg` for the field, `cBg1` for raised bars, `cBg2` for
   selection/dividers.
4. One accent per element; destructive = `cRed`, primary = `cGreen`.
5. Reflect any typed query with `root.hl()`.
6. Match the spacing scale in §3 (margins 16–18, row height 46, icons 22).
7. Keep motion to the selection glide; hover = color change only.
8. Keep copy lowercase and terse (§6).

If a change needs values not covered here, add them to this document in the same
turn — this file and the `Theme` singleton's tokens must never drift apart.
