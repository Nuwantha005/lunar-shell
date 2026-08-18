pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Lock screen")
    isSubPage: true

    readonly property list<string> backends: ["caelestia", "qylock", "hyprlock"]
    readonly property list<string> qylockThemes: [
        "Genshin", "R1999_1", "R1999_2", "clockwork", "dog-samurai", "enfield", "field", "forest",
        "girl-coffee", "girl-pillow", "last-of-us", "man-bicycle", "material-you", "minecraft",
        "nier-automata", "ninesols", "ninja_gaiden", "nothing", "osu", "osumania", "pixel-coffee",
        "pixel-cyberpunk", "pixel-dusk-city", "pixel-emerald", "pixel-hollowknight", "pixel-munchlax",
        "pixel-night-city", "pixel-rainyroom", "pixel-sakura", "pixel-skyscrapers", "pixel-waterfall",
        "star-rail", "sword", "terraria", "windows_7", "winter", "women-umbrella", "wuwa"
    ]

    function getPreviewUrl(name: string): string {
        const filenames = {
            "Genshin": "genshin.gif",
            "R1999_1": "R1999_1.gif",
            "R1999_2": "R1999_2.gif",
            "clockwork": "clockwork.gif",
            "dog-samurai": "dog_samurai.gif",
            "enfield": "enfield.gif",
            "field": "field.gif",
            "forest": "forest.gif",
            "girl-coffee": "girl_coffee.gif",
            "girl-pillow": "girl_pillow.gif",
            "last-of-us": "the_last_of_us.gif",
            "man-bicycle": "man_bicycle.gif",
            "material-you": "material-you.gif",
            "minecraft": "minecraft.gif",
            "nier-automata": "nier_automata.gif",
            "ninesols": "title.png",
            "ninja_gaiden": "ninja_gaiden.gif",
            "nothing": "nothing.gif",
            "osu": "osu.gif",
            "osumania": "osumania.gif",
            "pixel-coffee": "pixel_coffee.gif",
            "pixel-cyberpunk": "pixel-cyberpunk.gif",
            "pixel-dusk-city": "pixel_dusk_city.gif",
            "pixel-emerald": "pixel-emerald.gif",
            "pixel-hollowknight": "pixel_hollowknight.gif",
            "pixel-munchlax": "pixel_munchlax.gif",
            "pixel-night-city": "pixel_night_city.gif",
            "pixel-rainyroom": "pixel_rainyroom.gif",
            "pixel-sakura": "pixel-sakura.gif",
            "pixel-skyscrapers": "pixel_skyscrapers.gif",
            "pixel-waterfall": "pixel-waterfall.gif",
            "star-rail": "star_rail.gif",
            "sword": "sword.gif",
            "terraria": "terraria.gif",
            "windows_7": "win7.gif",
            "winter": "winter.gif",
            "women-umbrella": "women_umbrella.gif",
            "wuwa": "wuwa.gif"
        };
        const fname = filenames[name] || (name + ".gif");
        return Quickshell.shellPath("lock-themes/Assets/" + fname);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("Backend")
            font: Tokens.font.title.small
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            Repeater {
                model: root.backends

                IconTextButton {
                    required property string modelData

                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    type: Theme.lockBackend === modelData ? IconTextButton.Primary : IconTextButton.Tonal
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: Theme.setLockBackend(modelData)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Theme.lockBackend === "qylock"
            spacing: Tokens.spacing.small

            StyledText {
                Layout.topMargin: Tokens.spacing.medium
                Layout.bottomMargin: Tokens.spacing.extraSmall
                text: qsTr("Qylock theme")
                font: Tokens.font.title.small
            }

            GridLayout {
                Layout.fillWidth: true
                columns: Config.nexus.wallpapersPerRow ?? 3
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.qylockThemes

                    Item {
                        id: themeItemRoot
                        required property string modelData

                        property bool isActive: Theme.qylockTheme === modelData

                        Layout.fillWidth: true
                        implicitHeight: itemColumn.implicitHeight

                        ColumnLayout {
                            id: itemColumn
                            anchors.fill: parent
                            spacing: Tokens.spacing.small

                            StyledClippingRect {
                                id: imgBox
                                Layout.fillWidth: true
                                implicitHeight: width * 0.6
                                radius: themeItemRoot.isActive ? Tokens.rounding.medium : Tokens.rounding.large
                                color: Colours.tPalette.m3surfaceContainer
                                border.width: themeItemRoot.isActive ? 3 : 0
                                border.color: Colours.palette.m3primary

                                AnimatedImage {
                                    anchors.fill: parent
                                    source: root.getPreviewUrl(themeItemRoot.modelData)
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                }

                                StyledRect {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Tokens.padding.small
                                    visible: themeItemRoot.isActive
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
                                Layout.fillWidth: true
                                text: themeItemRoot.modelData
                                color: themeItemRoot.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.builders.small.weight(themeItemRoot.isActive ? Font.Bold : Font.Medium).build()
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        StateLayer {
                            anchors.fill: parent
                            onClicked: Theme.setQylockTheme(themeItemRoot.modelData)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Theme.lockBackend === "hyprlock"
            spacing: Tokens.spacing.small

            StyledText {
                Layout.topMargin: Tokens.spacing.medium
                Layout.bottomMargin: Tokens.spacing.extraSmall
                text: Theme.activeHyprlockConfigs.length > 0 ? qsTr("Hyprlock config") : qsTr("No Hyprlock configs available for current theme")
                font: Tokens.font.title.small
            }

            ButtonRow {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small
                visible: Theme.activeHyprlockConfigs.length > 0

                Repeater {
                    model: Theme.activeHyprlockConfigs

                    IconTextButton {
                        required property string modelData

                        text: modelData
                        font: Tokens.font.body.large
                        isRound: true
                        shapeMorph: true
                        type: Theme.hyprlockConfig === modelData ? IconTextButton.Primary : IconTextButton.Tonal
                        horizontalPadding: Tokens.padding.extraLarge
                        verticalPadding: Tokens.padding.medium
                        onClicked: Theme.setHyprlockConfig(modelData)
                    }
                }
            }
        }
    }
}
