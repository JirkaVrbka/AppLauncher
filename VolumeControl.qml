import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Volume pill + flyout (same style as the other pills): a horizontal volume
// slider + mute, and an output-device switcher (Pipewire sinks). Click the pill
// to mute.
Item {
    id: root

    property var sink
    property int volPct: 0
    property bool muted: false

    readonly property real level: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool open: fp.open

    implicitWidth: fp.implicitWidth
    implicitHeight: fp.implicitHeight

    // Output devices (real sinks, not per-stream nodes).
    readonly property var sinks: Pipewire.nodes
        ? Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
        : []

    // Keep the default sink's audio properties populated.
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    function setVolume(v) {
        if (!sink || !sink.audio)
            return
        const c = Math.max(0, Math.min(1, v))
        sink.audio.volume = c
        if (sink.audio.muted && c > 0)
            sink.audio.muted = false
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    function nodeName(n) { return n ? (n.description || n.nickname || n.name || "output") : "" }
    function sinkGlyph(n) {
        const s = (n ? ((n.name || "") + " " + (n.description || "")) : "").toLowerCase()
        if (s.includes("bluez") || s.includes("headset") || s.includes("headphone")) return Icons.headphones
        if (s.includes("hdmi") || s.includes("displayport") || s.includes("display")) return Icons.monitor
        return Icons.volume
    }

    FlyoutPill {
        id: fp
        side: Qt.AlignRight
        panelWidth: 290
        maxLabelWidth: 90
        glyph: (root.muted || root.volPct === 0) ? Icons.volumeMute : Icons.volume
        label: root.muted ? "muted" : (root.volPct + "%")
        accent: root.muted ? Theme.red : Theme.blue
        onPillTapped: root.toggleMute()

        // master header + mute
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 5
            Layout.bottomMargin: 2
            Text {
                text: "sound"
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 11
                Layout.fillWidth: true
            }
            Row {
                spacing: 6
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    path: root.muted ? Icons.volumeMute : Icons.volume
                    size: 13
                    color: root.muted ? Theme.red : Theme.grey
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? "muted" : "mute"
                    color: root.muted ? Theme.red : Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
                TapHandler { onTapped: root.toggleMute() }
            }
        }

        // horizontal slider
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            spacing: 11

            Icon {
                path: (root.muted || root.volPct === 0) ? Icons.volumeMute : Icons.volume
                size: 17
                color: root.muted ? Theme.grey : Theme.blue
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 18

                Rectangle {
                    id: barBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.bg2
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, root.level))
                        radius: 3
                        color: root.muted ? Theme.grey : Theme.green
                    }
                }
                Rectangle {
                    width: 13
                    height: 13
                    radius: height / 2
                    color: Theme.fg
                    y: (parent.height - height) / 2
                    x: Math.max(0, Math.min(parent.width - width,
                        parent.width * Math.max(0, Math.min(1, root.level)) - width / 2))
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => root.setVolume(m.x / width)
                    onPositionChanged: (m) => { if (pressed) root.setVolume(m.x / width) }
                }
            }

            Text {
                text: root.volPct + "%"
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 12
                Layout.minimumWidth: 34
                horizontalAlignment: Text.AlignRight
            }
        }

        // output devices (only worth showing when there's a choice)
        FlyoutDivider { visible: root.sinks.length > 1 }
        FlyoutHeader { visible: root.sinks.length > 1; text: "output" }
        Repeater {
            model: root.sinks.length > 1 ? root.sinks : []
            FlyoutRow {
                required property var modelData
                readonly property bool isActive: Pipewire.defaultAudioSink === modelData
                onActivated: Pipewire.preferredDefaultAudioSink = modelData

                Icon { path: root.sinkGlyph(modelData); size: 16; color: isActive ? Theme.blue : Theme.grey }
                Text {
                    text: root.nodeName(modelData)
                    color: isActive ? Theme.fg : Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Icon { visible: isActive; path: Icons.check; size: 15; color: Theme.blue; stroke: 2.0 }
            }
        }
    }
}
