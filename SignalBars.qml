import QtQuick

// Four ascending bars; `level` (0–4) sets how many are lit.
Row {
    id: sb

    property int level: 0
    property color litColor: Theme.fg

    spacing: 2

    Repeater {
        model: 4
        delegate: Item {
            required property int index
            width: 3
            height: 14
            Rectangle {
                anchors.bottom: parent.bottom
                width: 3
                radius: 1
                height: 5 + parent.index * 3
                color: parent.index < sb.level ? sb.litColor : Theme.bg3
            }
        }
    }
}
