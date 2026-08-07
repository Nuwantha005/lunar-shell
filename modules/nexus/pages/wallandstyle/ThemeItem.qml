pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property var themeData
    property bool isActive: Theme.currentTheme.toLowerCase() === (themeData?.name ?? "").toLowerCase()

    signal clicked

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imgWrapper

            Layout.fillWidth: true
            implicitHeight: width
            radius: root.isActive ? Tokens.rounding.medium : Tokens.rounding.largeIncreased
            color: Colours.tPalette.m3surfaceContainer
            border.width: root.isActive ? 3 : 0
            border.color: Colours.palette.m3primary

            Behavior on radius {
                Anim { type: Anim.DefaultEffects }
            }

            Behavior on border.width {
                Anim { type: Anim.DefaultEffects }
            }

            Loader {
                anchors.centerIn: parent

                opacity: img.status === Image.Ready ? 0 : 1
                active: opacity > 0

                sourceComponent: StyledRect {
                    implicitWidth: loadingIndicator.implicitSize + Tokens.padding.large * 2
                    implicitHeight: loadingIndicator.implicitSize + Tokens.padding.large * 2

                    color: Colours.palette.m3primaryContainer
                    radius: Tokens.rounding.full

                    LoadingIndicator {
                        id: loadingIndicator

                        anchors.centerIn: parent
                        containsIcon: true
                        implicitSize: Math.min(imgWrapper.width, imgWrapper.height) * 0.3
                    }
                }

                Behavior on opacity {
                    Anim { type: Anim.DefaultEffects }
                }
            }

            Image {
                id: img

                anchors.fill: parent
                source: root.themeData?.wallpaper ? ("file://" + root.themeData.wallpaper) : ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim { type: Anim.SlowEffects }
                }
            }

            // Selected Checkmark Badge
            StyledRect {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.small

                visible: root.isActive
                implicitWidth: checkIcon.fontStyle.size + Tokens.padding.small * 2
                implicitHeight: checkIcon.fontStyle.size + Tokens.padding.small * 2
                color: Colours.palette.m3primary
                radius: Tokens.rounding.full

                MaterialIcon {
                    id: checkIcon
                    anchors.centerIn: parent
                    text: "check"
                    color: Colours.palette.m3onPrimary
                    fontStyle: Tokens.font.icon.medium
                }
            }
        }

        StyledText {
            id: label

            Layout.bottomMargin: Tokens.padding.small
            Layout.fillWidth: true
            text: (root.themeData?.name ?? "").toUpperCase()
            color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(root.isActive ? Font.Bold : Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    StateLayer {
        anchors.bottomMargin: layout.implicitHeight - imgWrapper.implicitHeight
        onClicked: root.clicked()
    }
}
