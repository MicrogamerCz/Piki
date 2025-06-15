// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.labs.components as Kila
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: user.name
    padding: 0

    /*
        Possible design - Header similar to profile pages on the web client (for the most
        basic info), details visible upon clicking can be in a floating card on the right
        side. Rest of the profile page can be infinite feed with SelectionButtons with the
        following choices:
        - Illust/manga
        - Novels
        - Illust/manga bookmarks
        - Novels bookmarks

        or they don't have to be this way. It doesn't have to be infinite feed, although
        it's the best option in my opinon, without having to do extra clicking as in the
        android app (or website).
    */

    property UserDetails details
    property User user: details.user
    property Profile profile: details.profile

    property WebAction fanboxAction: WebAction {
        url: ""
        visible: this.url != ""
        icon.name: "approved"
    }
    property WebAction messagesAction: WebAction {
        url: "https://www.pixiv.net/messages.php?receiver_id=" + page.user.id
        icon.name: "mail-message"
    }

    Component.onCompleted: {
        PikiHelper.CheckFanbox(user).then(url => fanboxAction.url = url);
        if (user.isFollowed > 0)
            piqi.FollowDetail(user).then(details => user.isFollowed = (details.restriction == "private") ? 2 : 1);
    }

    PixivImage {
        id: bannerImage
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        // Layout.preferredHeight: NaN // TODO: parallax or parallax-alike effect when scrolling
        Layout.maximumHeight: 350//page.height * 0.3
        fillMode: Image.PreserveAspectCrop
        source: page.profile.backgroundImageUrl
    }
    Kirigami.AbstractCard {
        Layout.topMargin: Kirigami.Units.largeSpacing * 4 - bannerImage.height
        Layout.leftMargin: Kirigami.Units.largeSpacing * 4
        Layout.maximumWidth: 500

        padding: Kirigami.Units.largeSpacing * 2
        contentItem: RowLayout {
            id: infoRow
            anchors.fill: parent
            spacing: Kirigami.Units.mediumSpacing * 2
            uniformCellSizes: false

            ColumnLayout {
                Kila.Avatar {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    source: page.user.profileImageUrls.medium
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Controls.Button {
                        action: page.fanboxAction
                        visible: page.fanboxAction.url != ""
                        flat: true
                    }
                    Controls.Button {
                        action: page.messagesAction
                        flat: true
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                uniformCellSizes: true

                RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Controls.Label {
                        text: page.user.name
                        font.bold: true
                        font.pointSize: 14
                        Layout.alignment: Qt.AlignVCenter
                    }
                    RequestsCard {
                        user: page.user
                    }
                }
                RowLayout {
                    visible: page.profile.totalFollowUsers > 0

                    Controls.Label {
                        text: page.profile.totalFollowUsers
                    }
                    Controls.Label {
                        text: "Following"
                        color: Kirigami.Theme.disabledTextColor
                    }
                }
                RowLayout {
                    visible: page.profile.region != ""

                    Kirigami.Icon {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        source: "mark-location"
                        color: Kirigami.Theme.disabledTextColor
                    }
                    Controls.Label {
                        text: page.profile.region
                        color: Kirigami.Theme.disabledTextColor
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ColumnLayout {
                layoutDirection: Qt.RightToLeft

                Controls.Button {
                    checkable: true
                    checked: page.user.isFollowed > 0
                    text: checked ? "Following" : "Follow"
                    icon.name: (page.user.isFollowed == 2) ? "view-private" : ""
                    onClicked: {
                        if (page.user.isFollowed == 0)
                            piqi.Follow(page.user);
                        else
                            piqi.RemoveFollow(page.user);
                    }
                    onPressAndHold: piqi.Follow(page.user, page.user.isFollowed < 2)
                }
                Controls.Button {
                    text: "My pixiv request"
                    enabled: false
                }
                // Controls.Button {
                //     text: "Recommended Users"
                //     enabled: false
                // }
                Kirigami.Separator {
                    Layout.preferredWidth: parent.width
                }
                // Controls.Label {
                //     text: "Share"
                // }
                Kirigami.ActionToolBar {
                    alignment: Qt.AlignRight
                    actions: [
                        Kirigami.Action {
                            icon.name: "edit-copy"
                            enabled: false
                        }
                        // more choices via purpose


                    ]
                }
            }
        }
    }
    // Item {
    // Layout.fillHeight: true
    // }
    Controls.Label {
        text: "h"
    }
}
