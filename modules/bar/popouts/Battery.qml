pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    property int currentLimit: 100

    function setChargeLimit(limit: int): void {
        root.currentLimit = limit;
        Quickshell.execDetached([`${Paths.home}/dotfiles/customScripts/battery-toggle.sh`, String(limit)]);
    }

    spacing: Tokens.spacing.medium
    width: Tokens.sizes.bar.batteryWidth

    Process {
        id: getLimitProc

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null || echo 100"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim(), 10);
                if (val === 60 || val === 80 || val === 100) {
                    root.currentLimit = val;
                }
            }
        }
    }

    Component.onCompleted: {
        getLimitProc.running = true;
    }

    StyledText {
        text: UPower.displayDevice.isLaptopBattery ? qsTr("Remaining: %1%").arg(Math.round(UPower.displayDevice.percentage * 100)) : qsTr("No battery detected")
    }

    StyledText {
        function formatSeconds(s: int, fallback: string): string {
            const day = Math.floor(s / 86400);
            const hr = Math.floor(s / 3600) % 24;
            const min = Math.floor(s / 60) % 60;

            let comps = [];
            if (day > 0)
                comps.push(`${day} days`);
            if (hr > 0)
                comps.push(`${hr} hours`);
            if (min > 0)
                comps.push(`${min} mins`);

            return comps.join(", ") || fallback;
        }

        text: UPower.displayDevice.isLaptopBattery ? qsTr("Time %1: %2").arg(UPower.onBattery ? "remaining" : "until charged").arg(UPower.onBattery ? formatSeconds(UPower.displayDevice.timeToEmpty, "Calculating...") : formatSeconds(UPower.displayDevice.timeToFull, "Fully charged!")) : qsTr("Power profile: %1").arg(PowerProfile.toString(PowerProfiles.profile))
    }

    Loader {
        asynchronous: true
        anchors.horizontalCenter: parent.horizontalCenter

        active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

        height: active ? ((item as Item)?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: child.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: child.implicitHeight + Tokens.padding.large

            color: Colours.palette.m3error
            radius: Tokens.rounding.large

            Column {
                id: child

                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Performance Degraded")
                        color: Colours.palette.m3onError
                        font: Tokens.font.mono.builders.medium.weight(Font.Medium).build()
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Reason: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
                    color: Colours.palette.m3onError
                }
            }
        }
    }

    StyledRect {
        id: profiles

        property string current: {
            const p = PowerProfiles.profile;
            if (p === PowerProfile.PowerSaver)
                return saver.icon;
            if (p === PowerProfile.Performance)
                return perf.icon;
            return balance.icon;
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: saver.implicitHeight + balance.implicitHeight + perf.implicitHeight + Tokens.padding.medium * 2 + Tokens.spacing.largeIncreased * 2
        implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + Tokens.padding.small

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        StyledRect {
            id: indicator

            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
            state: profiles.current

            states: [
                State {
                    name: saver.icon

                    Fill {
                        target: indicator
                        item: saver
                    }
                },
                State {
                    name: balance.icon

                    Fill {
                        target: indicator
                        item: balance
                    }
                },
                State {
                    name: perf.icon

                    Fill {
                        target: indicator
                        item: perf
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }
        }

        Profile {
            id: saver

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.extraSmall

            profile: PowerProfile.PowerSaver
            icon: "energy_savings_leaf"
        }

        Profile {
            id: balance

            anchors.centerIn: parent

            profile: PowerProfile.Balanced
            icon: "balance"
        }

        Profile {
            id: perf

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.extraSmall

            profile: PowerProfile.Performance
            icon: "rocket_launch"
        }
    }

    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        active: UPower.displayDevice.isLaptopBattery
        height: active ? ((item as Item)?.implicitHeight ?? 0) : 0

        sourceComponent: Column {
            spacing: Tokens.spacing.small
            anchors.horizontalCenter: parent.horizontalCenter

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Charge limit")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledRect {
                id: limitRect

                anchors.horizontalCenter: parent.horizontalCenter

                implicitWidth: limit60.implicitWidth + limit80.implicitWidth + limit100.implicitWidth + Tokens.padding.medium * 2 + Tokens.spacing.largeIncreased * 2
                implicitHeight: Math.max(limit60.implicitHeight, limit80.implicitHeight, limit100.implicitHeight) + Tokens.padding.small

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.full

                StyledRect {
                    id: limitIndicator

                    color: Colours.palette.m3primary
                    radius: Tokens.rounding.full
                    state: String(root.currentLimit)

                    states: [
                        State {
                            name: "60"

                            Fill {
                                target: limitIndicator
                                item: limit60
                            }
                        },
                        State {
                            name: "80"

                            Fill {
                                target: limitIndicator
                                item: limit80
                            }
                        },
                        State {
                            name: "100"

                            Fill {
                                target: limitIndicator
                                item: limit100
                            }
                        }
                    ]

                    transitions: Transition {
                        AnchorAnim {}
                    }
                }

                LimitButton {
                    id: limit60

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.padding.extraSmall

                    limit: 60
                    label: "60%"
                }

                LimitButton {
                    id: limit80

                    anchors.centerIn: parent

                    limit: 80
                    label: "80%"
                }

                LimitButton {
                    id: limit100

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.extraSmall

                    limit: 100
                    label: "100%"
                }
            }
        }
    }

    component Fill: AnchorChanges {
        required property Item item
        required property Item target

        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component Profile: Item {
        required property string icon
        required property int profile

        implicitWidth: icon.implicitHeight + Tokens.padding.small
        implicitHeight: icon.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: profiles.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: PowerProfiles.profile = parent.profile
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent

            text: parent.icon
            fontStyle: Tokens.font.icon.large
            color: profiles.current === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: profiles.current === text ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    component LimitButton: Item {
        required property int limit
        required property string label

        implicitWidth: label.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: label.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: root.currentLimit === parent.limit ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: root.setChargeLimit(parent.limit)
        }

        StyledText {
            id: label

            anchors.centerIn: parent

            text: parent.label
            font: Tokens.font.label.medium
            color: root.currentLimit === parent.limit ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            animate: true
        }
    }
}
