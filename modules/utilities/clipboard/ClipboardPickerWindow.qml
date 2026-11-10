pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.utilities.clipboard

StyledWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    signal close()

    name: "clipboard-picker"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: Qt.rgba(0, 0, 0, 0.4)
    surfaceFormat.opaque: false

    // Click outside backdrop to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    ClipboardPickerContent {
        id: content
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, 1060)
        height: Math.min(parent.height * 0.82, 680)
        onClose: root.close()
    }
}
