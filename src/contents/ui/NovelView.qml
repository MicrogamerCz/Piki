// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtWebEngine
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.Page {
    id: page
    padding: 0
    title: ""

    property string novel
    onNovelChanged: web.loadHtml(novel)

    WebEngineView {
        id: web
        anchors.fill: parent
        // backgroundColor: "#B7B7B7"
        backgroundColor: "transparent"

        profile: WebEngineProfile {
            id: profile
            httpAcceptLanguage: Qt.uiLanguage
        }
    }
}
