pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.lock

PageBase {
    id: root

    title: qsTr("Lock screen")
    isSubPage: true

    LockPickerContent {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        implicitHeight: 640
        onClose: {
            if (root.nState) root.nState.back();
        }
    }
}
