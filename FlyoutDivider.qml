import QtQuick
import QtQuick.Layouts

// 1px separator between flyout sections. Set `visible` to gate it.
Rectangle {
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.topMargin: 5
    Layout.bottomMargin: 5
    implicitHeight: 1
    color: Theme.bg2
}
