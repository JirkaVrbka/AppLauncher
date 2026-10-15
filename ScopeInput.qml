import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The input bar as one rounded dark capsule (pill style): a mode chip, the
// text field, and a match-count chip. Owns scope entry/exit; reports
// navigation and submission via signals.
Rectangle {
    id: bar

    property alias text: field.text
    property string scope: ""              // "" = none, else the scope name (e.g. "tab", "power")
    property var knownScopes: ["tab"]      // keywords that "<scope> " turns into a pill
    property int matchCount: 0
    property string mode: "APPS"           // shown in the mode chip

    signal navUp()
    signal navDown()
    signal accepted()
    signal escaped()
    signal scopeEntered(string scope)
    signal queryEdited()

    function focusInput() { field.forceActiveFocus() }

    implicitHeight: 54
    radius: 15
    color: Theme.bgDark

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 12

        // mode chip (also reflects the active scope)
        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: modeText.implicitWidth + 22
            radius: height / 2
            color: Theme.green
            Text {
                id: modeText
                anchors.centerIn: parent
                text: bar.mode
                color: Theme.bgDark
                font.family: Theme.mono
                font.pixelSize: 12
                font.bold: true
            }
        }

        TextField {
            id: field
            Layout.fillWidth: true
            focus: true
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 16
            placeholderText: bar.scope === "tab" ? "search open tabs…"
                : bar.scope === "term" ? "search kitty terminal tabs…"
                : bar.scope === "power" ? "choose a power action…"
                : bar.scope === "new" ? "launch a new instance…"
                : bar.scope === "open" ? "switch to an open window…"
                : bar.scope === "google" ? "search Google…"
                : "search apps"
            placeholderTextColor: Theme.grey
            selectionColor: Theme.green
            selectedTextColor: Theme.bgDark
            background: Rectangle { color: "transparent" }

            onTextChanged: {
                // Typing "<scope> " swallows the prefix into the mode chip.
                if (bar.scope.length === 0) {
                    const sp = text.indexOf(" ")
                    if (sp > 0) {
                        const w = text.slice(0, sp).toLowerCase()
                        if (bar.knownScopes.indexOf(w) !== -1) {
                            bar.scope = w
                            text = text.slice(sp + 1)
                            bar.scopeEntered(w)
                        }
                    }
                }
                bar.queryEdited()
            }

            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) {
                    bar.escaped()
                    e.accepted = true
                } else if (e.key === Qt.Key_Backspace && bar.scope.length > 0 && text.length === 0) {
                    // Backspace on an empty query drops the scope.
                    bar.scope = ""
                    e.accepted = true
                } else if (e.key === Qt.Key_Down) {
                    bar.navDown()
                    e.accepted = true
                } else if (e.key === Qt.Key_Up) {
                    bar.navUp()
                    e.accepted = true
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    bar.accepted()
                    e.accepted = true
                }
            }
        }

        // match-count chip
        Rectangle {
            visible: bar.matchCount > 0
            Layout.preferredHeight: 24
            Layout.preferredWidth: countText.implicitWidth + 20
            radius: height / 2
            color: Theme.bg2
            Text {
                id: countText
                anchors.centerIn: parent
                text: bar.matchCount
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 12
            }
        }
    }
}
