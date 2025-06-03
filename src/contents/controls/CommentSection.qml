// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: section
    clip: true
    property variant illust
    property int commentCount: 0
    property bool collapsed: true

    Component.onCompleted: piqi.IllustComments(illust).then(comments => processComments(comments, 0, null))

    function processComments(comments, level, previous) {
        for (let i = 0; i < comments.comments.length; i++) {
            let commentData = comments.comments[i];
            let commentComponent = Qt.createComponent("CommentCard.qml");
            commentComponent.createObject(commentLayout, {
                illust: section.illust,
                comment: commentData,
                level: level
            });
            commentCount++;

            if (commentData.hasReplies) {
                piqi.CommentReplies(commentData).then(comms => processComments(comms, level + 1, {
                        index: i + 1,
                        cms: comments,
                        lvl: level,
                        prv: previous
                    }));
                break;
            }
        }
        if (previous != null)
            processPrevious(previous);
    }
    function processPrevious(pd) {
        for (let i = pd.index; i < pd.cms.comments.length; i++) {
            let commentData = pd.cms.comments[i];
            let commentComponent = Qt.createComponent("CommentCard.qml");
            commentComponent.createObject(commentLayout, {
                illust: section.illust,
                comment: commentData,
                level: pd.lvl
            });
            commentCount++;

            if (commentData.hasReplies) {
                piqi.CommentReplies(commentData).then(comms => processComments(comms, pd.lvl + 1, {
                        index: i + 1,
                        cms: pd.cms,
                        lvl: pd.lvl,
                        prv: pd
                    }));
                break;
            }
        }
    }

    header: RowLayout {
        spacing: Kirigami.Units.largeSpacing * 2
        Kirigami.Icon {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            source: "comment-symbolic"
        }
        Controls.Label {
            text: "Comments"
            font.bold: true
            font.pointSize: 16
            Layout.alignment: Qt.AlignVCenter
        }
        Item {
            Layout.fillWidth: true
        }
        Controls.Button {
            visible: section.commentCount > 0
            flat: true
            icon.name: section.collapsed ? "usermenu-down" : "usermenu-up"
            onClicked: section.collapsed = !section.collapsed
        }
    }

    contentItem: Item {
        implicitWidth: commentLayout.implicitWidth
        implicitHeight: section.collapsed ? 0 : commentLayout.implicitHeight
        opacity: section.collapsed ? 0 : 1
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        ColumnLayout {
            id: commentLayout
            anchors {
                left: parent.left
                right: parent.right
            }
        }
    }
}
