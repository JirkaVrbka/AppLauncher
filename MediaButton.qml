import QtQuick

// A small transparent control button for the media flyout (prev/play/next).
// Set `enabled` (built-in) false to dim + disable it.
Item {
    id: mb

    property string glyph: ""
    property color tint: Theme.fg
    signal tapped()

    implicitWidth: 26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: hh.hovered ? Theme.bg2 : "transparent"
    }

    Icon {
        anchors.centerIn: parent
        path: mb.glyph
        filled: true
        size: 14
        color: mb.enabled ? mb.tint : Theme.bg3
    }

    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: mb.tapped() }
}
