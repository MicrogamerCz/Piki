// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.AbstractCard {
    id: ac
    showClickFeedback: true
    property string pfp: "../assets/pixiv_no_profile.png"
    property string name: ""
    signal removed

    implicitWidth: 320
    contentItem: RowLayout {
        spacing: 15
        PixivImage {
            Layout.preferredHeight: 50
            Layout.preferredWidth: 50
            source: ac.pfp
        }
        Kirigami.Heading {
            text: ac.name
        }
        Item {
            Layout.fillWidth: true
        }
        Controls.Button {
            flat: true
            enabled: ac.enabled
            icon.name: "edit-delete-remove"
            onClicked: ac.removed()
        }
    }
}
