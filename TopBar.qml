import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

// Full-width top bar: media + keyboard layout (left), clock + workspaces
// (center), volume + battery + bluetooth + wifi (right). `info` carries the
// script-polled bits (layout, workspaces); media/volume/battery/bluetooth/wifi
// are self-contained pill components reading their own Quickshell services.
Item {
    id: bar

    property var info: ({ layout: "", wsCount: 1, wsActive: 0 })

    signal layoutClicked()

    implicitHeight: 36

    // Needed for Pipewire to populate audio properties of the default sink.
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

    // --- derived data (volume + battery feed their pills) ---
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volPct: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    readonly property var batt: UPower.displayDevice
    // Quickshell reports percentage as a 0–1 fraction.
    readonly property int battPct: batt ? Math.round(batt.percentage * 100) : 0
    readonly property bool hasBatt: batt && battPct > 0
    readonly property bool charging: batt && (batt.state === UPowerDeviceState.Charging || batt.state === UPowerDeviceState.FullyCharged)

    // --- left: media + keyboard layout ---
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        MediaPill {}

        Pill {
            glyph: Icons.keyboard
            label: bar.info.layout
            accent: Theme.orange

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.layoutClicked()
            }
        }
    }

    // --- center: clock + workspaces ---
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        ClockPill {}

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 30
            implicitWidth: wsRow.implicitWidth + 24
            radius: height / 2
            color: Theme.bgDark

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: bar.info.wsCount

                    delegate: Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: index === bar.info.wsActive ? 11 : 9
                        height: width
                        radius: width / 2
                        color: index === bar.info.wsActive ? Theme.fg : Theme.bg3
                    }
                }
            }
        }
    }

    // --- right: volume + battery + bluetooth + wifi ---
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        VolumeControl {
            sink: bar.sink
            volPct: bar.volPct
            muted: bar.muted
        }

        Pill {
            visible: bar.hasBatt
            glyph: Icons.battery
            label: bar.battPct + "%"
            accent: bar.battPct <= 20 ? Theme.red : (bar.charging ? Theme.aqua : Theme.green)
        }

        BluetoothPill {}

        WifiVpnPill {}
    }
}
