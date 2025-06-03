// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtWebEngine
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    title: "pixiv Premium"
    padding: 0
    WebEngineView {
        anchors.fill: parent
        url: "https://www.pixiv.net/premium"
    }
}
