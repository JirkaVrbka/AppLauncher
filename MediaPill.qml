import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// Media pill + flyout listing every MPRIS player: app art + track + transport
// controls, with the active player highlighted and a progress line. Pure Mpris.
Item {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var active: {
        for (const p of players)
            if (p.isPlaying)
                return p
        return players.length > 0 ? players[0] : null
    }
    readonly property bool open: fp.open

    visible: players.length > 0
    implicitWidth: fp.implicitWidth
    implicitHeight: fp.implicitHeight

    function mediaText(p) {
        if (!p)
            return ""
        const a = (p.trackArtist || "").trim()
        const t = (p.trackTitle || "").trim()
        return a.length > 0 && t.length > 0 ? (a + " — " + t) : (t || a || p.identity)
    }

    // Live progress tick for the active player while the flyout is open.
    property real tick: 0
    Timer { interval: 1000; running: root.open; repeat: true; onTriggered: root.tick = Date.now() }

    FlyoutPill {
        id: fp
        side: Qt.AlignLeft
        panelWidth: 320
        maxLabelWidth: 220
        glyph: (root.active && root.active.isPlaying) ? Icons.mediaPause : Icons.mediaPlay
        glyphFilled: true
        accent: Theme.fg
        label: root.mediaText(root.active)
        onPillTapped: if (root.active && root.active.canTogglePlaying) root.active.togglePlaying()

        FlyoutHeader { text: "players"; topMargin: 5 }

        Repeater {
            model: root.players
            FlyoutRow {
                id: prow
                required property var modelData
                readonly property bool isActive: modelData === root.active
                rowHeight: 48
                active: isActive
                progress: (isActive && modelData.length > 0)
                    ? (root.tick, modelData.position / modelData.length) : -1
                onActivated: if (modelData.canTogglePlaying) modelData.togglePlaying()

                // app / album art
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 7
                    color: Theme.bg2
                    clip: true
                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: Quickshell.iconPath(modelData.desktopEntry, "audio-x-generic")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: (modelData.trackTitle && modelData.trackTitle.length > 0)
                            ? modelData.trackTitle : root.mediaText(modelData)
                        color: Theme.fg
                        font.family: Theme.mono
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        Text {
                            text: modelData.identity
                            color: Theme.grey
                            font.family: Theme.mono
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.maximumWidth: 120
                        }
                        Text {
                            visible: (modelData.trackArtist || "").length > 0
                            text: "· " + modelData.trackArtist
                            color: Theme.grey
                            font.family: Theme.mono
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.isPlaying ? "playing" : "paused"
                            color: modelData.isPlaying ? Theme.green : Theme.grey
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    spacing: 2
                    MediaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Icons.skipPrev
                        enabled: modelData.canGoPrevious
                        onTapped: modelData.previous()
                    }
                    MediaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: modelData.isPlaying ? Icons.mediaPause : Icons.mediaPlay
                        enabled: modelData.canTogglePlaying
                        tint: prow.isActive ? Theme.green : Theme.fg
                        onTapped: modelData.togglePlaying()
                    }
                    MediaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Icons.skipNext
                        enabled: modelData.canGoNext
                        onTapped: modelData.next()
                    }
                }
            }
        }
    }
}
