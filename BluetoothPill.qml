import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Bluetooth pill + devices flyout. Supports multiple connected devices (each
// with its battery), reconnecting paired devices, and pairing freshly
// discovered ones (scan runs only while the flyout is open).
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var _all: Bluetooth.devices ? Bluetooth.devices.values : []
    // Filters re-evaluate when any device's connected/paired changes, because
    // the binding captures each d.<prop> it reads.
    readonly property var connectedList: _all.filter(d => d.connected)
    readonly property var pairedList: _all.filter(d => d.paired && !d.connected)
    readonly property var availList: _all.filter(d => !d.paired && !d.connected)
    readonly property var primary: connectedList.length > 0 ? connectedList[0] : null

    visible: adapter !== null
    implicitWidth: fp.implicitWidth
    implicitHeight: fp.implicitHeight

    // Scan for new devices only while the flyout is open.
    onOpenChanged: if (adapter) adapter.discovering = (open && adapter.enabled)
    readonly property bool open: fp.open

    function devGlyph(d) {
        const n = (d && d.icon ? d.icon : "").toLowerCase()
        if (n.includes("headset") || n.includes("headphone")) return Icons.headphones
        if (n.includes("mouse")) return Icons.mouse
        if (n.includes("keyboard")) return Icons.keyboard
        if (n.includes("phone")) return Icons.phone
        if (n.includes("speaker")) return Icons.speakerBox
        if (n.includes("earbud") || n.includes("buds")) return Icons.buds
        if (n.includes("audio")) return Icons.headphones
        return Icons.chip
    }
    function devType(d) {
        const n = (d && d.icon ? d.icon : "").toLowerCase()
        if (n.includes("headset") || n.includes("headphone")) return "headphones"
        if (n.includes("mouse")) return "mouse"
        if (n.includes("keyboard")) return "keyboard"
        if (n.includes("phone")) return "phone"
        if (n.includes("speaker")) return "speaker"
        if (n.includes("audio")) return "audio"
        return "device"
    }

    FlyoutPill {
        id: fp
        side: Qt.AlignRight
        panelWidth: 286
        maxLabelWidth: 150
        glyph: Icons.bluetooth
        label: root.primary ? root.primary.name
            : (root.adapter && root.adapter.enabled ? "bluetooth" : "off")
        accent: root.connectedList.length > 0 ? Theme.blue
            : (root.adapter && root.adapter.enabled ? Theme.fg : Theme.grey)
        onPillTapped: if (root.adapter) root.adapter.enabled = !root.adapter.enabled

        // count badge when more than one device is connected
        trailing: Component {
            Rectangle {
                visible: root.connectedList.length > 1
                implicitWidth: visible ? Math.max(17, cnt.implicitWidth + 8) : 0
                implicitHeight: 17
                radius: height / 2
                color: Theme.blue
                Text {
                    id: cnt
                    anchors.centerIn: parent
                    text: root.connectedList.length
                    color: Theme.bgDark
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // master header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 5
            Layout.bottomMargin: 2
            Text {
                text: "bluetooth"
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 11
                Layout.fillWidth: true
            }
            FlyoutToggle {
                on: root.adapter ? root.adapter.enabled : false
                onColor: Theme.blue
                TapHandler { onTapped: if (root.adapter) root.adapter.enabled = !root.adapter.enabled }
            }
        }

        // connected
        FlyoutHeader { visible: root.connectedList.length > 0; text: "connected" }
        Repeater {
            model: root.connectedList
            FlyoutRow {
                required property var modelData
                onActivated: modelData.connected = false
                Icon { path: root.devGlyph(modelData); size: 16; color: Theme.blue }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: modelData.name
                        color: Theme.fg
                        font.family: Theme.mono
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.devType(modelData)
                        color: Theme.grey
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                }
                Row {
                    spacing: 7
                    Text {
                        visible: modelData.batteryAvailable
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(modelData.battery * 100) + "%"
                        color: (modelData.battery * 100) <= 30 ? Theme.orange : Theme.green
                        font.family: Theme.mono
                        font.pixelSize: 12
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 7; radius: 3.5
                        color: Theme.blue
                    }
                }
            }
        }

        // paired (not connected)
        FlyoutDivider { visible: root.pairedList.length > 0 }
        FlyoutHeader { visible: root.pairedList.length > 0; text: "paired" }
        Repeater {
            model: root.pairedList
            FlyoutRow {
                required property var modelData
                onActivated: modelData.connected = true
                Icon { path: root.devGlyph(modelData); size: 16; color: Theme.grey }
                Text {
                    text: modelData.name
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: modelData.state === BluetoothDeviceState.Connecting ? "…" : "connect"
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }
        }

        // discovered (unpaired) — shown while scanning
        FlyoutDivider { visible: root.availList.length > 0 }
        Repeater {
            model: root.availList
            FlyoutRow {
                required property var modelData
                onActivated: modelData.pair()
                Icon { path: root.devGlyph(modelData); size: 16; color: Theme.grey }
                Text {
                    text: modelData.name.length > 0 ? modelData.name : modelData.address
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: modelData.pairing ? "…" : "pair"
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }
        }

        // scanning indicator
        RowLayout {
            visible: root.adapter && root.adapter.discovering
            Layout.leftMargin: 10
            Layout.topMargin: 3
            Layout.bottomMargin: 4
            spacing: 9
            Icon {
                path: Icons.arc
                size: 13
                color: Theme.blue
                RotationAnimation on rotation {
                    running: root.adapter ? root.adapter.discovering : false
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 900
                }
            }
            Text {
                text: "scanning…"
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 12
            }
        }
    }
}
