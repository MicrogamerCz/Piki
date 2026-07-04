// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.Page {
    id: page
    padding: Kirigami.Units.gridUnit

    LoginProcessor {
        id: processor
        onLoggedIn: function (response) {
            let json = JSON.parse(response);
            if (json.has_error) {
                root.showPassiveNotification(i18n("Login failed: invalid refresh_token"));
                return;
            }
            root.loggedIn(response);
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, 400)

        Kirigami.Heading {
            text: i18n("Pixiv Login")
            Layout.alignment: Qt.AlignHCenter
        }

        Controls.Label {
            text: i18n("Enter your Pixiv refresh_token:")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Controls.TextField {
            id: tokenField
            placeholderText: i18n("Paste refresh_token here...")
            Layout.fillWidth: true
        }

        Controls.Button {
            text: i18n("Log In")
            enabled: tokenField.text.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            onClicked: processor.LoginWithRefreshToken(tokenField.text.trim())
        }

        Controls.Label {
            text: i18n("You can obtain a refresh_token by logging into Pixiv in your browser, then using the browser's developer tools (Network tab) to capture the response from the oauth.secure.pixiv.net/auth/token endpoint after a successful login.")
            wrapMode: Text.Wrap
            font.pixelSize: 10
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }
    }
}
