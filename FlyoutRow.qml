import QtQuick
import QtQuick.Layouts

// One row inside a flyout: leading glyph + body + trailing (its content is a
// RowLayout), with a color-only hover fill and a tap signal. `active` keeps the
// fill on (e.g. the playing media row); `progress` (0–1) draws a bottom line.
// Pointer handlers compose with the pill's hover zone — no dead zones.
Rectangle {
    id: row

    signal activated()

    default property alias content: lay.data
    property bool active: false
    property real progress: -1
    property int rowHeight: 34

    Layout.fillWidth: true
    implicitHeight: rowHeight
    radius: 9
    color: (active || hover.hovered) ? Theme.bg1 : "transparent"

    RowLayout {
        id: lay
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: row.progress >= 0 ? 4 : 0
        spacing: 11
    }

    Rectangle {
        visible: row.progress >= 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 4
        height: 2
        radius: 1
        color: Theme.bg2
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, row.progress))
            radius: 1
            color: Theme.green
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: row.activated() }
}
