pragma Singleton

import Quickshell

// Power actions shared by the status bar and the typed-command matching.
// Shut Down / Restart / Log Out go through KDE's confirm screen
// (org.kde.LogoutPrompt); Sleep suspends immediately.
Singleton {
    readonly property var list: [
        { isPower: true, key: "sleep", name: "Sleep", glyph: Icons.moon, accent: Theme.blue,
          keywords: ["sleep", "suspend"],
          cmd: ["systemctl", "suspend"] },
        { isPower: true, key: "lock", name: "Lock", glyph: Icons.lock, accent: Theme.blue,
          keywords: ["lock", "lock screen"],
          cmd: ["loginctl", "lock-session"] },
        { isPower: true, key: "shutdown", name: "Shut Down", glyph: Icons.power, accent: Theme.red,
          keywords: ["shut down", "shutdown", "power off", "poweroff", "turn off"],
          cmd: ["qdbus6", "org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt.promptShutDown"] },
        { isPower: true, key: "restart", name: "Restart", glyph: Icons.restart, accent: Theme.blue,
          keywords: ["restart", "reboot"],
          cmd: ["qdbus6", "org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt.promptReboot"] },
        { isPower: true, key: "logout", name: "Log Out", glyph: Icons.logout, accent: Theme.blue,
          keywords: ["log out", "logout", "sign out", "log off"],
          cmd: ["qdbus6", "org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt.promptLogout"] },
    ]
}
