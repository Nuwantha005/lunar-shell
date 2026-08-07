pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Themes")
    isSubPage: true

    Component.onCompleted: Theme.refreshThemeList()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.small
            text: qsTr("Available themes")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: Theme.themesList.length > 0

            columns: Config.nexus.wallpapersPerRow ?? 3
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                id: themesRepeater

                model: Theme.themesList

                ThemeItem {
                    required property var modelData

                    themeData: modelData

                    onClicked: {
                        Theme.setTheme(modelData.name);
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: Theme.themesList.length === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: noThemesLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noThemesLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "palette"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No themes found in ~/Pictures/themes")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }
}
