pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc
import qs.services
import qs.modules.lock

Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Connections {
        target: lock
        function onLockedChanged(): void {
            if (lock.locked && Theme.lockBackend === "hyprlock") {
                lock.locked = false;
                Quickshell.execDetached(["hyprlock"]);
            }
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: {
            lock.unlock();
            Quickshell.execDetached(["pkill", "-USR1", "hyprlock"]);
        }
    }

    LazyLoader {
        id: lockPickerLoader

        Variants {
            model: Screens.screens

            LockPickerWindow {
                modelData: modelData
                onClose: lockPickerLoader.activeAsync = false
            }
        }
    }

    IpcHandler {
        function lock(): void {
            lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
            Quickshell.execDetached(["pkill", "-USR1", "hyprlock"]);
        }

        function isLocked(): bool {
            return lock.locked;
        }

        function openPicker(): void {
            lockPickerLoader.activeAsync = true;
        }

        function closePicker(): void {
            lockPickerLoader.activeAsync = false;
        }

        target: "lock"
    }
}
