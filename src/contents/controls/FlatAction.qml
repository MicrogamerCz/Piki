// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.Action {
    id: action
    property string iconName

    displayComponent: Row {
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            width: (source == "") ? 1 : 20
            height: (source == "") ? 1 : 20
            source: action.iconName
        }
        Controls.Label {
            text: action.text
        }
    }
}
