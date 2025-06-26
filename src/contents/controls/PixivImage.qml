// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Image {
    asynchronous: true
    Controls.ProgressBar {
        z: -1
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.mediumSpacing
        }
        from: 0
        to: 1
        value: parent.progress
        visible: value < 1
    }
}
