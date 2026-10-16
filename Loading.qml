pragma Singleton

import QtQuick
import Quickshell

// Shared animated "loading" indicator for top-bar pills whose data arrives
// asynchronously (wi-fi, bluetooth, volume). `dots()` returns THREE dots with
// the lit one moving — always three mono-width characters, so a pill showing it
// keeps a fixed width and never jiggles its neighbours while loading. One clock
// drives every pill so their animations stay in sync.
Singleton {
    id: root

    property int phase: 0

    Timer {
        interval: 350
        running: true
        repeat: true
        onTriggered: root.phase = (root.phase + 1) % 3
    }

    // e.g. "•··", "·•·", "··•". Reading root.phase makes callers' bindings
    // re-evaluate on each tick.
    function dots() {
        return (root.phase === 0 ? "•" : "·")
             + (root.phase === 1 ? "•" : "·")
             + (root.phase === 2 ? "•" : "·")
    }
}
