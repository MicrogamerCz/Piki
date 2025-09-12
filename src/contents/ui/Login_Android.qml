// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtWebView
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.Page {
    id: page
    padding: 0
    title: ""

    Component.onCompleted: {
        web.url = processor.Begin();
    }

    LoginProcessor {
        id: processor

        onLoggedIn: function (response) {
            root.loggedIn(response);
        }
    }

    WebView {
        id: web
        anchors.fill: parent
    }
}
