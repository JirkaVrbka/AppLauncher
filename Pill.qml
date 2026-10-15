import QtQuick

// Rounded dark capsule: a tinted glyph icon + light mono label. Used by the
// simple top-bar pills (clock, keyboard, battery). The interactive hover-flyout
// pills are built on FlyoutPill instead.
Rectangle {
    id: pill

    property string glyph: ""              // Icons.* path
    property string label: ""
    property color accent: Theme.fg        // icon color
    property color labelColor: Theme.fg    // value text color

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 26
    radius: height / 2
    color: Theme.bgDark

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: pill.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            path: pill.glyph
            color: pill.accent
            size: 15
        }

        Text {
            visible: pill.label.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: pill.label
            color: pill.labelColor
            font.family: Theme.mono
            font.pixelSize: 13
        }
    }
}
