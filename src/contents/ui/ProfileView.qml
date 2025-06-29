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
    property Workspace workspace: details.workspace

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

    Rectangle {
        id: headerLayout
        Layout.preferredHeight: 350
        Layout.fillWidth: true
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "#000000", 0.1)

        PixivImage {
            id: bannerImage
            visible: source != ""
            sourceSize.width: width
            sourceSize.height: height
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: page.profile.backgroundImageUrl
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Kirigami.Units.largeSpacing * 3

            Kirigami.AbstractCard {
                id: dataCard
                Layout.leftMargin: (headerLayout.height - height) * 0.5
                padding: Kirigami.Units.largeSpacing * 2

                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.mediumSpacing * 2
                    uniformCellSizes: false

                    ColumnLayout {
                        RowLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Kirigami.Units.mediumSpacing
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
                                    // TODO: buttons for other links (Twitter, Pawoo, ...)
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                uniformCellSizes: true

                                RowLayout {
                                    spacing: Kirigami.Units.largeSpacing
                                    Controls.Label {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: page.user.name
                                        font.bold: true
                                        font.pointSize: 14
                                        color: page.profile.isPremium ? "gold" : Kirigami.Theme.textColor
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
                        }

                        RequestsCard {
                            user: page.user
                        }
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
                        Controls.Button {
                            text: "Recommended Users"
                            enabled: false
                        }
                        /*Controls.Button {
                            text: "Mute settings"
                            enabled: false
                        }*/
                        // Block
                        // Report
                        Kirigami.Separator {
                            Layout.fillWidth: true
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
            Kirigami.AbstractCard {
                Layout.preferredHeight: dataCard.height
                Layout.leftMargin: (headerLayout.height - height) * 0.5
                verticalPadding: Kirigami.Units.largeSpacing * 2
                horizontalPadding: Kirigami.Units.largeSpacing * 6
                clip: true

                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing * 4
                    uniformCellSizes: false

                    ColumnLayout {
                        id: userDetailsSwitch
                        property int details: 0
                        uniformCellSizes: true
                        Controls.Button {
                            icon.name: "user-symbolic"
                            flat: true
                            checkable: true
                            checked: parent.details == 1
                            onClicked: {
                                if (parent.details == 1)
                                    parent.details = 0;
                                else
                                    parent.details = 1;
                            }
                        }
                        Item {}
                        Controls.Button {
                            icon.name: "window"
                            flat: true
                            checked: parent.details == 2
                            checkable: true
                            onClicked: {
                                if (parent.details == 2)
                                    parent.details = 0;
                                else
                                    parent.details = 2;
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        visible: userDetailsSwitch.details > 0
                    }

                    Kirigami.FormLayout {
                        visible: userDetailsSwitch.details == 1

                        Controls.TextField {
                            Kirigami.FormData.label: "Gender"
                            readOnly: true
                            text: {
                                switch (page.profile.gender) {
                                case 0:
                                    return "Unknown";
                                case 1:
                                    return "Male";
                                default:
                                    return page.profile.gender;
                                }
                            }
                        }
                        Controls.TextField {
                            Kirigami.FormData.label: "Age"
                            visible: text != ""
                            readOnly: true
                            text: (page.profile.birth != "") ? page.calculateAge(new Date(Date.parse(page.profile.birth))) : ""
                        }
                        Controls.TextField {
                            Kirigami.FormData.label: "Birthday"
                            readOnly: true
                            text: `${page.profile.birthDay} ${page.profile.birthYear}`
                        }
                    }
                    Kirigami.FormLayout {
                        visible: userDetailsSwitch.details == 2

                        Controls.TextField {
                            Kirigami.FormData.label: "Computer"
                            visible: text != ""
                            readOnly: true
                            text: page.workspace.pc
                        }
                        Controls.TextField {
                            Kirigami.FormData.label: "Software used"
                            visible: text != ""
                            readOnly: true
                            text: page.workspace.tool
                        }
                        Controls.TextField {
                            Kirigami.FormData.label: "Tablet"
                            visible: text != ""
                            readOnly: true
                            text: page.workspace.tablet
                        }
                    }
                }

                // It's buggy when changing the layouts
                /*Behavior on implicitWidth {
                    SmoothedAnimation {
                        duration: 100
                    }
                }*/
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }

    function calculateAge(date) {
        let age = new Date().getFullYear() - date.getFullYear();

        if (new Date().getMonth() > date.getMonth())
            return age;
        if (new Date().getDay() >= date.getDay())
            return age;

        return age - 1;
    }
}
