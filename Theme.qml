pragma Singleton

import Quickshell
import QtQuick

// Everforest (dark, soft) design tokens + text helpers.
// Single source of truth for colors/typography — see DESIGN.md.
Singleton {
    readonly property string bgDark:  "#232a2e"   // darker surface, e.g. top-bar pills
    readonly property string bg:      "#2d353b"
    readonly property string bg1:     "#343f44"
    readonly property string bg2:     "#3d484d"
    readonly property string bg3:     "#475258"
    readonly property string purple:  "#d699b6"
    readonly property string fg:     "#d3c6aa"
    readonly property string grey:   "#859289"
    readonly property string green:  "#a7c080"
    readonly property string orange: "#e69875"
    readonly property string blue:   "#7fbbb3"
    readonly property string red:    "#e67e80"
    readonly property string aqua:   "#83c092"
    readonly property string mono:   "Hack"

    function escapeHtml(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    // A name with the matched query substring highlighted (orange, bold).
    // Returns StyledText-compatible markup.
    function hl(s, query) {
        const str = (s === undefined || s === null) ? "" : String(s)
        const q = (query || "").trim()
        if (q.length === 0)
            return escapeHtml(str)
        const i = str.toLowerCase().indexOf(q.toLowerCase())
        if (i < 0)
            return escapeHtml(str)
        return escapeHtml(str.slice(0, i))
            + '<b><font color="' + orange + '">' + escapeHtml(str.slice(i, i + q.length)) + '</font></b>'
            + escapeHtml(str.slice(i + q.length))
    }
}
