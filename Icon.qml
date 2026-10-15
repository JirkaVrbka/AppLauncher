import QtQuick
import QtQuick.Shapes

// A single recolorable glyph drawn from an SVG path string (24×24 space).
// Stroked line icon by default; set `filled` for solid shapes. Color it with
// `color`, size with `size` — mirrors the tinted icons used across the bar.
Item {
    id: ic

    property string path: ""
    property real size: 16
    property color color: Theme.fg
    property bool filled: false
    property real stroke: 1.8

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: ic.size / 24
        antialiasing: true
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: ic.filled ? "transparent" : ic.color
            fillColor: ic.filled ? ic.color : "transparent"
            strokeWidth: ic.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: ic.path }
        }
    }
}
