// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls

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
