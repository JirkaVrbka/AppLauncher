import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// One result row (pill style): number gutter, icon (app icon / tab favicon /
// themed command icon), highlighted name + subtitle, and a trailing source /
// command-keyword pill. Selection is drawn by the ListView highlight behind;
// this delegate adds the hover fill. Used as the ListView delegate.
Item {
    id: row

    required property var modelData
    required property int index
    property bool tabMode: false
    property bool openMode: false
    property bool commandMode: false
    property string query: ""
    readonly property bool selected: ListView.isCurrentItem

    signal clicked()

    width: ListView.view ? ListView.view.width : implicitWidth
    height: 48

    // Non-app items (commands, power/built-in actions) carry their own line
    // `glyph` + `accent`; apps fall back to the themed IconImage.
    readonly property string itemGlyph: (!tabMode && modelData && modelData.glyph) ? modelData.glyph : ""
    readonly property color itemAccent: (modelData && modelData.accent) ? modelData.accent : Theme.fg

    // trailing pill text/color: tab source, or command keyword
    readonly property string trailingText: tabMode ? (modelData.source ?? "")
        : commandMode ? (":" + (modelData.key ?? ""))
        : ""
    readonly property color trailingColor: tabMode
        ? (modelData.source === "kitty" ? Theme.aqua : Theme.green)
        : (commandMode ? Theme.blue : Theme.grey)

    // hover fill (selection comes from the ListView highlight behind this)
    Rectangle {
        anchors.fill: parent
        radius: 12
        visible: hov.containsMouse && !row.selected
        color: Theme.bg1
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 13

        // number gutter
        Text {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignRight
            text: row.index + 1
            color: row.selected ? Theme.green : Theme.bg3
            font.family: Theme.mono
            font.pixelSize: 12
        }

        // app icon (themed, real icon)
        IconImage {
            visible: !row.tabMode && row.itemGlyph.length === 0
            implicitSize: 22
            source: (row.tabMode || row.itemGlyph.length > 0)
                ? "" : Quickshell.iconPath(row.modelData.icon, "application-x-executable")
        }

        // non-app item: a tinted line glyph (commands, power/built-in actions)
        Icon {
            visible: !row.tabMode && row.itemGlyph.length > 0
            path: row.itemGlyph
            color: row.itemAccent
            size: 22
        }

        // tab favicon, with a themed fallback
        Image {
            visible: row.tabMode
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            sourceSize.width: 22
            sourceSize.height: 22
            fillMode: Image.PreserveAspectFit
            source: {
                if (!row.tabMode)
                    return ""
                if (row.modelData.favIconUrl && row.modelData.favIconUrl.length > 0)
                    return row.modelData.favIconUrl
                if (row.modelData.source === "kitty")
                    return Quickshell.iconPath("utilities-terminal", "terminal")
                return Quickshell.iconPath("web-browser", "applications-internet")
            }
            onStatusChanged: {
                if (status === Image.Error)
                    source = row.modelData.source === "kitty"
                        ? Quickshell.iconPath("utilities-terminal", "terminal")
                        : Quickshell.iconPath("web-browser", "applications-internet")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Theme.hl(row.tabMode ? row.modelData.title
                    : row.openMode ? row.modelData.appName
                    : row.modelData.name, row.query)
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: row.tabMode ? (row.modelData.url ?? "")
                    : row.openMode ? (row.modelData.title ?? "")
                    : (row.modelData.comment ?? "")
                color: Theme.grey
                font.family: Theme.mono
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // trailing pill (tab source / command keyword)
        Rectangle {
            visible: row.trailingText.length > 0
            Layout.preferredHeight: 24
            implicitWidth: tagText.implicitWidth + 22
            radius: height / 2
            color: Theme.bgDark
            Text {
                id: tagText
                anchors.centerIn: parent
                text: row.trailingText
                color: row.trailingColor
                font.family: Theme.mono
                font.pixelSize: 11
            }
        }
    }
}
