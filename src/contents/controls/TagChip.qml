// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi

Kirigami.Chip {
    id: chip
    checked: false
    checkable: false

    required property Tag modelData

    implicitWidth: layout.implicitWidth + Kirigami.Units.mediumSpacing * 2
    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2
    padding: Kirigami.Units.largeSpacing

    contentItem: RowLayout {
        id: layout
        Controls.Label {
            text: chip.modelData.name
        }
        Controls.Label {
            color: Kirigami.Theme.disabledTextColor
            visible: chip.modelData.translatedName != ""
            text: `(${chip.modelData.translatedName})`
            font.pointSize: 8
        }
        Item {
            Layout.fillWidth: true
        }
        Controls.Button {
            visible: chip.closable
            Layout.margins: 0
            Layout.maximumWidth: layout.height
            Layout.maximumHeight: layout.height
            icon.name: "dialog-close"
            icon.color: "red"
            padding: 0
            flat: true

            onClicked: chip.removed()
        }
    }
    closable: false
}
