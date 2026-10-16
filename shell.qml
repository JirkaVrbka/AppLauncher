import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // Absolute paths to helpers, resolved next to this file.
    readonly property string activateScript: Qt.resolvedUrl("activate-tab.sh").toString().replace("file://", "")
    readonly property string raiseScript: Qt.resolvedUrl("app-raise.sh").toString().replace("file://", "")
    readonly property string listScript: Qt.resolvedUrl("list-tabs.sh").toString().replace("file://", "")
    readonly property string windowsScript: Qt.resolvedUrl("list-windows.sh").toString().replace("file://", "")
    readonly property string raiseWindowScript: Qt.resolvedUrl("raise-window.sh").toString().replace("file://", "")
    readonly property string notesScript: Qt.resolvedUrl("list-notes.sh").toString().replace("file://", "")

    // Scopes supported by the input pill.
    readonly property var knownScopes: ["tab", "open", "power", "new", "term", "note", "google"]

    // Active scope + query come from the input bar (single source of truth).
    readonly property string scope: scopeInput.scope
    readonly property bool tabMode: scope === "tab"
    readonly property bool powerMode: scope === "power"
    readonly property bool openMode: scope === "open"
    readonly property bool newMode: scope === "new"
    readonly property bool termMode: scope === "term"
    readonly property bool noteMode: scope === "note"
    readonly property bool googleMode: scope === "google"
    readonly property string query: scopeInput.text

    // Label shown in the input's mode chip.
    readonly property string modeLabel: tabMode ? "TAB"
        : termMode ? "TERM"
        : noteMode ? "NOTE"
        : googleMode ? "GOOGLE"
        : openMode ? "OPEN"
        : powerMode ? "POWER"
        : newMode ? "NEW"
        : commandMode ? "CMD"
        : "APPS"

    // Command mode: input begins with ":" (and no scope pill is active).
    readonly property bool commandMode: scope.length === 0 && query.startsWith(":")
    readonly property string commandQuery: commandMode ? query.slice(1) : ""

    // The query that the result list is actually filtered/highlighted by.
    readonly property string activeQuery: commandMode ? commandQuery : query

    // A query that is *only* a number is a 1-based position selector, not a
    // search term: the list stays unfiltered and that row is preselected (the
    // user still presses Enter to act). Works in every mode, e.g. "tab 3".
    readonly property bool posMode: /^\d+$/.test(activeQuery.trim())
    readonly property int posNumber: posMode ? parseInt(activeQuery.trim(), 10) : -1
    // Preselect from here, not from ScopeInput.queryEdited: that signal fires
    // before these bindings invalidate, so it would read a stale posMode. This
    // handler runs after posNumber settles, so the values are current.
    onPosNumberChanged: if (posMode) Qt.callLater(applyPreselect)
    readonly property string filterQuery: posMode ? "" : query
    readonly property string filterCommandQuery: posMode ? "" : commandQuery
    readonly property string highlightQuery: posMode ? "" : activeQuery

    // Preselect the row at the typed position. Deferred via Qt.callLater so it
    // runs after the model/list settle (reading the list's own fresh `count`,
    // not a binding that may still be stale mid-update).
    function applyPreselect() {
        if (!posMode || list.count === 0)
            return
        list.currentIndex = Math.max(0, Math.min(posNumber - 1, list.count - 1))
    }

    // ":" palette: the scopes, each entered on selection.
    readonly property var commands: [
        { isCommand: true, scope: "tab", key: "tab", name: "Tab Search", glyph: Icons.cmdTab, accent: Theme.green,
          keywords: ["tab", "tabs", "browser", "window"] },
        { isCommand: true, scope: "term", key: "term", name: "Terminal Tabs", glyph: Icons.terminal, accent: Theme.aqua,
          keywords: ["term", "terminal", "kitty", "shell", "console", "tty"] },
        { isCommand: true, scope: "open", key: "open", name: "Open Windows", glyph: Icons.cmdOpen, accent: Theme.blue,
          keywords: ["open", "running", "windows", "switch", "active"] },
        { isCommand: true, scope: "new", key: "new", name: "New Instance", glyph: Icons.cmdNew, accent: Theme.purple,
          keywords: ["new", "instance", "window", "launch", "another", "again", "fresh"] },
        { isCommand: true, scope: "power", key: "power", name: "Power", glyph: Icons.power, accent: Theme.red,
          keywords: ["power", "sleep", "lock", "shutdown", "restart", "logout"] },
        { isCommand: true, scope: "note", key: "note", name: "Obsidian Notes", glyph: Icons.note, accent: Theme.purple,
          keywords: ["note", "notes", "obsidian", "obs", "md", "markdown", "vault"] },
        { isCommand: true, scope: "google", key: "google", name: "Google Search", glyph: Icons.google, accent: Theme.blue,
          keywords: ["google", "search", "web", "www", "internet", "find", "browser"] }
    ]

    // A single synthetic result row for a Google search of `q` (used by the
    // google scope and as the always-last fallback in plain app search).
    function googleRow(q) {
        return { isGoogle: true, name: "Search Google for “" + q.trim() + "”",
                 glyph: Icons.google, accent: Theme.blue }
    }

    readonly property var commandMatches: {
        const q = filterCommandQuery.toLowerCase().trim()
        if (q.length === 0)
            return commands
        return commands.filter(c => c.key.includes(q) || c.name.toLowerCase().includes(q) || c.keywords.some(k => k.includes(q)))
    }

    // Power scope results: power actions filtered by the query.
    readonly property var powerMatches: {
        const q = filterQuery.toLowerCase().trim()
        if (q.length === 0)
            return PowerActions.list
        return PowerActions.list.filter(a => a.key.includes(q) || a.name.toLowerCase().includes(q) || a.keywords.some(k => k.includes(q)))
    }

    // Open windows [{id, class, title}], from list-windows.sh; refreshed when
    // entering the open scope.
    property var runningWindows: []

    // The desktop entry whose window class matches cls (same heuristic as
    // app-raise.sh), used to give a window a nice app name + icon.
    function appForClass(cls) {
        const c = (cls || "").toLowerCase()
        if (c.length === 0)
            return null
        const all = [...DesktopEntries.applications.values]
        let best = null
        for (const a of all) {
            const k = matchKey(a).toLowerCase()
            if (k.length === 0)
                continue
            if (k === c)
                return a
            if (!best && (c.indexOf(k) !== -1 || k.indexOf(c) !== -1))
                best = a
        }
        return best
    }

    // Open scope: one row per window, grouped by app (sorted), each with its
    // own title; filtered by the query over app name + title.
    readonly property var openMatches: {
        const items = runningWindows.map(w => {
            const app = appForClass(w.class)
            return {
                isOpenWindow: true,
                id: w.id,
                title: w.title,
                appName: app ? app.name : w.class,
                icon: app ? app.icon : "application-x-executable"
            }
        })
        items.sort((a, b) => a.appName.localeCompare(b.appName) || String(a.title).localeCompare(String(b.title)))
        const q = filterQuery.toLowerCase().trim()
        if (q.length === 0)
            return items
        return items.filter(it => (it.appName + " " + it.title).toLowerCase().includes(q))
    }

    // Google scope: a single synthetic row reflecting the query (raw, not
    // filterQuery, so a numeric query still searches). Empty when blank.
    readonly property var googleResults: {
        const q = query.trim()
        if (q.length === 0)
            return []
        return [googleRow(q)]
    }

    // The model shown in the list, by mode.
    readonly property var model: tabMode ? tabs
        : termMode ? terms
        : noteMode ? notes
        : googleMode ? googleResults
        : openMode ? openMatches
        : powerMode ? powerMatches
        : newMode ? apps
        : commandMode ? commandMatches
        : appMatches

    readonly property var apps: {
        const all = [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))

        if (filterQuery.length === 0)
            return all

        const q = filterQuery.toLowerCase()
        return all.filter(a => a.name.toLowerCase().includes(q))
    }

    // Extra built-in actions surfaced in plain app search (not power actions).
    readonly property var extraActions: [
        { isAction: true, key: "printscreen", name: "Print Screen", glyph: Icons.screenshot, accent: Theme.orange,
          keywords: ["print screen", "printscreen", "screenshot", "screen shot", "snip", "capture", "grab", "screen"],
          cmd: ["setsid", "-f", "spectacle"] }
    ]

    readonly property var extraMatches: {
        const q = filterQuery.toLowerCase().trim()
        if (q.length === 0)
            return []
        return extraActions.filter(a => a.name.toLowerCase().includes(q) || a.keywords.some(k => k.includes(q)))
    }

    // Plain app search also surfaces matching power actions + extra actions on top.
    // (With a non-empty query, powerMatches is already the filtered subset.)
    // Google search is always the last option once something is typed.
    readonly property var appMatches: {
        if (filterQuery.trim().length === 0)
            return apps
        return [...powerMatches, ...extraMatches, ...apps, googleRow(query)]
    }

    // Raw tab list from `list-tabs.sh`, refreshed when entering tab mode.
    property var allTabs: []

    readonly property var tabs: {
        if (filterQuery.length === 0)
            return allTabs

        const q = filterQuery.toLowerCase()
        return allTabs.filter(t => (t.title + " " + t.url).toLowerCase().includes(q))
    }

    // Term scope: the kitty terminal tabs only, filtered by the query.
    readonly property var terms: {
        const kitty = allTabs.filter(t => t.source === "kitty")
        if (filterQuery.length === 0)
            return kitty
        const q = filterQuery.toLowerCase()
        return kitty.filter(t => (t.title + " " + t.url).toLowerCase().includes(q))
    }

    // Raw note list [{title, file, vault}] from `list-notes.sh`, refreshed when
    // entering the note scope.
    property var allNotes: []

    // Note scope: Obsidian notes mapped onto app-row fields (name + comment +
    // line glyph); filtered by the query over title + vault-relative path.
    readonly property var notes: {
        const items = allNotes.map(n => ({
            name: n.title,
            comment: n.file,
            glyph: Icons.note,
            accent: Theme.purple,
            file: n.file,
            vault: n.vault
        }))
        if (filterQuery.length === 0)
            return items
        const q = filterQuery.toLowerCase()
        return items.filter(it => (it.name + " " + it.file).toLowerCase().includes(q))
    }

    // ---- actions ----

    function accept(i) {
        if (tabMode) {
            activateTabEntry(root.tabs[i])
            return
        }

        if (termMode) {
            activateTabEntry(root.terms[i])
            return
        }

        if (noteMode) {
            openNote(root.notes[i])
            return
        }

        if (googleMode) {
            openGoogle(root.query)
            return
        }

        if (openMode) {
            // Raise the exact window chosen.
            raiseWindow(root.openMatches[i])
            return
        }

        if (powerMode) {
            const action = root.powerMatches[i]
            if (action)
                runCommand(action)
            else
                Qt.quit()
            return
        }

        if (newMode) {
            // Always spawn a fresh instance (skip the raise-existing path).
            launchNew(root.apps[i])
            return
        }

        if (commandMode) {
            const cmd = root.commandMatches[i]
            if (cmd)
                enterScope(cmd.scope)
            else
                Qt.quit()
            return
        }

        const item = root.appMatches[i]
        if (!item) {
            Qt.quit()
            return
        }
        if (item.isGoogle)
            openGoogle(root.query)
        else if (item.isPower || item.isAction)
            runCommand(item)
        else
            launchApp(item)
    }

    // Switch into a scope (pill + its list). Called from the ":" palette.
    function enterScope(s) {
        scopeInput.text = ""
        scopeInput.scope = s
        if ((s === "tab" || s === "term") && !tabLister.running)
            tabLister.running = true
        else if (s === "open" && !windowsLister.running)
            windowsLister.running = true
        else if (s === "note" && !notesLister.running)
            notesLister.running = true
    }

    function runCommand(action) {
        powerProc.command = action.cmd
        powerProc.running = true
    }

    // Open an Obsidian note via its URI handler. xdg-open routes obsidian:// to
    // Obsidian (launching it if closed); setsid -f detaches the GUI, matching
    // the Spectacle launch idiom. Afterwards we raise Obsidian's window (see
    // noteProc.onExited) — xdg-open alone only switches the note in the
    // background instance, which KWin won't bring to front on its own.
    function openNote(n) {
        if (!n) {
            Qt.quit()
            return
        }
        const uri = "obsidian://open?vault=" + encodeURIComponent(n.vault)
            + "&file=" + encodeURIComponent(n.file)
        noteProc.command = ["setsid", "-f", "xdg-open", uri]
        noteProc.running = true
    }

    // Open a Google search for the query in the default browser. xdg-open routes
    // the https URL to the default browser (launching it if closed); setsid -f
    // detaches, matching the note/Spectacle idiom. A browser focuses itself, so
    // no window-raise follow-up is needed.
    function openGoogle(q) {
        const query = (q || "").trim()
        if (query.length === 0) {
            Qt.quit()
            return
        }
        const url = "https://www.google.com/search?q=" + encodeURIComponent(query)
        googleProc.command = ["setsid", "-f", "xdg-open", url]
        googleProc.running = true
    }

    function raiseWindow(win) {
        if (!win) {
            Qt.quit()
            return
        }
        // Detached: raise-window.sh waits for this overlay to close, then
        // activates — otherwise KWin's focus-restore on close wins.
        winRaiser.command = ["setsid", "-f", "bash", root.raiseWindowScript, win.id]
        winRaiser.running = true
    }

    Process {
        id: winRaiser
        onExited: Qt.quit()
    }

    // Window-match key for an app: StartupWMClass if present, else desktop id.
    function matchKey(app) {
        let k = ""
        try {
            if (app.startupClass)
                k = app.startupClass
        } catch (e) {}
        if (!k)
            k = app.id || app.name || ""
        return k
    }

    property var pendingApp: null

    function launchApp(app) {
        if (!app) {
            Qt.quit()
            return
        }

        // Try to raise an existing window; if none, the Process exits 10 and we
        // launch a new instance in onExited.
        root.pendingApp = app
        appRaiser.command = ["bash", root.raiseScript, root.matchKey(app)]
        appRaiser.running = true
    }

    // Launch a new instance directly, without trying to raise an existing
    // window. Single-instance apps may still just focus — that's their call.
    function launchNew(app) {
        if (!app) {
            Qt.quit()
            return
        }
        app.execute()
        Qt.quit()
    }

    function activateTabEntry(t) {
        if (!t) {
            Qt.quit()
            return
        }

        // Detached: the raise inside activate-tab.sh must run AFTER this overlay
        // closes, or KWin's focus-restore on close overrides the activation.
        tabActivator.command = ["setsid", "-f", "bash", root.activateScript, t.source ?? "browser", t.id, t.title ?? "", t.socket ?? ""]
        tabActivator.running = true
    }

    // ---- processes ----

    Process {
        id: powerProc
        onExited: Qt.quit()
    }

    Process {
        id: noteProc
        onExited: noteRaiser.running = true
    }

    Process {
        id: googleProc
        onExited: googleRaiser.running = true
    }

    // Bring the default browser to the front after the search opens. xdg-open
    // opens the URL in a background browser instance, which KWin won't raise on
    // its own (same issue as notes). We resolve the default browser's desktop id
    // via xdg-settings, strip ".desktop", and feed it to app-raise.sh as a
    // window-class match key (substring, case-insensitive). Detached + delayed so
    // it runs AFTER this overlay closes — otherwise KWin's focus-restore on close
    // wins. If the browser was not running, its fresh window focuses itself and
    // the raise is a harmless no-op.
    Process {
        id: googleRaiser
        command: ["setsid", "-f", "sh", "-c",
            "sleep 0.4; b=$(xdg-settings get default-web-browser 2>/dev/null); b=${b%.desktop}; [ -n \"$b\" ] && exec bash \"$1\" \"$b\"",
            "sh", root.raiseScript]
        onExited: Qt.quit()
    }

    // Bring Obsidian to the front after the note is opened. "obsidian"
    // substring-matches its window class (e.g. md.obsidian.Obsidian) in
    // app-raise.sh; if it is not running yet the raise is a harmless no-op and
    // the freshly launched window focuses itself. Detached + delayed so it runs
    // AFTER this overlay closes — otherwise KWin's focus-restore on close
    // overrides the activation. Positional args avoid any quoting issues.
    Process {
        id: noteRaiser
        command: ["setsid", "-f", "sh", "-c", "sleep 0.3; exec bash \"$1\" obsidian", "sh", root.raiseScript]
        onExited: Qt.quit()
    }

    Process {
        id: notesLister
        command: ["bash", root.notesScript]
        stdout: StdioCollector {
            id: notesListerOut
            onStreamFinished: {
                try {
                    root.allNotes = JSON.parse(notesListerOut.text)
                } catch (e) {
                    root.allNotes = []
                }
            }
        }
    }

    Process {
        id: appRaiser
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.pendingApp)
                root.pendingApp.execute()
            Qt.quit()
        }
    }

    Process {
        id: tabLister
        command: ["bash", root.listScript]
        stdout: StdioCollector {
            id: tabListerOut
            onStreamFinished: {
                try {
                    root.allTabs = JSON.parse(tabListerOut.text)
                } catch (e) {
                    root.allTabs = []
                }
            }
        }
    }

    Process {
        id: tabActivator
        onExited: Qt.quit()
    }

    Process {
        id: windowsLister
        command: ["bash", root.windowsScript]
        stdout: StdioCollector {
            id: windowsListerOut
            onStreamFinished: {
                try {
                    root.runningWindows = JSON.parse(windowsListerOut.text)
                } catch (e) {
                    root.runningWindows = []
                }
            }
        }
    }

    // ---- window ----

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Frosted dim scrim over the desktop (soft translucent gradient for depth).
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.11, 0.13, 0.14, 0.60) }
            GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.08, 0.09, 0.72) }
        }
    }

    // Top bar: media/layout (left), clock/workspaces (center), volume/battery/
    // bluetooth/wifi (right). Script-polled bits come via `topInfo`.
    property var topInfo: ({ layout: "", wsCount: 1, wsActive: 0 })

    Process {
        id: infoProc
        running: true
        command: ["bash", Qt.resolvedUrl("topinfo.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            id: infoOut
            onStreamFinished: {
                try {
                    root.topInfo = JSON.parse(infoOut.text)
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!infoProc.running) infoProc.running = true
    }

    Process {
        id: layoutSwitch
        command: ["gdbus", "call", "--session", "--dest", "org.kde.keyboard",
                  "--object-path", "/Layouts", "--method", "org.kde.KeyboardLayouts.switchToNextLayout"]
        onExited: infoProc.running = true   // refresh the pill
    }

    // The top bar — and its Bluetooth/Pipewire/UPower/Mpris service pills — isn't
    // needed to start typing, so load it asynchronously: the first frame is just
    // the scrim + search panel (focused, typeable) and the bar appears a moment
    // later. Loading by URL (not an inline component) keeps TopBar.qml and the
    // pill files it pulls in — MediaPill, VolumeControl, BluetoothPill, WifiVpnPill
    // and their service imports — off shell.qml's own compile path; `asynchronous`
    // then builds that subtree without blocking the first frame. Wired in onLoaded.
    Loader {
        id: topBarLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 20
        asynchronous: true
        source: "TopBar.qml"
        onLoaded: {
            item.info = Qt.binding(() => root.topInfo)
            item.layoutClicked.connect(() => { if (!layoutSwitch.running) layoutSwitch.running = true })
        }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 576
        height: 520
        radius: 20
        color: Theme.bg
        border {
            color: Theme.bg2
            width: 1
        }
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            ScopeInput {
                id: scopeInput
                Layout.fillWidth: true
                knownScopes: root.knownScopes
                matchCount: root.model.length
                mode: root.modeLabel

                onQueryEdited: {
                    list.currentIndex = 0
                    if ((root.tabMode || root.termMode) && !tabLister.running)
                        tabLister.running = true
                }
                onScopeEntered: scope => {
                    if ((scope === "tab" || scope === "term") && !tabLister.running)
                        tabLister.running = true
                    else if (scope === "open" && !windowsLister.running)
                        windowsLister.running = true
                    else if (scope === "note" && !notesLister.running)
                        notesLister.running = true
                }
                onEscaped: Qt.quit()
                onAccepted: root.accept(list.currentIndex)
                onNavDown: if (list.count > 0) list.currentIndex = (list.currentIndex + 1) % list.count
                // Wrap around: Up on the first item jumps to the last.
                onNavUp: if (list.count > 0) list.currentIndex = (list.currentIndex - 1 + list.count) % list.count
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.model
                currentIndex: 0
                topMargin: 2
                bottomMargin: 2

                // Re-apply the positional preselect when the list arrives
                // asynchronously (e.g. "tab 3" typed before tabs finish loading).
                onCountChanged: if (root.posMode) Qt.callLater(root.applyPreselect)

                // Selection: a soft green wash + an inset green left bar.
                highlight: Rectangle {
                    radius: 12
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15) }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.03) }
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: parent.height - 14
                        radius: 1
                        color: Theme.green
                    }
                }
                highlightMoveDuration: 90
                highlightResizeDuration: 0

                Text {
                    anchors.centerIn: parent
                    visible: root.model.length === 0 && (root.tabMode || root.termMode || root.openMode || root.noteMode)
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 14
                    text: root.tabMode ? "no tabs — is tabctl running?"
                        : root.termMode ? "no kitty tabs — is kitty running?"
                        : root.noteMode ? "no notes — vault found in obsidian.json?"
                        : "no running apps"
                }

                delegate: ResultRow {
                    tabMode: root.tabMode || root.termMode
                    openMode: root.openMode
                    commandMode: root.commandMode
                    query: root.highlightQuery
                    onClicked: root.accept(index)
                }
            }

            StatusBar {
                Layout.fillWidth: true
                actions: PowerActions.list
                onInvoked: action => root.runCommand(action)
            }
        }
    }
}
