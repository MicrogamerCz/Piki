// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
import io.github.micro.piki
import io.github.micro.piqi
import "."
import "templates"

DoubleAbstractCard {
    id: card
    topHeight: 205
    bottomHeight: 45
    width: 175
    required property Work illust
    property bool hidden: false

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Component.onCompleted: {
        if (illust.isBookmarked == 1)
            illust.bookmarkDetail().then(details => illust.isBookmarked = (details.restriction == "private") ? 2 : 1);
    }

    onTopItemClicked: {
        if (illust.novelAiType == undefined)
            navigateToPageParm("IllustView", {
                illust: card.illust
            });
        else
            piqi.fetchNovel(illust).then(nv => navigateToPageParm("NovelView", {
                    novel: nv
                }));
    }
    onBottomItemClicked: piqi.details(card.illust.user).then(response => {
        if (!response.isSuccessful) {
            showResponseError(response);
            return;
        }
        root.navigateToPageParm("ProfileView", {
            details: response.data
        });
    })

    topItem: Item {
        anchors.fill: parent

        PixivImage {
            sourceSize.width: 140
            sourceSize.height: 140
            cache: true
            source: card.illust.imageUrls.squareMedium
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
            }
            height: width

            Item {
                anchors {
                    fill: parent
                    margins: Kirigami.Units.largeSpacing
                }
                Rectangle {
                    visible: card.illust.xRestrict != 0
                    anchors {
                        top: parent.top
                        left: parent.left
                    }

                    color: Kirigami.Theme.negativeTextColor
                    border.color: Kirigami.Theme.negativeBackgroundColor
                    radius: Kirigami.Units.cornerRadius
                    implicitWidth: restrictLabel.implicitWidth + Kirigami.Units.largeSpacing * 1.5
                    implicitHeight: restrictLabel.implicitHeight + Kirigami.Units.largeSpacing

                    Controls.Label {
                        id: restrictLabel
                        anchors.centerIn: parent
                        text: card.illust.xRestrict == 1 ? "R-18" : "R-18G"
                        font.pointSize: 10
                        font.bold: true
                    }
                }
                Controls.Control {
                    visible: card.illust.pageCount > 1
                    anchors {
                        top: parent.top
                        right: parent.right
                    }

                    contentItem: Row {
                        anchors.centerIn: parent
                        Kirigami.Icon {
                            height: pageCountLabel.height
                            width: height
                            source: "view-pages-overview"
                        }
                        Controls.Label {
                            id: pageCountLabel
                            text: card.illust.pageCount
                            font.pointSize: 10
                            font.bold: true
                        }
                    }
                    background: Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
                        radius: Kirigami.Units.cornerRadius
                    }
                }
                Rectangle {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    color: Kirigami.Theme.backgroundColor
                    border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
                    radius: Kirigami.Units.cornerRadius
                    implicitWidth: bookmarkIcon.implicitWidth + Kirigami.Units.mediumSpacing
                    implicitHeight: bookmarkIcon.implicitHeight + Kirigami.Units.mediumSpacing

                    Kirigami.Icon {
                        id: bookmarkIcon
                        z: 500
                        anchors.centerIn: parent
                        source: {
                            if (card.illust.isBookmarked === 2) {
                                return "view-private";
                            } else if (card.illust.isBookmarked === 1) {
                                return "favorite-favorited";
                            } else {
                                return "favorite";
                            }
                        }
                        color: (card.illust.isBookmarked > 0) ? "gold" : Kirigami.Theme.disabledTextColor

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true

                            onClicked: {
                                if (card.illust.isBookmarked == 0)
                                    card.illust.addBookmark(false);
                                else
                                    card.illust.removeBookmark();
                            }
                            onPressAndHold: card.illust.addBookmark(card.illust.isBookmarked != 2)
                        }
                    }
                }
            }

            layer {
                enabled: GraphicsInfo.api !== GraphicsInfo.Software
                effect: Kirigami.ShadowedTexture {
                    color: "transparent"
                    corners {
                        topLeftRadius: Kirigami.Units.cornerRadius
                        topRightRadius: Kirigami.Units.cornerRadius
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }
                }
            }
        }
        Controls.Label {
            id: titleLabel
            text: card.illust.title
            elide: Text.ElideRight
            font.bold: true
            anchors {
                left: parent.left
                bottom: parent.bottom
                right: parent.right
                margins: Kirigami.Units.mediumSpacing
            }
        }
    }
    bottomItem: Item {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.mediumSpacing
        PixivImage {
            id: pfp
            source: card.illust.user.profileImageUrls.medium
            cache: true
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: height
            sourceSize.width: 40
            sourceSize.height: 40
            fillMode: Image.PreserveAspectCrop

            layer {
                enabled: GraphicsInfo.api !== GraphicsInfo.Software
                effect: Kirigami.ShadowedTexture {
                    radius: 40
                }
            }
        }
        Controls.Label {
            anchors {
                left: pfp.right
                verticalCenter: parent.verticalCenter
                right: parent.right
                leftMargin: Kirigami.Units.mediumSpacing
            }
            text: card.illust.user.name
            elide: Text.ElideRight
        }
    }
}
