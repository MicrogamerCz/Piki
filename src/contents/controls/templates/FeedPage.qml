// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: fp
    property alias flick: _flickable
    default property alias contentItems: columnLayout.data
    property bool loading: false
    signal fetchNext
    signal refresh

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
        value: _flickable.contentY
        onValueChanged: {
            if (!_flickable.interactive && value == 0)
                _flickable.interactive = true;
            if (value != to)
                return;
            _flickable.interactive = false;
            fp.refresh();
        }
    }
    Flickable {
        id: _flickable
        anchors.fill: parent
        contentWidth: columnLayout.width
        contentHeight: columnLayout.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        interactive: true
        clip: true

        onAtYEndChanged: {
            if (!atYEnd || fp.loading)
                return;

            fp.loading = true;
            fp.fetchNext();
        }

        ColumnLayout {
            id: columnLayout
            width: _flickable.width - sc.width
            spacing: Kirigami.Units.largeSpacing
        }

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: sc
            policy: Controls.ScrollBar.AlwaysOn
            anchors.right: parent.right
        }
    }
}
