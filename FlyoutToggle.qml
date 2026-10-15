import QtQuick

// Small pill toggle used for the master on/off and VPN profiles.
Rectangle {
    id: t

    property bool on: false
    property color onColor: Theme.green

    implicitWidth: 26
    implicitHeight: 15
    radius: height / 2
    color: on ? onColor : Theme.bg3
    antialiasing: true
    Behavior on color { ColorAnimation { duration: 90 } }

    Rectangle {
        width: 11
        height: 11
        radius: height / 2
        color: Theme.bgDark
        y: 2
        x: t.on ? 13 : 2
        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    }
}
