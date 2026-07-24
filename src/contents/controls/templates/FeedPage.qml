// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KAC
import io.github.micro.piqi
import ".."

/*
    Required implementations by derived pages:
    - refresh() function implemented
*/
Kirigami.ScrollablePage {
    id: fp

    default property list<Item> contentItems
    property alias filterSelections: filterRow.children // TODO: Simplify, use KirigamiAddons.SegmentedButton
    property bool loading: false
    property Illusts feed

    supportsRefreshing: true

    function fetchNext() {
        if ((feed?.nextUrl ?? "") == "") {
            loading = false;
            return;
        }

        feed.NextFeed().then(() => {
            // Cache.SynchroniseIllusts(newFeed.illusts);
            // feed.Extend(newFeed);
            loading = false;
        });
    }

    Connections {
        target: fp.flickable

        function onAtYEndChanged(): void {
            if (!fp.flickable.atYEnd || fp.loading)
                return;

            fp.loading = true;
            fp.fetchNext();
        }
    }

    header: Controls.Control {
        padding: Kirigami.Units.largeSpacing

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    right: parent.right
                }
            }
        }

        contentItem: RowLayout {
            id: filterRow
            spacing: Kirigami.Units.largeSpacing
        }
    }

    GridView {
        id: gv

        leftMargin: Kirigami.Units.gridUnit
        rightMargin: Kirigami.Units.gridUnit
        topMargin: Kirigami.Units.gridUnit
        bottomMargin: Kirigami.Units.gridUnit

        cellWidth: 175 + Kirigami.Units.gridUnit // width
        cellHeight: 205 + 45 + Kirigami.Units.gridUnit // top height + bottom height

        model: fp.feed
        delegate: IllustrationButton {}

        header: Item {
            width: gv.width - Kirigami.Units.gridUnit * 2
            implicitHeight: prefeed.implicitHeight + Kirigami.Units.gridUnit

            ColumnLayout {
                id: prefeed
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: Kirigami.Units.largeSpacing

                children: fp.contentItems
            }
        }

        KAC.FloatingButton {
            opacity: fp.flickable.contentY > fp.flickable.originY
            visible: opacity > 0

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit
            }

            action: Kirigami.Action {
                id: returnAction
                icon.name: "arrow-up"
                icon.height: Kirigami.Units.iconSizes.medium
                icon.width: Kirigami.Units.iconSizes.medium
                onTriggered: {
                    autoscrollbeh.enabled = true
                    gv.contentY = -30
                    autoscrollbeh.enabled = false
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }
        Behavior on contentY {
            id: autoscrollbeh
            enabled: false

            SmoothedAnimation {
                duration: 225
            }
        }
    }

    footer: Item {
        Kirigami.AbstractCard {
            z: 5
            visible: fp.loading

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit
            }

            contentItem: Controls.ProgressBar {
                indeterminate: true
                anchors.fill: parent
            }
        }
    }

    ColumnLayout {
        visible: (fp.feed?.rowCount() ?? 0) == 0
        anchors.centerIn: parent

        Kirigami.Icon {
            Layout.preferredWidth: fp.width * 0.25
            Layout.preferredHeight: width

            source: "folder-crash-symbolic"
            color: Kirigami.Theme.negativeBackgroundColor
        }

        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter

            text: i18n("Failed to load")
            color: Kirigami.Theme.negativeTextColor
        }

        /* TODO: Add reload feature once Piki can detect whether feed is missing or device is disconnected
        Controls.Button {
            flat: true
            text: "Reload"
        }
        */
    }

    Shortcut {
        sequences: [StandardKey.Refresh]
        onActivated: {
            returnAction.trigger();
            fp.flickable.contentY = fp.flickable.originY;
            fp.refresh();
        }
    }
}
