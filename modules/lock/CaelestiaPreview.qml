import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import "center"

Item {
    id: root

    required property string wallpaperPath
    required property string pfpPath

    clip: true

    // Background Layer with Wallpaper and Blur Effect
    Image {
        id: bgImg
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? root.wallpaperPath : (Wallpapers.lockWallpaper || Wallpapers.current)
        fillMode: Image.PreserveAspectCrop

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.6
            blurMax: 32
            blurMultiplier: 1
        }
    }

    // Semi-transparent overlay to ensure contrast
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
    }

    // 1920x1080 Reference Container scaled GPU-accelerated to fit preview box
    Item {
        id: refContainer
        width: 1920
        height: 1080
        anchors.centerIn: parent

        readonly property real scaleFactor: Math.min(root.width / 1920, root.height / 1080)
        scale: scaleFactor
        transformOrigin: Item.Center

        // Center Floating Card
        StyledRect {
            id: surfaceCard
            anchors.centerIn: parent
            width: 1280
            height: 760
            color: Colours.palette.m3surface
            radius: Tokens.rounding.extraLarge * 1.5
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraLargeIncreased
                spacing: Tokens.spacing.largeIncreased * 2

                // Left Column (Weather / Fetch / Media Preview)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Tokens.spacing.medium

                    WeatherInfo {
                        Layout.fillWidth: true
                        rootHeight: surfaceCard.height
                    }

                    Fetch {
                        Layout.fillWidth: true
                        rootHeight: surfaceCard.height
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.large
                        color: Colours.tPalette.m3surfaceContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "music_note"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                            }
                            StyledText {
                                text: "Media Player"
                                font: Tokens.font.title.medium
                                color: Colours.palette.m3onSurface
                            }
                        }
                    }
                }

                // Center Column (Clock, Date, Selected PFP, Password Pill)
                ColumnLayout {
                    Layout.preferredWidth: 380
                    Layout.fillHeight: true
                    spacing: Tokens.spacing.largeIncreased

                    Clock {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.padding.large
                        centerScale: 0.9
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Time.format("dddd • d MMM").toUpperCase()
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
                    }

                    // Profile Pic using selected PFP path
                    Item {
                        id: pfpContainer
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.spacing.large
                        Layout.bottomMargin: Tokens.spacing.medium
                        implicitWidth: 160
                        implicitHeight: 160

                        MaterialShape {
                            anchors.fill: parent
                            shape: MaterialShape.ClamShell
                            color: Colours.palette.m3surfaceContainerHigh

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: root.pfpPath
                                fillMode: Image.PreserveAspectCrop
                                visible: root.pfpPath !== "" && status === Image.Ready
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: root.pfpPath === "" || (parent.children[0] as Image).status !== Image.Ready
                                text: "person"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2.5).build()
                            }
                        }
                    }

                    // Mock Password Input Pill (No Auth Logic)
                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 320
                        implicitHeight: 52
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.large
                            anchors.rightMargin: Tokens.padding.large
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "lock"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: "Enter password"
                                color: Colours.palette.m3outline
                                font: Tokens.font.body.large
                            }

                            StyledRect {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: Tokens.rounding.full
                                color: Colours.palette.m3primary

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "arrow_forward"
                                    color: Colours.palette.m3onPrimary
                                    fontStyle: Tokens.font.icon.medium
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Caelestia Session Lock"
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }

                // Right Column (Resources / NotifDock Preview)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Tokens.spacing.medium

                    Resources {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        bottomRightRadius: Tokens.rounding.extraLarge
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "notifications"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.large
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No Notifications"
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
}
