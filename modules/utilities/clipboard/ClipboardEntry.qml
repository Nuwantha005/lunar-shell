pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var entry
    property int entryIndex: 0
    required property bool isSelected

    signal selectClicked()
    signal pasteClicked()
    signal deleteClicked()

    implicitHeight: 60
    radius: Tokens.rounding.medium

    color: {
        if (root.isSelected) return Colours.tPalette.m3surfaceContainerHighest;
        if (mouseArea.containsMouse) return Qt.alpha(Colours.palette.m3onSurface, 0.06);
        return "transparent";
    }

    border.width: 0

    Behavior on color {
        CAnim {}
    }

    // Active accent indicator pill on the left
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 24
        radius: 1.5
        color: Colours.palette.m3primary
        visible: root.isSelected
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPositionChanged: mouse => {
        const p = mouseArea.mapToItem(null, mouse.x, mouse.y);
        const last = Clipboard.lastHoverPos;
        Clipboard.lastHoverPos = Qt.point(p.x, p.y);

        // First event after opening is the synthetic one, so just record it
        if (last.x < 0) return;
        // Same window position means the list moved, not the mouse
        if (Math.abs(p.x - last.x) < 1 && Math.abs(p.y - last.y) < 1) return;

        root.selectClicked();
    }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.isSelected ? Tokens.padding.medium + 4 : Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.topMargin: Tokens.padding.small
        anchors.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.medium

        // Thumbnail / Icon container
        StyledRect {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignVCenter
            radius: Tokens.rounding.small
            color: root.isSelected ? Colours.tPalette.m3surfaceContainer : Colours.tPalette.m3surfaceContainerLowest
            clip: true

            Loader {
                anchors.fill: parent
                active: root.entry.isImage && !!Clipboard.cachedImages[root.entry.id]
                sourceComponent: Image {
                    anchors.fill: parent
                    source: "file://" + root.entry.imagePath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 84
                    sourceSize.height: 84
                    visible: status === Image.Ready
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.entry.isImage || !Clipboard.cachedImages[root.entry.id]
                text: {
                    if (root.entry.isImage) return "image";
                    if (root.entry.isUrl) return "link";
                    return "notes";
                }
                color: {
                    if (root.entry.isImage) return Colours.palette.m3primary;
                    if (root.entry.isUrl) return Colours.palette.m3tertiary;
                    return Colours.palette.m3secondary;
                }
                fontStyle: Tokens.font.icon.builders.medium.scale(0.85).build()
            }
        }

        // Text content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: {
                    if (root.entry.isImage) {
                        const dim = root.entry.dimensions ? ` · ${root.entry.dimensions}` : "";
                        return `Image (${root.entry.format.toUpperCase()}${dim})`;
                    }
                    return root.entry.preview.replace(/\s+/g, " ").trim();
                }
                elide: Text.ElideRight
                maximumLineCount: 1
                color: root.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.body.medium
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: Tokens.spacing.small

                // Type Badge
                StyledRect {
                    Layout.fillWidth: false
                    implicitWidth: badgeText.implicitWidth + 8
                    implicitHeight: 18
                    radius: Tokens.rounding.extraSmall
                    color: root.isSelected ? Qt.alpha(Colours.palette.m3primary, 0.2) : Colours.tPalette.m3surfaceContainerHigh

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.entry.format.toUpperCase()
                        font: Tokens.font.label.small
                        color: root.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: {
                        if (root.entry.isImage) {
                            return root.entry.size ? `${root.entry.size}` : "";
                        }
                        if (root.entry.isUrl) {
                            return "URL Link";
                        }
                        return `${root.entry.preview.length} chars`;
                    }
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    opacity: 0.85
                }
            }
        }

        // Quick delete button only on hover
        IconButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            icon: "close"
            type: IconButton.Text
            opacity: mouseArea.containsMouse ? 0.7 : 0
            visible: mouseArea.containsMouse
            onClicked: root.deleteClicked()

            Behavior on opacity {
                Anim {}
            }
        }
    }
}
