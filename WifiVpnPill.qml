import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Wi-Fi pill + flyout: available networks on top, VPN profiles below. The pill
// carries a green "vpn" tag whenever a VPN is connected. Data + actions go
// through nmcli (netinfo.sh); the launcher has no NetworkManager service.
Item {
    id: root

    readonly property string script: Qt.resolvedUrl("netinfo.sh").toString().replace("file://", "")
    property var net: ({ wifiEnabled: false, ssid: "", vpnActive: false, networks: [], vpns: [] })
    readonly property bool open: fp.open

    visible: true
    implicitWidth: fp.implicitWidth
    implicitHeight: fp.implicitHeight

    function level(sig) {
        return sig >= 75 ? 4 : sig >= 50 ? 3 : sig >= 25 ? 2 : sig > 0 ? 1 : 0
    }
    function wifiGlyph(sig) {
        return sig >= 55 ? Icons.wifi : sig >= 25 ? Icons.wifiMid : Icons.wifiLow
    }

    // --- data ---
    Process {
        id: netProc
        command: ["bash", root.script]
        stdout: StdioCollector {
            id: netOut
            onStreamFinished: { try { root.net = JSON.parse(netOut.text) } catch (e) {} }
        }
    }
    function refresh() { if (!netProc.running) netProc.running = true }
    Component.onCompleted: refresh()
    onOpenChanged: if (open) refresh()
    Timer { interval: 3000; running: root.open; repeat: true; onTriggered: root.refresh() }

    // --- actions ---
    Process { id: actionProc; onExited: root.refresh() }
    function run(args) { if (!actionProc.running) { actionProc.command = args; actionProc.running = true } }
    function wifiConnect(ssid) { run(["nmcli", "dev", "wifi", "connect", ssid]) }
    function vpnUp(name) { run(["nmcli", "connection", "up", name]) }
    function vpnDown(name) { run(["nmcli", "connection", "down", name]) }
    function toggleRadio() { run(["nmcli", "radio", "wifi", root.net.wifiEnabled ? "off" : "on"]) }

    FlyoutPill {
        id: fp
        side: Qt.AlignRight
        panelWidth: 300
        maxLabelWidth: 150
        glyph: Icons.wifi
        accent: root.net.wifiEnabled ? Theme.purple : Theme.grey
        label: root.net.ssid.length > 0 ? root.net.ssid
            : (root.net.wifiEnabled ? "wi-fi" : "off")
        onPillTapped: root.toggleRadio()

        // green "vpn" wash tag when a VPN is connected
        trailing: Component {
            Rectangle {
                visible: root.net.vpnActive
                implicitWidth: visible ? vpnRow.implicitWidth + 14 : 0
                implicitHeight: 19
                radius: height / 2
                color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.16)
                Row {
                    id: vpnRow
                    anchors.centerIn: parent
                    spacing: 5
                    Icon { anchors.verticalCenter: parent.verticalCenter; path: Icons.shield; size: 12; color: Theme.green }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "vpn"
                        color: Theme.green
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
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
                text: "wi-fi"
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 11
                Layout.fillWidth: true
            }
            FlyoutToggle {
                on: root.net.wifiEnabled
                onColor: Theme.purple
                TapHandler { onTapped: root.toggleRadio() }
            }
        }

        FlyoutHeader { text: "networks"; topMargin: 2 }
        Repeater {
            model: root.net.networks
            FlyoutRow {
                required property var modelData
                onActivated: if (!modelData.active) root.wifiConnect(modelData.ssid)

                Icon {
                    path: root.wifiGlyph(modelData.signal)
                    size: 16
                    color: modelData.active ? Theme.purple : Theme.grey
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        spacing: 7
                        Text {
                            text: modelData.ssid
                            color: modelData.active ? Theme.fg : Theme.grey
                            font.family: Theme.mono
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Icon {
                            visible: modelData.secured
                            path: Icons.lock
                            size: 12
                            color: Theme.grey
                            stroke: 2.0
                        }
                    }
                    Text {
                        visible: modelData.active
                        text: "connected"
                        color: Theme.grey
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                }
                SignalBars { level: root.level(modelData.signal); litColor: modelData.active ? Theme.purple : Theme.fg }
                Icon {
                    visible: modelData.active
                    path: Icons.check
                    size: 15
                    color: Theme.purple
                    stroke: 2.0
                }
                Text {
                    visible: !modelData.active
                    text: "join"
                    color: Theme.grey
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }
        }

        FlyoutDivider { visible: root.net.vpns.length > 0 }
        FlyoutHeader { visible: root.net.vpns.length > 0; text: "vpn" }
        Repeater {
            model: root.net.vpns
            FlyoutRow {
                required property var modelData
                onActivated: modelData.active ? root.vpnDown(modelData.name) : root.vpnUp(modelData.name)

                Icon {
                    path: modelData.active ? Icons.shieldCheck : Icons.shield
                    size: 16
                    color: modelData.active ? Theme.green : Theme.grey
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: modelData.name
                        color: modelData.active ? Theme.fg : Theme.grey
                        font.family: Theme.mono
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.type + (modelData.active ? " · connected" : "")
                        color: Theme.grey
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                }
                FlyoutToggle { on: modelData.active; onColor: Theme.green }
            }
        }
    }
}
