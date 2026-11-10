pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    property var entries: []
    property var filteredEntries: []
    property string searchText: ""
    property int selectedIndex: 0
    readonly property var currentEntry: selectedIndex >= 0 && selectedIndex < filteredEntries.length ? filteredEntries[selectedIndex] : null

    property var cachedImages: ({})
    property string previewText: ""
    property string previewImagePath: ""
    property bool isPreviewLoading: false
    property bool isListLoading: false

    readonly property string cacheDir: Paths.cache + "/clipboard_previews"
    readonly property string helperScript: Quickshell.shellPath("scripts/clipboard-helper.sh")

    function refresh(): void {
        selectedIndex = 0;
        searchText = "";
        previewText = "";
        previewImagePath = "";
        isListLoading = true;
        checkCacheProc.running = false;
        checkCacheProc.running = true;
        listProc.running = false;
        listProc.running = true;
    }

    function parseEntries(rawText: string): void {
        const lines = rawText.split("\n");
        const parsed = [];
        const binPat = /^\[\[ binary data (.+?)\s+([a-zA-Z0-9]+)(?:\s+([0-9]+x[0-9]+))?\s*\]\]$/;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (!line) continue;

            const tabIdx = line.indexOf("\t");
            if (tabIdx === -1) continue;

            const id = line.substring(0, tabIdx).trim();
            const preview = line.substring(tabIdx + 1);

            const binMatch = preview.match(binPat);
            if (binMatch) {
                const size = binMatch[1] || "";
                const format = (binMatch[2] || "").toLowerCase();
                const dimensions = binMatch[3] || "";
                const isImage = ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif"].includes(format);

                parsed.push({
                    id: id,
                    raw: line,
                    preview: preview,
                    isBinary: true,
                    isImage: isImage,
                    isUrl: false,
                    format: format,
                    size: size,
                    dimensions: dimensions,
                    imagePath: `${cacheDir}/${id}.${format}`
                });
            } else {
                const trimmed = preview.trim();
                const isUrl = /^https?:\/\/\S+/i.test(trimmed);

                parsed.push({
                    id: id,
                    raw: line,
                    preview: preview,
                    isBinary: false,
                    isImage: false,
                    isUrl: isUrl,
                    format: isUrl ? "url" : "text",
                    size: "",
                    dimensions: "",
                    imagePath: ""
                });
            }
        }

        entries = parsed;
        filterEntries();
        isListLoading = false;
    }

    function filterEntries(): void {
        const query = searchText.trim().toLowerCase();
        if (!query) {
            filteredEntries = entries;
        } else {
            filteredEntries = entries.filter(e => {
                if (e.id.toLowerCase().includes(query)) return true;
                if (e.preview.toLowerCase().includes(query)) return true;
                if (e.format && e.format.toLowerCase().includes(query)) return true;
                if (e.dimensions && e.dimensions.toLowerCase().includes(query)) return true;
                return false;
            });
        }

        if (selectedIndex >= filteredEntries.length) {
            selectedIndex = Math.max(0, filteredEntries.length - 1);
        } else if (selectedIndex < 0 && filteredEntries.length > 0) {
            selectedIndex = 0;
        }
        triggerPreview();
    }

    function setSearch(text: string): void {
        searchText = text;
        selectedIndex = 0;
        filterEntries();
    }

    function selectIndex(idx: int): void {
        if (idx >= 0 && idx < filteredEntries.length) {
            selectedIndex = idx;
            triggerPreview();
        }
    }

    function selectNext(): void {
        if (filteredEntries.length === 0) return;
        selectedIndex = (selectedIndex + 1) % filteredEntries.length;
        triggerPreview();
    }

    function selectPrev(): void {
        if (filteredEntries.length === 0) return;
        selectedIndex = (selectedIndex - 1 + filteredEntries.length) % filteredEntries.length;
        triggerPreview();
    }

    function triggerPreview(): void {
        previewDebounceTimer.restart();
    }

    function doPreview(): void {
        const entry = currentEntry;
        if (!entry) {
            previewText = "";
            previewImagePath = "";
            isPreviewLoading = false;
            return;
        }

        if (entry.isImage) {
            previewText = "";
            if (cachedImages[entry.id]) {
                previewImagePath = "file://" + entry.imagePath;
                isPreviewLoading = false;
            } else {
                previewImagePath = "";
                isPreviewLoading = true;
                decodeImageProc.running = false;
                decodeImageProc.targetImagePath = entry.imagePath;
                decodeImageProc.targetEntryId = entry.id;
                decodeImageProc.command = [helperScript, "decode-image", entry.id, entry.imagePath];
                decodeImageProc.running = true;
            }
        } else {
            previewImagePath = "";
            previewText = entry.preview;
            isPreviewLoading = true;
            decodeTextProc.running = false;
            decodeTextProc.command = [helperScript, "decode-text", entry.id];
            decodeTextProc.running = true;
        }
    }

    function pasteEntry(id: string): void {
        if (!id) return;
        Quickshell.execDetached([helperScript, "paste", id]);
    }

    function copyEntry(id: string): void {
        if (!id) return;
        Quickshell.execDetached([helperScript, "copy", id]);
    }

    function deleteEntry(id: string, raw: string): void {
        if (!id) return;
        Quickshell.execDetached([helperScript, "delete", raw || id]);
        entries = entries.filter(e => e.id !== id);
        filterEntries();
    }

    function clearHistory(): void {
        Quickshell.execDetached([helperScript, "wipe"]);
        cachedImages = ({});
        entries = [];
        filteredEntries = [];
        selectedIndex = -1;
        previewText = "";
        previewImagePath = "";
    }

    Timer {
        id: previewDebounceTimer
        interval: 40
        repeat: false
        onTriggered: root.doPreview()
    }

    Process {
        id: checkCacheProc
        command: ["ls", "-1", root.cacheDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.split("\n");
                const map = {};
                for (let i = 0; i < files.length; i++) {
                    const f = files[i].trim();
                    if (!f) continue;
                    const dot = f.lastIndexOf(".");
                    const id = dot !== -1 ? f.substring(0, dot) : f;
                    map[id] = true;
                }
                root.cachedImages = map;
            }
        }
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseEntries(text)
        }
    }

    Process {
        id: decodeTextProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    root.previewText = text;
                }
                root.isPreviewLoading = false;
            }
        }
    }

    Process {
        id: decodeImageProc
        property string targetImagePath: ""
        property string targetEntryId: ""
        onExited: (code, status) => {
            if (code === 0 && targetImagePath) {
                const map = Object.assign({}, root.cachedImages);
                if (targetEntryId) {
                    map[targetEntryId] = true;
                }
                root.cachedImages = map;
                if (root.currentEntry && root.currentEntry.id === targetEntryId) {
                    root.previewImagePath = "file://" + targetImagePath;
                }
            }
            root.isPreviewLoading = false;
        }
    }

    Component.onCompleted: {
        refresh();
    }
}
