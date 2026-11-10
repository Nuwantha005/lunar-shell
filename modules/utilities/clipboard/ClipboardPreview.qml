pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

Item {
    id: root

    property var entry
    signal close()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.large

        // Top Header & Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: {
                    if (!root.entry) return "visibility";
                    if (root.entry.isImage) return "image";
                    if (root.entry.isUrl) return "link";
                    return "description";
                }
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: {
                    if (!root.entry) return "Preview";
                    if (root.entry.isImage) return "Image Preview";
                    if (root.entry.isUrl) return "Link Preview";
                    return "Text Preview";
                }
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }

            // Entry ID / format badge
            StyledRect {
                visible: !!root.entry
                implicitWidth: idBadge.implicitWidth + 12
                implicitHeight: 22
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StyledText {
                    id: idBadge
                    anchors.centerIn: parent
                    text: root.entry ? `#${root.entry.id} · ${root.entry.format.toUpperCase()}` : ""
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Action Buttons
            RowLayout {
                visible: !!root.entry
                spacing: Tokens.spacing.small

                IconTextButton {
                    text: "Paste"
                    icon: "content_paste"
                    type: ButtonBase.Filled
                    onClicked: {
                        if (root.entry) {
                            Clipboard.pasteEntry(root.entry.id);
                            root.close();
                        }
                    }
                }

                IconButton {
                    icon: "content_copy"
                    type: IconButton.Tonal
                    onClicked: {
                        if (root.entry) {
                            Clipboard.copyEntry(root.entry.id);
                        }
                    }
                }

                IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    onClicked: {
                        if (root.entry) {
                            Clipboard.deleteEntry(root.entry.id, root.entry.raw);
                        }
                    }
                }
            }
        }

        // Main Preview Body
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerLowest
            border.color: Colours.palette.m3outlineVariant
            border.width: 1
            clip: true

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.entry
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "content_paste_off"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.large.scale(1.8).build()
                    opacity: 0.5
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No entry selected"
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Select an item from the history to preview"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outline
                }
            }

            // Image Preview
            Item {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                visible: !!root.entry && root.entry.isImage

                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.bottomMargin: 38
                    source: Clipboard.previewImagePath
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true

                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        Anim {}
                    }
                }

                // Loading indicator for image
                LoadingIndicator {
                    anchors.centerIn: parent
                    visible: Clipboard.isPreviewLoading || previewImage.status === Image.Loading
                }

                // Image details footer bar
                StyledRect {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: Tokens.padding.small
                    implicitWidth: imgMetaText.implicitWidth + 24
                    implicitHeight: 30
                    radius: Tokens.rounding.full
                    color: Qt.rgba(0, 0, 0, 0.65)
                    visible: previewImage.status === Image.Ready

                    StyledText {
                        id: imgMetaText
                        anchors.centerIn: parent
                        text: {
                            if (!root.entry) return "";
                            const parts = [];
                            if (root.entry.dimensions) parts.push(root.entry.dimensions);
                            if (root.entry.size) parts.push(root.entry.size);
                            parts.push(root.entry.format.toUpperCase());
                            return parts.join(" · ");
                        }
                        font: Tokens.font.label.medium
                        color: "#ffffff"
                    }
                }
            }

            // URL Preview
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 64, 480)
                visible: !!root.entry && root.entry.isUrl
                spacing: Tokens.spacing.large

                StyledRect {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3tertiaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "open_in_browser"
                        color: Colours.palette.m3onTertiaryContainer
                        fontStyle: Tokens.font.icon.large
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.entry && root.entry.isUrl ? root.entry.preview.trim() : ""
                    font: Tokens.font.body.large
                    color: Colours.palette.m3primary
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    IconTextButton {
                        text: "Open in Browser"
                        icon: "launch"
                        type: ButtonBase.Filled
                        onClicked: {
                            if (root.entry) {
                                Quickshell.execDetached(["xdg-open", root.entry.preview.trim()]);
                                root.close();
                            }
                        }
                    }

                    IconTextButton {
                        text: "Copy Link"
                        icon: "link"
                        type: ButtonBase.Tonal
                        onClicked: {
                            if (root.entry) {
                                Clipboard.copyEntry(root.entry.id);
                            }
                        }
                    }
                }
            }

            // Text Preview
            Item {
                anchors.fill: parent
                visible: !!root.entry && !root.entry.isImage && !root.entry.isUrl

                Flickable {
                    id: textFlickable
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.bottomMargin: 36
                    contentWidth: width
                    contentHeight: textDisplay.implicitHeight
                    clip: true

                    TextEdit {
                        id: textDisplay
                        width: parent.width
                        text: Clipboard.previewText || (root.entry ? root.entry.preview : "")
                        wrapMode: TextEdit.Wrap
                        font: Tokens.font.mono.small
                        color: Colours.palette.m3onSurface
                        readOnly: true
                        selectByMouse: true
                        selectionColor: Colours.palette.m3primary
                        selectedTextColor: Colours.palette.m3onPrimary
                    }
                }

                StyledScrollBar {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.topMargin: Tokens.padding.large
                    anchors.bottomMargin: 36
                    anchors.rightMargin: 4
                    flickable: textFlickable
                }

                // Text stats footer bar
                StyledRect {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 32
                    color: Colours.tPalette.m3surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        spacing: Tokens.spacing.large

                        StyledText {
                            text: {
                                const t = textDisplay.text || "";
                                const lines = t.split("\n").length;
                                const words = t.trim() ? t.trim().split(/\s+/).length : 0;
                                const chars = t.length;
                                return `${lines} lines · ${words} words · ${chars} characters`;
                            }
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        LoadingIndicator {
                            visible: Clipboard.isPreviewLoading
                        }
                    }
                }
            }
        }
    }
}
