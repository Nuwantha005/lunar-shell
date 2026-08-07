pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property string themeStatePath: `${Paths.state}/theme.json`

    property string currentTheme: ""
    property string themePath: ""
    property string lockBackend: "caelestia"
    property string qylockTheme: ""
    property var themeData: ({})
    property list<var> themesList: []

    function setTheme(name: string): void {
        Quickshell.execDetached(["caelestia", "theme", "set", name]);
    }

    function setWallpaper(path: string): void {
        Quickshell.execDetached(["caelestia", "theme", "wallpaper", "set", path]);
    }

    function setPfp(path: string): void {
        Quickshell.execDetached(["caelestia", "theme", "pfp", "set", path]);
    }

    function refreshThemeList(): void {
        listProc.running = true;
    }

    FileView {
        path: root.themeStatePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.currentTheme = data.name ?? "";
                root.themePath = data.path ?? "";
                root.lockBackend = data.lockBackend ?? "caelestia";
                root.qylockTheme = data.qylockTheme ?? "";
                root.themeData = data;
            } catch (e) {
                console.warn("Failed to parse theme.json:", e);
            }
            root.refreshThemeList();
        }
        onLoadFailed: {
            root.currentTheme = "";
            root.themePath = "";
            root.themeData = ({});
            root.refreshThemeList();
        }
    }

    Process {
        id: listProc

        command: ["caelestia", "theme", "list", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themesList = JSON.parse(text);
                } catch (e) {
                    root.themesList = [];
                }
            }
        }
    }

    Component.onCompleted: refreshThemeList()
}
