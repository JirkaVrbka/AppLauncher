import QtQuick

// Clock capsule (HH:mm) built on the two-tone Pill. Neutral icon segment.
Pill {
    id: clock

    property string time: Qt.formatDateTime(new Date(), "HH:mm")

    glyph: Icons.clock
    label: time
    accent: Theme.purple

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.time = Qt.formatDateTime(new Date(), "HH:mm")
    }
}
