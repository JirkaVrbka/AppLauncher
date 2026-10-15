pragma Singleton

import Quickshell
import QtQuick

// Line/solid icon path data (24×24 viewBox), lifted from the mockups.
// Rendered by Icon.qml via QtQuick.Shapes. `filled` icons set fillColor;
// the rest are stroked. One source of truth so the bar + flyouts share glyphs.
Singleton {
    // --- media ---
    readonly property string mediaPlay:  "M8 5v14l11-7z"                         // filled
    readonly property string mediaPause: "M7 5h3v14H7z M14 5h3v14h-3z"           // filled
    readonly property string skipPrev:   "M18 6v12l-8-6z M8 6h2v12H8z"           // filled
    readonly property string skipNext:   "M6 6v12l8-6z M14 6h2v12h-2z"           // filled

    // --- bar pills ---
    readonly property string keyboard:  "M2 6h20v12H2z M6.5 10h.01 M10.5 10h.01 M14.5 10h.01 M8 14h8"
    readonly property string clock:     "M12 3a9 9 0 1 0 0 18 9 9 0 1 0 0-18z M12 7.5v5l3.5 2"
    readonly property string battery:   "M2 7.5h17v9H2z M21 10.5v3"
    readonly property string volume:    "M11 5 6 9H3v6h3l5 4V5z M15.5 8.5a5 5 0 0 1 0 7"
    readonly property string volumeMute:"M11 5 6 9H3v6h3l5 4V5z M22 9.5l-5 5 M17 9.5l5 5"
    readonly property string monitor:   "M3 4h18v12H3z M8 20h8 M12 16v4"

    // --- bluetooth ---
    readonly property string bluetooth:  "M7 7l10 10-5 5V2l5 5L7 17"
    readonly property string headphones: "M4 14v-2a8 8 0 0 1 16 0v2 M3 14h4v6H3z M17 14h4v6h-4z"
    readonly property string mouse:      "M12 3a6 6 0 0 0-6 6v6a6 6 0 0 0 12 0V9a6 6 0 0 0-6-6z M12 3v6"
    readonly property string buds:       "M4 7h6v11H4z M14 7h6v11h-6z"
    readonly property string speakerBox: "M4 8h16v9H4z M8 8V6 M16 8V6"
    readonly property string phone:      "M7 3h10v18H7z M11 18h2"
    readonly property string chip:       "M6 8h12v8H6z M9 8V6 M15 8V6 M9 16v2 M15 16v2"

    // --- wifi / vpn ---
    readonly property string wifi:     "M5 12.6a11 11 0 0 1 14 0 M1.5 9a16 16 0 0 1 21 0 M8.5 16.1a6 6 0 0 1 7 0 M12 20h.01"
    readonly property string wifiMid:  "M5 12.6a11 11 0 0 1 14 0 M8.5 16.1a6 6 0 0 1 7 0 M12 20h.01"
    readonly property string wifiLow:  "M8.5 16.1a6 6 0 0 1 7 0 M12 20h.01"
    readonly property string lock:       "M5.5 11h13v9h-13z M8 11V8a4 4 0 0 1 8 0v3"
    readonly property string shield:     "M12 22s7.5-3.8 7.5-9.5V5.2L12 2.5 4.5 5.2v7.3C4.5 18.2 12 22 12 22z"
    readonly property string shieldCheck:"M12 22s7.5-3.8 7.5-9.5V5.2L12 2.5 4.5 5.2v7.3C4.5 18.2 12 22 12 22z M8.8 12.3l2 2 4.4-4.4"

    // --- commands / scopes (the ":" palette) ---
    readonly property string cmdTab:   "M3 6h18v13H3z M3 10h18 M8 6V4h6v2"   // tabbed window
    readonly property string terminal: "M4 5h16v14H4z M7 9l3 3-3 3 M13 15h4" // prompt
    readonly property string cmdOpen:  "M8 4h12v12H8z M4 8v12h12"            // window stack
    readonly property string cmdNew:   "M4 5h16v14H4z M12 9.5v5 M9.5 12h5"   // window + plus
    readonly property string screenshot: "M4 8h3l2-3h6l2 3h3v11H4z M12 10a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z"
    readonly property string google:   "M12 3a9 9 0 1 0 0 18 9 9 0 1 0 0-18z M3 12h18 M12 3c3 3 3 15 0 18 M12 3c-3 3-3 15 0 18" // globe

    // --- power actions (bottom command bar) ---
    readonly property string moon:    "M20 14a8 8 0 1 1-9.5-10.6 6.5 6.5 0 0 0 9.5 10.6z"
    readonly property string power:   "M12 3v9 M7 6a8 8 0 1 0 10 0"
    readonly property string restart: "M3 12a9 9 0 1 0 2.6-6.4 M3 4v4h4"
    readonly property string logout:  "M14 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3 M9 12h11 M16 9l3 3-3 3"

    // --- notes (Obsidian) ---
    readonly property string note: "M6 3h8l4 4v14H6z M14 3v4h4 M9 12h6 M9 15h6 M9 18h4" // page + text lines

    // --- generic ---
    readonly property string check: "M20 6.5 9.5 17 4.5 12"
    readonly property string arc:   "M12 3a9 9 0 0 1 9 9"   // quarter arc for a spinner
}
