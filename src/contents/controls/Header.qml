// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Item {
    id: head
    height: 60

    property alias searchBox: searchField.queryBox

    function pushSearchPage() {
        searchField.loading = true;
        let searchRequest = new SearchRequest();
        searchRequest.setTags(Cache.selectedTags);

        searchRequest.search().then(sr => {
            searchField.loading = false;
            navigateToPageParm("Search", {
                searchRequest: searchRequest,
                feed: sr
            });
        });
    }
    function verifyUrl(str) {
        try {
            let url = new URL(str);
            return str.substring(str.lastIndexOf("/") + 1);
        } catch (_) {
            if (!isNaN(str))
                return str;
            else
                return "";
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.margins: 5

        Controls.Label {
            id: headerLabel
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            text: root.currentPage
            font.bold: true
            font.pointSize: 14
        }

        TagCard {
            enable: searchBox.text != ""

            anchors {
                top: searchField.verticalCenter
                left: searchField.left
                right: searchField.right
                margins: 5
                topMargin: enable ? 30 : 0
            }
        }

        SearchField {
            id: searchField
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Controls.Button {
                flat: true

                icon.width: Kirigami.Units.gridUnit * 1.4
                icon.height: Kirigami.Units.gridUnit * 1.4
                icon.name: "notifications"

                Kirigami.Badge {
                    text: "5"
                    padding: 0

                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: Kirigami.Units.mediumSpacing
                    }
                }
            }
            Controls.Button {
                text: "Create"
                flat: true
                enabled: false
            }
        }
    }
}
