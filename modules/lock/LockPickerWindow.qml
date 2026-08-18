pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.lock

StyledWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    signal close

    name: "lock-picker"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: Colours.tPalette.m3surface
    surfaceFormat.opaque: false

    LockPickerContent {
        id: content
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.92, 1350)
        height: Math.min(parent.height * 0.88, 800)
        onClose: root.close()
    }
}
