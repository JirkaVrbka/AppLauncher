import QtQuick
import QtQuick.Layouts

// A flyout section label: 11px grey mono, standard margins. Set `text`.
// Hidden automatically collapses in the ColumnLayout.
Text {
    property int topMargin: 4

    color: Theme.grey
    font.family: Theme.mono
    font.pixelSize: 11
    Layout.fillWidth: true
    Layout.leftMargin: 10
    Layout.rightMargin: 10
    Layout.topMargin: topMargin
    Layout.bottomMargin: 2
}
