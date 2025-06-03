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
    Layout.fillWidth: true
    Layout.minimumHeight: card.height
    clip: true
    Layout.leftMargin: level * 50

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
                    // Author stamp
                }
                Controls.Label {
                    visible: card.comment.stamp == null
                    text: card.comment.comment
                    font.bold: true
                    wrapMode: Text.WordWrap
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                }
                PixivImage {
                    visible: card.comment.stamp != null
                    height: 80
                    width: 80
                    source: card.comment.stamp?.url ?? ""
                }

                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    Controls.Label {
                        text: Qt.formatDateTime(card.illust.createDate, "yyyy-MM-dd hh:mm")
                    }
                    Controls.Button {
                        flat: true
                        text: "Reply"
                    }
                }
            }
        }
    }
}
