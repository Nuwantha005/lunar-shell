pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

FocusScope {
    id: root

    signal close()

    focus: true

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            Clipboard.selectNext();
            listView.positionViewAtIndex(Clipboard.selectedIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            Clipboard.selectPrev();
            listView.positionViewAtIndex(Clipboard.selectedIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (Clipboard.currentEntry) {
                Clipboard.pasteEntry(Clipboard.currentEntry.id);
                root.close();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete) {
            if (Clipboard.currentEntry) {
                Clipboard.deleteEntry(Clipboard.currentEntry.id, Clipboard.currentEntry.raw);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchBar.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
            if (Clipboard.currentEntry) {
                Clipboard.copyEntry(Clipboard.currentEntry.id);
                root.close();
            }
            event.accepted = true;
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surface
        border.color: Colours.palette.m3outlineVariant
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left Pane (Sidebar & List)
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: 380
                Layout.minimumWidth: 380
                Layout.maximumWidth: 380
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Tokens.spacing.medium

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.large
                        Layout.rightMargin: Tokens.padding.large
                        Layout.topMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "content_paste"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            text: "Clipboard History"
                            font: Tokens.font.title.medium
                            color: Colours.palette.m3onSurface
                        }

                        StyledRect {
                            implicitWidth: countText.implicitWidth + 12
                            implicitHeight: 20
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primaryContainer

                            StyledText {
                                id: countText
                                anchors.centerIn: parent
                                text: `${Clipboard.filteredEntries.length}`
                                font: Tokens.font.label.small
                                color: Colours.palette.m3onPrimaryContainer
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        IconButton {
                            icon: "refresh"
                            type: IconButton.Text
                            onClicked: Clipboard.refresh()
                        }

                        IconButton {
                            icon: "delete_sweep"
                            type: IconButton.Text
                            onClicked: Clipboard.clearHistory()
                        }
                    }

                    // Search Bar
                    Item {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.large
                        Layout.rightMargin: Tokens.padding.large
                        implicitHeight: searchBar.implicitHeight

                        SearchBar {
                            id: searchBar
                            anchors.fill: parent
                            placeholderText: "Search history... (Ctrl+F)"
                            onTextChanged: Clipboard.setSearch(text)

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    Clipboard.selectNext();
                                    listView.positionViewAtIndex(Clipboard.selectedIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    Clipboard.selectPrev();
                                    listView.positionViewAtIndex(Clipboard.selectedIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (Clipboard.currentEntry) {
                                        Clipboard.pasteEntry(Clipboard.currentEntry.id);
                                        root.close();
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root.close();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    // Entries List
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: Tokens.padding.large
                        Layout.rightMargin: Tokens.padding.large
                        clip: true

                        StyledListView {
                            id: listView
                            anchors.fill: parent
                            clip: true
                            spacing: 4
                            model: Clipboard.filteredEntries

                            delegate: ClipboardEntry {
                                required property var modelData
                                required property int index

                                width: listView.width
                                entry: modelData
                                entryIndex: index
                                isSelected: Clipboard.selectedIndex === index

                                onSelectClicked: {
                                    Clipboard.selectIndex(index);
                                }
                                onPasteClicked: {
                                    Clipboard.pasteEntry(modelData.id);
                                    root.close();
                                }
                                onDeleteClicked: {
                                    Clipboard.deleteEntry(modelData.id, modelData.raw);
                                }
                            }
                        }

                        StyledScrollBar {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: -4
                            flickable: listView
                        }

                        // Empty indicator
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: Clipboard.filteredEntries.length === 0
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "inbox"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.large
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Clipboard.searchText ? "No matching entries" : "Clipboard is empty"
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3outline
                            }
                        }
                    }

                    // Navigation hints footer
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        color: Colours.tPalette.m3surfaceContainerHigh

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.large
                            anchors.rightMargin: Tokens.padding.large

                            StyledText {
                                text: "↑↓ Navigate  •  ↵ Paste  •  Del Delete  •  Esc Close"
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }
                    }
                }
            }

            // Vertical divider
            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: 1
                width: 1
                color: Colours.palette.m3outlineVariant
            }

            // Right Pane (Detailed Preview)
            ClipboardPreview {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                entry: Clipboard.currentEntry
                onClose: root.close()
            }
        }
    }
}
