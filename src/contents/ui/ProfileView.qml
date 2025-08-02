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
    property string category: "0"
    property Illusts feed

    property WebAction fanboxAction: WebAction {
        url: ""
        visible: this.url != ""
        icon.name: "approved"
    }
    property WebAction messagesAction: WebAction {
        url: "https://www.pixiv.net/messages.php?receiver_id=" + page.user.id
        icon.name: "mail-message"
    }

    function refresh() {
    }

    Component.onCompleted: {
        PikiHelper.CheckFanbox(user).then(url => fanboxAction.url = url);
        if (user.isFollowed > 0)
            piqi.FollowDetail(user).then(details => user.isFollowed = (details.restriction == "private") ? 2 : 1);

        if (profile.totalIllusts > 0 || profile.totalManga > 0)
            piqi.UserIllusts(user, "illust").then(illusts => {
                feed = illusts;
            });
        // else
        // return; // novels
    }

    header: null

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
                            visible: page.user.account != piqi.user.account
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
                Layout.maximumHeight: dataCard.height
                Layout.preferredHeight: dataCard.height
                Layout.leftMargin: (headerLayout.height - height) * 0.5
                Layout.maximumWidth: page.width * 0.4
                verticalPadding: Kirigami.Units.largeSpacing * 2
                horizontalPadding: Kirigami.Units.largeSpacing * 6
                clip: true
                implicitHeight: extraInfoCard.implicitHeight
                // implicitWidth: extraInfoCard.implicitWidth

                visible: (page.user.comment != "") || profileDetailsButton.shouldBeVisible || workspaceDetailsButton.shouldBeVisible

                contentItem: RowLayout {
                    id: extraInfoCard
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing * 4
                    uniformCellSizes: false

                    ColumnLayout {
                        id: userDetailsSwitch
                        Layout.fillHeight: true
                        spacing: Kirigami.Units.largeSpacing * 2
                        uniformCellSizes: true

                        property int details: 0

                        Controls.Button {
                            visible: page.user.comment != ""
                            icon.name: "description"
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
                        Controls.Button {
                            id: profileDetailsButton
                            property bool shouldBeVisible: false
                            icon.name: "user-symbolic"
                            flat: true
                            checkable: true
                            checked: parent.details == 2
                            onClicked: {
                                if (parent.details == 2)
                                    parent.details = 0;
                                else
                                    parent.details = 2;
                            }

                            Component.onCompleted: {
                                let visibles = 0;
                                for (let i = 0; i < profileDetailsLayout.children.length; i++) {
                                    let txt = profileDetailsLayout.children[i].text;
                                    let doesExist = (txt != "") && (txt != null) && (txt != undefined);
                                    visibles += (doesExist) ? 1 : 0;
                                }
                                shouldBeVisible = visible = visibles > 0;
                            }
                        }
                        Controls.Button {
                            id: workspaceDetailsButton
                            property bool shouldBeVisible: false
                            icon.name: "window"
                            flat: true
                            checked: parent.details == 3
                            checkable: true
                            onClicked: {
                                if (parent.details == 3)
                                    parent.details = 0;
                                else
                                    parent.details = 3;
                            }

                            Component.onCompleted: {
                                let visibles = 0;
                                for (let i = 0; i < workspaceDetailsLayout.children.length; i++) {
                                    let txt = workspaceDetailsLayout.children[i].text;
                                    let doesExist = (txt != "") && (txt != null) && (txt != undefined);
                                    visibles += (doesExist) ? 1 : 0;
                                }
                                shouldBeVisible = visible = visibles > 0;
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        visible: userDetailsSwitch.details > 0
                    }

                    Controls.Label {
                        wrapMode: Text.WordWrap
                        visible: userDetailsSwitch.details == 1
                        text: page.user.comment
                        Layout.fillWidth: true
                    }
                    Kirigami.FormLayout {
                        id: profileDetailsLayout
                        visible: userDetailsSwitch.details == 2

                        Controls.TextField {
                            Kirigami.FormData.label: "Gender"
                            visible: text != ""
                            readOnly: true
                            text: {
                                switch (page.profile.gender) {
                                case -1:
                                    return "";
                                case 0:
                                    return "";
                                // return "Unknown";
                                case 1:
                                    return "Male";
                                case 2:
                                    return "Female";
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
                            visible: text != ""
                            readOnly: true
                            // text: `${page.profile.birthDay} ${page.profile.birthYear}`
                            text: page.processBD(page.profile.birthDay, page.profile.birthYear)
                        }
                    }
                    Kirigami.FormLayout {
                        id: workspaceDetailsLayout
                        visible: userDetailsSwitch.details == 3

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
                            Kirigami.FormData.label: "Graphic tablet"
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

    SelectionButtons {
        id: categories
        Layout.leftMargin: Kirigami.Units.gridUnit
        Layout.fillWidth: true
        value: page.category
        onValueChanged: page.category = value

        options: [
            {
                label: "Illustrations",
                value: "0"
            },
            {
                label: "Manga",
                value: "1"
            },
            {
                label: "Manga series",
                value: "2"
            },
            {
                label: "Novels",
                value: "3"
            },
            {
                label: "Illustrations / Manga (Bookmarks)",
                value: "4"
            },
            {
                label: "Novels (Bookmarks)",
                value: "5"
            }
        ]
    }
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Kirigami.Units.gridUnit
        Layout.rightMargin: Kirigami.Units.gridUnit
        rowSpacing: 15
        columnSpacing: 15
        columns: Math.floor((page.width - 25) / 190)

        Repeater {
            model: page.feed
            IllustrationButton {
                required property variant modelData
                illust: modelData
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
    function formatDate(day, month, year) {
    }

    function processBD(birth_day, birth_year) {
        var spl = birth_day.split("-");
        var day = spl[1];
        var month = spl[0];

        if (day == "" && month == "" && birth_year == "")
            return "";

        // var y = hasYear ? parseInt(year) : 2000;
        // var m = hasMonth ? parseInt(month) - 1 : 0;
        // var d = hasDay ? parseInt(day) : 1;

        var date = new Date(birth_year, month - 1, day);

        var format = "";
        if (day)
            format += "d";
        if (month)
            format += (format ? " " : "") + "MMMM";
        // Appropriate expectation
        if (birth_year > 1900)
            format += (format ? " " : "") + "yyyy";

        var locale = Qt.locale();
        return locale.toString(date, format);//.trim();
    }
}
