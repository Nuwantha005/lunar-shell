pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components.misc
import qs.services
import qs.modules.utilities.clipboard

Scope {
    id: root

    LazyLoader {
        id: pickerLoader

        Variants {
            model: Screens.screens

            ClipboardPickerWindow {
                modelData: modelData
                onClose: pickerLoader.activeAsync = false
            }
        }
    }

    // Native Wayland global shortcut: caelestia:clipboard
    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clipboard"
        description: "Toggle clipboard history picker"
        onPressed: {
            if (pickerLoader.activeAsync) {
                pickerLoader.activeAsync = false;
            } else {
                Clipboard.refresh();
                pickerLoader.activeAsync = true;
            }
        }
    }

    IpcHandler {
        function open(): void {
            Clipboard.refresh();
            pickerLoader.activeAsync = true;
        }

        function openPicker(): void {
            Clipboard.refresh();
            pickerLoader.activeAsync = true;
        }

        function closePicker(): void {
            pickerLoader.activeAsync = false;
        }

        function toggle(): void {
            if (pickerLoader.activeAsync) {
                pickerLoader.activeAsync = false;
            } else {
                Clipboard.refresh();
                pickerLoader.activeAsync = true;
            }
        }

        function clear(): void {
            Clipboard.clearHistory();
        }

        target: "clipboard"
    }
}
