// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: fp

    default property alias contentItems: columnLayout.data
    property alias filterSelections: filterRow.children
    property bool loading: false
    signal fetchNext
    signal refresh

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

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
    }

    Kirigami.AbstractCard {
        z: 5
        visible: fp.loading
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Kirigami.Units.gridUnit * 1.5
        }
        contentItem: Controls.ProgressBar {
            indeterminate: true
            anchors.fill: parent
        }
    }

    Controls.ProgressBar {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: Kirigami.Units.gridUnit
        anchors.topMargin: (value < 0) ? (-value / 2) : 0
        from: 0
        to: -200
        opacity: value * -0.01
        value: fp.flickable.contentY
        onValueChanged: {
            if (!fp.flickable.interactive && value == 0)
                fp.flickable.interactive = true;
            if (value != to)
                return;
            fp.flickable.interactive = false;
            fp.refresh();
        }
    }
}
