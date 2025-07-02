// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.Action {
    property string url: ""
    onTriggered: Qt.openUrlExternally(url)
}
