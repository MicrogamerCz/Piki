// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.AbstractCard {
    id: card

    property int level: 0
    property Illustration illust
    property Comment comment
    property bool hasStamp: comment.stamp !== null

    Layout.fillWidth: true
    Layout.minimumHeight: card.height
    clip: true
    Layout.leftMargin: level * 50

    function processTextEmotes(text) {
        text = text.replace("(love4)", "😍");

        return text;
    }

    contentItem: Item {
        implicitWidth: cmt.implicitWidth
        implicitHeight: cmt.implicitHeight
        RowLayout {
            id: cmt
            anchors.fill: parent
            spacing: Kirigami.Units.mediumSpacing
            PixivImage {
                Layout.alignment: Qt.AlignTop
                Layout.maximumHeight: 35
                Layout.maximumWidth: 35
                source: card.comment.user.profileImageUrls.medium
            }

            Column {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Controls.Label {
                        text: card.comment.user.name
                        font.bold: true
                    }
                    Rectangle {
                        visible: card.comment.user.account == card.illust.user.account
                        color: Kirigami.Theme.linkColor
                        border.color: Kirigami.Theme.linkBackgroundColor
                        radius: Kirigami.Units.cornerRadius
                        implicitWidth: authorLabel.implicitWidth + Kirigami.Units.largeSpacing * 1.5
                        implicitHeight: authorLabel.implicitHeight + Kirigami.Units.largeSpacing

                        Controls.Label {
                            id: authorLabel
                            anchors.centerIn: parent
                            text: i18n("Author")
                            font.pointSize: 7
                            font.bold: true
                        }
                    }
                }
                Controls.Label {
                    visible: !card.hasStamp
                    text: card.processTextEmotes(card.comment.comment)
                    font.bold: true
                    wrapMode: Text.WordWrap
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                }

                Loader {
                    sourceComponent: PixivImage {
                        id: stampImage
                        height: 80
                        width: 80
                        source: card.comment.stamp.stampUrl
                    }

                    active: card.hasStamp
                }

                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    Controls.Label {
                        text: Qt.formatDateTime(card.illust.createDate, "yyyy-MM-dd hh:mm")
                    }
                    Controls.Button {
                        flat: true
                        enabled: false
                        text: i18n("Reply")
                    }
                }
            }
        }
    }
}
