// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.NavigationTabButton {
    property bool matchPart: false
    property bool loading: false

    Layout.fillWidth: true
    implicitHeight: 50
    display: Controls.AbstractButton.TextBesideIcon
    checked: matchPart ? root.currentPage.startsWith(text) : (root.currentPage == text)
    checkable: false

    Controls.BusyIndicator {
        visible: parent.loading
        anchors {
            margins: 5
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
    }
}
