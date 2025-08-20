// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.AbstractCard {
    property User user

    showClickFeedback: true
    contentItem: ColumnLayout {
        anchors.fill: parent
        RowLayout {
            Layout.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.largeSpacing * 2
            PixivImage {
                Layout.maximumWidth: 20
                Layout.maximumHeight: 20
                source: page.illust.user.profileImageUrls.medium
            }
            Controls.Label {
                text: page.illust.user.name
                font.bold: true
                font.pointSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
            RequestsCard {
                user: page.illust.user
            }
        }
        Controls.Button {
            Layout.fillWidth: true
            checkable: true
            checked: page.illust.user.isFollowed > 0
            text: checked ? i18n("Following") : i18n("Follow")
            icon.name: (page.illust.user.isFollowed == 2) ? "view-private" : ""
            onClicked: {
                if (page.illust.user.isFollowed == 0)
                    piqi.Follow(page.illust.user);
                else
                    piqi.RemoveFollow(page.illust.user);
            }
            onPressAndHold: piqi.Follow(page.illust.user, page.illust.user.isFollowed < 2)
        }
    }
    onClicked: piqi.Details(page.illust.user).then(dtls => root.navigateToPageParm("ProfileView", {
            details: dtls
        }))
}
