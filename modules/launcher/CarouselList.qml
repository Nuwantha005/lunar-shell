pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content
    required property string carouselType

    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2
    property bool wasCancelled: false
    property bool alreadySelected: false

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    function selectCurrent(): void {
        if (alreadySelected)
            return;
        alreadySelected = true;
        if (!currentItem)
            return;
        const data = (currentItem as CarouselItem).modelData;
        if (!data)
            return;

        if (root.carouselType === "theme") {
            Theme.setTheme(data.themeName);
        } else if (root.carouselType === "pfp") {
            Theme.setPfp(data.path);
        } else if (root.carouselType === "lock") {
            Wallpapers.setLockWallpaper(data.path);
        } else if (root.carouselType === "wallpaper") {
            if (Colours.scheme === "dynamic" && data.path !== Wallpapers.actualCurrent)
                Wallpapers.previewColourLock = true;
            Wallpapers.setWallpaper(data.path);
        }
    }

    // pfpModel removed

    model: ScriptModel {
        id: scriptModel

        readonly property string queryText: {
            const parts = root.search.text.split(" ");
            return parts.slice(1).join(" ").toLowerCase();
        }

        values: {
            const q = queryText;
            if (root.carouselType === "theme") {
                const list = Theme.themesList || [];
                const res = [];
                for (const t of list) {
                    if (!q || t.name.toLowerCase().includes(q)) {
                        res.push({
                            themeName: t.name,
                            displayName: t.name.toUpperCase(),
                            imagePath: t.wallpaper || "",
                            path: t.wallpaper || ""
                        });
                    }
                }
                return res;
            } else if (root.carouselType === "pfp") {
                const list = Theme.queryPfp(q);
                return list.map(p => ({
                    displayName: p.name || p.relativePath || "Unknown",
                    imagePath: p.path,
                    path: p.path
                }));
            } else {
                // "wallpaper" or "lock"
                const list = Wallpapers.query(q);
                return list.map(w => ({
                    displayName: w.relativePath || w.name,
                    imagePath: w.path,
                    path: w.path
                }));
            }
        }

        onValuesChanged: {
            if (root.carouselType === "theme") {
                const idx = values.findIndex(v => v.themeName === Theme.currentTheme);
                root.currentIndex = idx >= 0 ? idx : 0;
            } else if (root.carouselType === "pfp") {
                const selectedPfpPath = Theme.themeData?.selectedPfp ? `${Theme.themePath}/${Theme.themeData.selectedPfp}` : "";
                const idx = values.findIndex(v => v.path === selectedPfpPath);
                root.currentIndex = idx >= 0 ? idx : 0;
            } else if (root.carouselType === "lock") {
                const idx = values.findIndex(v => v.path === Wallpapers.lockWallpaper);
                root.currentIndex = idx >= 0 ? idx : 0;
            } else {
                const idx = values.findIndex(v => v.path === Wallpapers.actualCurrent);
                root.currentIndex = idx >= 0 ? idx : 0;
            }
        }
    }

    Component.onCompleted: {
        if (root.carouselType === "theme") {
            Theme.refreshThemeList();
            const idx = scriptModel.values.findIndex(v => v.themeName === Theme.currentTheme);
            currentIndex = idx >= 0 ? idx : 0;
        } else if (root.carouselType === "pfp") {
            const selectedPfpPath = Theme.themeData?.selectedPfp ? `${Theme.themePath}/${Theme.themeData.selectedPfp}` : "";
            const idx = scriptModel.values.findIndex(v => v.path === selectedPfpPath);
            currentIndex = idx >= 0 ? idx : 0;
        } else if (root.carouselType === "lock") {
            const idx = scriptModel.values.findIndex(v => v.path === Wallpapers.lockWallpaper);
            currentIndex = idx >= 0 ? idx : 0;
        } else {
            const idx = scriptModel.values.findIndex(v => v.path === Wallpapers.actualCurrent);
            currentIndex = idx >= 0 ? idx : 0;
        }
    }

    Component.onDestruction: {
        if (!wasCancelled && !alreadySelected && currentItem) {
            selectCurrent();
        }
        Wallpapers.stopPreview();
    }

    onCurrentItemChanged: {
        if (currentItem) {
            const data = (currentItem as CarouselItem).modelData;
            if (data && data.imagePath && (root.carouselType === "wallpaper" || root.carouselType === "theme")) {
                Wallpapers.preview(data.imagePath);
            }
        }
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: CarouselItem {
        screenState: root.screenState
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                root.decrementCurrentIndex();
            } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                root.incrementCurrentIndex();
            }
        }
    }
}
