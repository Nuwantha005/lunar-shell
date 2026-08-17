pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Caelestia.Config
import qs.services
import qs.utils

Item {
    id: root

    property WlSessionLock lock
    property Pam pam

    readonly property string themeName: Theme.qylockTheme || "nier-automata"
    readonly property string themePath: Quickshell.shellPath("lock-themes/themes/" + themeName)

    property string backgroundOverridePath: ""

    // Emergency unlock: Ctrl+Alt+Backspace 3 times in 3 seconds
    property int panicCount: 0

    Timer {
        id: panicReset
        interval: 3000
        onTriggered: root.panicCount = 0
    }

    Item {
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.AltModifier)) {
                root.panicCount++;
                panicReset.restart();
                if (root.panicCount >= 3) {
                    console.warn("QylockSurface: Emergency unlock triggered!");
                    if (root.lock) root.lock.unlock();
                }
                event.accepted = true;
            }
        }
    }

    FileView {
        path: `${Paths.state}/lock_override_bg`
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.backgroundOverridePath = text().trim();
            if (themeLoader.item && ("overrideBg" in themeLoader.item)) {
                themeLoader.item.overrideBg = root.backgroundOverridePath;
            }
        }
    }

    property var config: ({})

    FileView {
        path: "file://" + root.themePath + "/theme.conf"
        printErrors: false
        onLoaded: {
            const newConfig = {};
            const lines = text().split("\n");
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                const parts = line.split("=");
                if (parts.length === 2) {
                    newConfig[parts[0].trim()] = parts[1].trim();
                }
            }
            if (!newConfig.background) newConfig.background = "bg.png";
            root.config = newConfig;
        }
    }

    // Dedicated PamContext for Qylock themes to ensure 100% reliable auth
    PamContext {
        id: qylockPam
        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")
        property string pendingPassword: ""

        onResponseRequiredChanged: {
            if (responseRequired && pendingPassword !== "") {
                respond(pendingPassword);
                pendingPassword = "";
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.sddm.loginSucceeded();
                if (root.lock) {
                    root.lock.unlock();
                }
            } else {
                root.sddm.loginFailed();
            }
        }
    }

    property var sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()

        function login(user, password, sessionIndex) {
            qylockPam.pendingPassword = password;
            qylockPam.start();
        }

        function reboot() {
            Quickshell.execDetached(["systemctl", "reboot"]);
        }

        function powerOff() {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    property var userModel: ListModel {
        property string lastUser: Quickshell.env("USER") || "user"
        property int lastIndex: 0
        function rowCount() { return count; }
        function index(row, col) { return row; }
        function data(row, role) {
            const item = get(row);
            if (!item) return "";
            if (role === (Qt.UserRole + 1)) return item.name;
            if (role === (Qt.UserRole + 2)) return item.realName;
            return item.name;
        }
        Component.onCompleted: {
            append({
                name: Quickshell.env("USER") || "user",
                realName: Quickshell.env("USER") || "User",
                icon: "",
                homeDir: "/home/" + (Quickshell.env("USER") || "user")
            });
        }
    }

    property var sessionModel: ListModel {
        property int lastIndex: 0
        function rowCount() { return count; }
        function index(row, col) { return row; }
        function data(row, role) {
            const item = get(row);
            if (!item) return "";
            return item.name;
        }
        Component.onCompleted: {
            append({ name: "Hyprland", file: "hyprland.desktop" });
        }
    }

    Loader {
        id: themeLoader
        anchors.fill: parent
        source: "file://" + root.themePath + "/Main.qml"

        onLoaded: {
            if (item) {
                item.forceActiveFocus();
                if ("overrideBg" in item) {
                    item.overrideBg = root.backgroundOverridePath;
                }
            }
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("QylockSurface: Failed to load qylock theme:", source);
            }
        }
    }
}
