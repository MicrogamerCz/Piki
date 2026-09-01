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

    required property Tag tag
    property bool bold: false

    implicitWidth: layout.implicitWidth + Kirigami.Units.mediumSpacing * 3 + (closable ? (indicator.implicitWidth - Kirigami.Units.mediumSpacing) : 0)
    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2
    padding: Kirigami.Units.largeSpacing

    contentItem: RowLayout {
        id: layout
        Controls.Label {
            property bool isR18: (text == "R-18") || (text == "R-18G")

            text: chip.tag.name
            font.bold: chip.bold || isR18
            color: isR18 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
        }
        Controls.Label {
            color: Kirigami.Theme.disabledTextColor
            visible: (chip.tag.translatedName) != ""
            text: `(${chip.tag.translatedName})`
            font.pointSize: 8
        }
    }
    closable: false
}
