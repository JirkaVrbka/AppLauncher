import Quickshell
import QtQuick
import QtQuick.Layouts

// Bottom command bar (pill style): a hint on the left, round icon buttons for
// the power actions on the right. Emits invoked(action) on a button click.
Rectangle {
    id: sb

    property var actions: []

    signal invoked(var action)

    implicitHeight: 46
    color: "transparent"

    function glyphFor(key) {
        if (key === "sleep") return Icons.moon
        if (key === "lock") return Icons.lock
        if (key === "shutdown") return Icons.power
        if (key === "restart") return Icons.restart
        if (key === "logout") return Icons.logout
        return Icons.power
    }

    // top divider
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.bg2
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 6
        anchors.rightMargin: 2
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "type a number to jump · ↩ launch"
            color: Theme.grey
            font.family: Theme.mono
            font.pixelSize: 12
        }

        Repeater {
            model: sb.actions

            delegate: Rectangle {
                required property var modelData
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: height / 2
                color: bh.containsMouse ? Theme.bg1 : Theme.bgDark

                Icon {
                    anchors.centerIn: parent
                    path: sb.glyphFor(modelData.key)
                    size: 17
                    color: modelData.key === "shutdown"
                        ? Theme.red
                        : (bh.containsMouse ? Theme.fg : Theme.blue)
                }

                MouseArea {
                    id: bh
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sb.invoked(modelData)
                }
            }
        }
    }
}
