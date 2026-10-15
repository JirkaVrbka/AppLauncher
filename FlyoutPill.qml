import QtQuick
import QtQuick.Layouts

// A top-bar pill plus its hover flyout, in one piece: the dark capsule
// (glyph + label + optional `trailing` adornment), the behind hover-zone that
// keeps the flyout open across the pill→panel gap, and the dropdown surface
// whose body is this component's default content. `side` picks the edge to
// align to (right for the right-hand pills, left for media).
Item {
    id: root

    // capsule
    property string glyph: ""
    property bool glyphFilled: false
    property color accent: Theme.fg
    property string label: ""
    property color labelColor: Theme.fg
    property int maxLabelWidth: 170
    property Component trailing: null
    signal pillTapped()

    // flyout
    property int side: Qt.AlignRight
    property int panelWidth: 300
    readonly property int pad: 6
    readonly property int gap: 5
    readonly property bool atRight: side === Qt.AlignRight
    readonly property bool open: zone.containsMouse || bridge.containsMouse || hh.hovered

    default property alias content: col.data

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    // Hover zone over the pill itself (behind it, click-transparent). Kept at
    // pill.width so it never overlaps the neighbouring pills in the row — the
    // old panel-wide zone stretched across the row and trapped hover on the open
    // pill, blocking the pill the cursor moved onto.
    MouseArea {
        id: zone
        z: -1
        anchors.top: pill.top
        anchors.left: root.atRight ? undefined : pill.left
        anchors.right: root.atRight ? pill.right : undefined
        width: pill.width
        height: pill.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Bridge across the pill→panel gap so the cursor can cross onto the panel
    // without the flyout closing. Sits BELOW the pill row (anchored to
    // pill.bottom) and only widens to the panel when open, so it spans the gap
    // horizontally without ever overlapping the neighbouring pills in the row.
    MouseArea {
        id: bridge
        z: -1
        anchors.top: pill.bottom
        anchors.left: root.atRight ? undefined : pill.left
        anchors.right: root.atRight ? pill.right : undefined
        width: root.open ? panel.width : 0
        height: root.gap + 2
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // capsule
    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.left: root.atRight ? undefined : parent.left
        anchors.right: root.atRight ? parent.right : undefined
        implicitHeight: 30
        implicitWidth: pillRow.implicitWidth + 26
        radius: height / 2
        color: Theme.bgDark

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            Icon {
                visible: root.glyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                path: root.glyph
                filled: root.glyphFilled
                color: root.accent
                size: 15
            }
            Text {
                visible: root.label.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: root.labelColor
                font.family: Theme.mono
                font.pixelSize: 13
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, root.maxLabelWidth)
            }
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: root.trailing !== null
                sourceComponent: root.trailing
            }
        }

        TapHandler { onTapped: root.pillTapped() }
    }

    // flyout surface — fades + slides in; body is `content` (goes into col).
    Rectangle {
        id: panel
        anchors.top: pill.bottom
        anchors.topMargin: root.gap
        anchors.left: root.atRight ? undefined : pill.left
        anchors.right: root.atRight ? pill.right : undefined

        width: root.panelWidth
        height: col.implicitHeight + root.pad * 2
        radius: 12
        color: Theme.bgDark
        border.color: Theme.bg2
        border.width: 1
        antialiasing: true
        clip: true

        visible: opacity > 0.01
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: root.open ? 0 : -6
            Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            id: col
            x: root.pad
            y: root.pad
            width: root.panelWidth - root.pad * 2
            spacing: 2
        }

        HoverHandler { id: hh }
    }
}
