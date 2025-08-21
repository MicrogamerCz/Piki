// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtWebEngine
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.Page {
    id: page
    padding: 0
    title: ""

    Component.onCompleted: {
        processor.AddInterceptor(profile);
        web.url = processor.Begin();
    }

    LoginProcessor {
        id: processor

        onLoggedIn: function (response) {
            root.loggedIn(response);
        }
    }

    WebEngineView {
        id: web
        anchors.fill: parent

        profile: WebEngineProfile {
            id: profile
            httpAcceptLanguage: Qt.uiLanguage
        }
    }
}
