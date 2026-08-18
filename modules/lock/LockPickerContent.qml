pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

FocusScope {
    id: root

    signal close
    signal applied

    readonly property list<string> backends: ["caelestia", "hyprlock", "qylock", "custom-qylock"]
    readonly property list<string> qylockThemes: [
        "Genshin", "R1999_1", "R1999_2", "clockwork/neo-orbital", "clockwork/orbital", "clockwork/tape", "dog-samurai", "enfield", "field", "forest",
        "girl-coffee", "girl-pillow", "last-of-us", "man-bicycle", "material-you", "minecraft",
        "nier-automata", "ninesols", "ninja_gaiden", "nothing", "osu", "osumania", "pixel-coffee",
        "pixel-cyberpunk", "pixel-dusk-city", "pixel-emerald", "pixel-hollowknight", "pixel-munchlax",
        "pixel-night-city", "pixel-rainyroom", "pixel-sakura", "pixel-skyscrapers", "pixel-waterfall",
        "star-rail", "sword", "terraria", "windows_7", "winter", "women-umbrella", "wuwa"
    ]

    property int activeTab: 0
    property int qylockIndex: 0
    property int wallpaperIndex: 0
    property int pfpIndex: 0

    readonly property var wallpaperList: Wallpapers.list || []
    readonly property int wallpaperCount: wallpaperList.length > 0 ? wallpaperList.length : 1

    readonly property var pfpList: Theme.queryPfp("") || []
    readonly property int pfpCount: pfpList.length > 0 ? pfpList.length : 1

    function getQylockPreview(name: string): string {
        if (!name) return "";
        const filenames = {
            "Genshin": "genshin.gif",
            "R1999_1": "R1999_1.gif",
            "R1999_2": "R1999_2.gif",
            "clockwork/neo-orbital": "clockwork.gif",
            "clockwork/orbital": "clockwork.gif",
            "clockwork/tape": "clockwork.gif",
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

    function initIndices(): void {
        const currBackend = Theme.lockBackend || "caelestia";
        const bIdx = backends.indexOf(currBackend);
        if (bIdx >= 0) activeTab = bIdx;

        const currQTheme = Theme.qylockTheme || "nier-automata";
        const qIdx = qylockThemes.indexOf(currQTheme);
        if (qIdx >= 0) qylockIndex = qIdx;

        if (wallpaperList.length > 0) {
            const currentWall = Wallpapers.lockWallpaper || Wallpapers.actualCurrent;
            const wIdx = wallpaperList.findIndex(w => w.path === currentWall);
            if (wIdx >= 0) wallpaperIndex = wIdx;
        }

        if (pfpList.length > 0 && Theme.themeData?.selectedPfp) {
            const selectedPfpPath = `${Theme.themePath}/${Theme.themeData.selectedPfp}`;
            const pIdx = pfpList.findIndex(p => p.path === selectedPfpPath);
            if (pIdx >= 0) pfpIndex = pIdx;
        }
    }

    function applySelection(): void {
        const selectedBackend = backends[activeTab];
        Theme.setLockBackend(selectedBackend);

        if (selectedBackend === "qylock" || selectedBackend === "custom-qylock") {
            const selectedTheme = qylockThemes[qylockIndex];
            Theme.setQylockTheme(selectedTheme);
        }

        if (selectedBackend === "custom-qylock" || selectedBackend === "hyprlock") {
            if (wallpaperList.length > 0 && wallpaperIndex >= 0 && wallpaperIndex < wallpaperList.length) {
                Theme.setLockWallpaper(wallpaperList[wallpaperIndex].path);
            }
        }

        if (selectedBackend === "caelestia" || selectedBackend === "hyprlock") {
            if (pfpList.length > 0 && pfpIndex >= 0 && pfpIndex < pfpList.length) {
                Theme.setPfp(pfpList[pfpIndex].path);
            }
        }

        root.applied();
        root.close();
    }

    Component.onCompleted: {
        initIndices();
        root.forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) {
            if (event.modifiers & Qt.ShiftModifier) {
                activeTab = (activeTab - 1 + backends.length) % backends.length;
            } else {
                activeTab = (activeTab + 1) % backends.length;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (activeTab === 2) {
                qylockIndex = (qylockIndex - 1 + qylockThemes.length) % qylockThemes.length;
            } else if (activeTab === 1 || activeTab === 3) {
                if (wallpaperCount > 0) {
                    wallpaperIndex = (wallpaperIndex - 1 + wallpaperCount) % wallpaperCount;
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (activeTab === 2) {
                qylockIndex = (qylockIndex + 1) % qylockThemes.length;
            } else if (activeTab === 1 || activeTab === 3) {
                if (wallpaperCount > 0) {
                    wallpaperIndex = (wallpaperIndex + 1) % wallpaperCount;
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (activeTab === 0 || activeTab === 1) {
                if (pfpCount > 0) {
                    pfpIndex = (pfpIndex - 1 + pfpCount) % pfpCount;
                }
            } else if (activeTab === 3) {
                qylockIndex = (qylockIndex - 1 + qylockThemes.length) % qylockThemes.length;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (activeTab === 0 || activeTab === 1) {
                if (pfpCount > 0) {
                    pfpIndex = (pfpIndex + 1) % pfpCount;
                }
            } else if (activeTab === 3) {
                qylockIndex = (qylockIndex + 1) % qylockThemes.length;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            applySelection();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surface
        radius: Tokens.rounding.large
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Instant Lock Screen Picker")
                        font: Tokens.font.title.large
                        color: Colours.palette.m3onSurface
                    }

                    Item { Layout.fillWidth: true }

                    StyledRect {
                        implicitWidth: helpText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: helpText.implicitHeight + Tokens.padding.small * 2
                        color: Colours.tPalette.m3surfaceContainerHigh
                        radius: Tokens.rounding.full

                        StyledText {
                            id: helpText
                            anchors.centerIn: parent
                            text: qsTr("Tab: Switch Tab • ←/→: Theme/Wall • ↑/↓: Pfp/Theme • Enter: Apply • Esc: Exit")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                // 4 Backend Tabs
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.backends

                        IconTextButton {
                            required property string modelData
                            required property int index

                            text: modelData === "custom-qylock" ? qsTr("Custom Qylock") : (modelData.charAt(0).toUpperCase() + modelData.slice(1))
                            font: Tokens.font.body.large
                            isRound: true
                            shapeMorph: true
                            type: root.activeTab === index ? IconTextButton.Primary : IconTextButton.Tonal
                            horizontalPadding: Tokens.padding.extraLarge
                            verticalPadding: Tokens.padding.medium
                            onClicked: {
                                root.activeTab = index;
                                root.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Main Preview Display Area
            Item {
                id: mainDisplayArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property real maxPreviewW: width * 0.65
                readonly property real maxPreviewH: height - 50
                readonly property real targetW: Math.min(maxPreviewW, maxPreviewH * (16.0 / 9.0))
                readonly property real targetH: targetW * (9.0 / 16.0)

                // Qylock Theme Carousel View (activeTab === 2)
                Item {
                    id: qylockTab
                    anchors.fill: parent
                    visible: root.activeTab === 2

                    // Active Theme Card (Center - Main Display)
                    Item {
                        id: centerCard
                        anchors.centerIn: parent
                        width: mainDisplayArea.targetW
                        height: mainDisplayArea.targetH

                        readonly property string currentTheme: root.qylockThemes[root.qylockIndex]
                        readonly property bool isSelectedInConfig: Theme.qylockTheme === currentTheme

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer
                            border.width: 3
                            border.color: Colours.palette.m3primary

                            AnimatedImage {
                                anchors.fill: parent
                                source: root.getQylockPreview(centerCard.currentTheme)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            StyledRect {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Tokens.padding.medium
                                visible: centerCard.isSelectedInConfig
                                implicitWidth: 32
                                implicitHeight: 32
                                color: Colours.palette.m3primary
                                radius: Tokens.rounding.full

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "check"
                                    color: Colours.palette.m3onPrimary
                                    fontStyle: Tokens.font.icon.medium
                                }
                            }
                        }
                    }

                    // Label below center card
                    RowLayout {
                        anchors.top: centerCard.bottom
                        anchors.topMargin: Tokens.spacing.small
                        anchors.horizontalCenter: centerCard.horizontalCenter
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "lock"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            text: centerCard.currentTheme
                            font: Tokens.font.title.medium
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: `(${root.qylockIndex + 1} / ${root.qylockThemes.length})`
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Previous Theme Card (Left)
                    Item {
                        id: prevCard
                        anchors.right: centerCard.left
                        anchors.rightMargin: Tokens.spacing.medium
                        anchors.verticalCenter: centerCard.verticalCenter
                        width: Math.round(mainDisplayArea.targetW * 0.22)
                        height: Math.round(mainDisplayArea.targetH * 0.22)
                        opacity: 0.45

                        readonly property int prevIdx: (root.qylockIndex - 1 + root.qylockThemes.length) % root.qylockThemes.length
                        readonly property string prevTheme: root.qylockThemes[prevIdx]

                        Behavior on opacity { Anim {} }

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.medium
                            color: Colours.tPalette.m3surfaceContainer

                            AnimatedImage {
                                anchors.fill: parent
                                source: root.getQylockPreview(prevCard.prevTheme)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.qylockIndex = (root.qylockIndex - 1 + root.qylockThemes.length) % root.qylockThemes.length
                        }
                    }

                    // Next Theme Card (Right)
                    Item {
                        id: nextCard
                        anchors.left: centerCard.right
                        anchors.leftMargin: Tokens.spacing.medium
                        anchors.verticalCenter: centerCard.verticalCenter
                        width: Math.round(mainDisplayArea.targetW * 0.22)
                        height: Math.round(mainDisplayArea.targetH * 0.22)
                        opacity: 0.45

                        readonly property int nextIdx: (root.qylockIndex + 1) % root.qylockThemes.length
                        readonly property string nextTheme: root.qylockThemes[nextIdx]

                        Behavior on opacity { Anim {} }

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.medium
                            color: Colours.tPalette.m3surfaceContainer

                            AnimatedImage {
                                anchors.fill: parent
                                source: root.getQylockPreview(nextCard.nextTheme)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.qylockIndex = (root.qylockIndex + 1) % root.qylockThemes.length
                        }
                    }
                }

                // Caelestia Lock Preview (activeTab === 0)
                Item {
                    id: caelestiaTab
                    anchors.fill: parent
                    visible: root.activeTab === 0

                    Item {
                        id: caelestiaCard
                        anchors.centerIn: parent
                        width: mainDisplayArea.targetW
                        height: mainDisplayArea.targetH

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer

                            Image {
                                anchors.fill: parent
                                source: Wallpapers.lockWallpaper || Wallpapers.current
                                fillMode: Image.PreserveAspectCrop
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.medium

                                StyledClippingRect {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 90
                                    implicitHeight: 90
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3surface

                                    Image {
                                        anchors.fill: parent
                                        source: root.pfpList.length > 0 && root.pfpIndex < root.pfpList.length ? root.pfpList[root.pfpIndex].path : ""
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Caelestia Session Lock"
                                    font: Tokens.font.title.medium
                                    color: Colours.palette.m3onSurface
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.top: caelestiaCard.bottom
                        anchors.topMargin: Tokens.spacing.small
                        anchors.horizontalCenter: caelestiaCard.horizontalCenter
                        text: qsTr("PFP: %1 (%2 / %3)").arg(root.pfpList.length > 0 && root.pfpIndex < root.pfpList.length ? root.pfpList[root.pfpIndex].displayName || root.pfpList[root.pfpIndex].name || "Default" : "Default").arg(root.pfpCount > 0 ? root.pfpIndex + 1 : 0).arg(root.pfpCount)
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // Hyprlock Preview (activeTab === 1)
                Item {
                    id: hyprlockTab
                    anchors.fill: parent
                    visible: root.activeTab === 1

                    Item {
                        id: hyprlockCard
                        anchors.centerIn: parent
                        width: mainDisplayArea.targetW
                        height: mainDisplayArea.targetH

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer

                            Image {
                                anchors.fill: parent
                                source: root.wallpaperList.length > 0 && root.wallpaperIndex < root.wallpaperList.length ? root.wallpaperList[root.wallpaperIndex].path : Wallpapers.lockWallpaper
                                fillMode: Image.PreserveAspectCrop
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.medium

                                StyledClippingRect {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 80
                                    implicitHeight: 80
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3surface

                                    Image {
                                        anchors.fill: parent
                                        source: root.pfpList.length > 0 && root.pfpIndex < root.pfpList.length ? root.pfpList[root.pfpIndex].path : ""
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Hyprlock"
                                    font: Tokens.font.title.medium
                                    color: Colours.palette.m3onSurface
                                }
                            }
                        }
                    }

                    RowLayout {
                        anchors.top: hyprlockCard.bottom
                        anchors.topMargin: Tokens.spacing.small
                        anchors.horizontalCenter: hyprlockCard.horizontalCenter
                        spacing: Tokens.spacing.large

                        StyledText {
                            text: qsTr("Wallpaper: %1 / %2").arg(root.wallpaperCount > 0 ? root.wallpaperIndex + 1 : 0).arg(root.wallpaperCount)
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: qsTr("PFP: %1 / %2").arg(root.pfpCount > 0 ? root.pfpIndex + 1 : 0).arg(root.pfpCount)
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                // Custom Qylock Preview (activeTab === 3)
                Item {
                    id: customQylockTab
                    anchors.fill: parent
                    visible: root.activeTab === 3

                    readonly property string activeWallPath: root.wallpaperList.length > 0 && root.wallpaperIndex < root.wallpaperList.length ? root.wallpaperList[root.wallpaperIndex].path : Wallpapers.lockWallpaper
                    readonly property bool isVideoWall: activeWallPath.endsWith(".mp4") || activeWallPath.endsWith(".webm") || activeWallPath.endsWith(".mkv")

                    Item {
                        id: customQylockCard
                        anchors.centerIn: parent
                        width: mainDisplayArea.targetW
                        height: mainDisplayArea.targetH

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer

                            Image {
                                anchors.fill: parent
                                visible: !customQylockTab.isVideoWall
                                source: customQylockTab.activeWallPath
                                fillMode: Image.PreserveAspectCrop
                            }

                            AnimatedImage {
                                anchors.fill: parent
                                opacity: 0.85
                                source: root.getQylockPreview(root.qylockThemes[root.qylockIndex])
                                fillMode: Image.PreserveAspectCrop
                            }
                        }
                    }

                    RowLayout {
                        anchors.top: customQylockCard.bottom
                        anchors.topMargin: Tokens.spacing.small
                        anchors.horizontalCenter: customQylockCard.horizontalCenter
                        spacing: Tokens.spacing.large

                        StyledText {
                            text: qsTr("Wallpaper: %1 (%2 / %3)").arg(root.wallpaperList.length > 0 && root.wallpaperIndex < root.wallpaperList.length ? root.wallpaperList[root.wallpaperIndex].displayName || "Wall" : "Wall").arg(root.wallpaperCount > 0 ? root.wallpaperIndex + 1 : 0).arg(root.wallpaperCount)
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: qsTr("Theme: %1 (%2 / %3)").arg(root.qylockThemes[root.qylockIndex]).arg(root.qylockIndex + 1).arg(root.qylockThemes.length)
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }

            // Footer Section
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Backend: %1").arg(root.backends[root.activeTab])
                    font: Tokens.font.label.large
                    color: Colours.palette.m3primary
                }

                Item { Layout.fillWidth: true }

                IconTextButton {
                    text: qsTr("Cancel")
                    font: Tokens.font.body.large
                    type: IconTextButton.Tonal
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: root.close()
                }

                IconTextButton {
                    icon: "check"
                    text: qsTr("Apply")
                    font: Tokens.font.body.large
                    type: IconTextButton.Primary
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: root.applySelection()
                }
            }
        }
    }
}
