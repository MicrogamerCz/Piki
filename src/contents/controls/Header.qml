// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

// TODOs:
// - split controls

Item {
    id: head
    height: 60

    property alias selectedTags: _selectedTags
    property alias queryBox: searchField.queryBox

    ListModel {
        id: tagsHistory

        function refresh() {
            Cache.getTagHistory().then(hist => {
                clear();

                for (let i = 0; i < hist.length; i++) {
                    let tag = hist[i];

                    if (!selectedTags.tagInSelected(tag))
                        append({
                            tagData: tag
                        });
                }
            });
        }
    }
    ListModel {
        id: _selectedTags
        onRowsInserted: {
            queryBox.text = "";
            queryBox.forceActiveFocus();
        }
        onRowsRemoved: {
            queryBox.autocomplete();
            tagsHistory.refresh();

            if (currentPage.startsWith("Search"))
                pushSearchPage();
        }

        function tagInSelected(tag) {
            for (let i = 0; i < count; i++) {
                let sTag = get(i).tagData;
                let sameName = sTag.name == tag.name;
                let sameTr = sTag.translatedName == tag.translatedName;
                if (sameName && sameTr)
                    return true;
            }
            return false;
        }
    }

    function pushSearchPage() {
        searchField.loading = true;
        let searchRequest = new SearchRequest();
        searchRequest.SetTags(selectedTags);

        Cache.pushTagHistory(searchRequest.tags);

        searchRequest.Search().then(sr => {
            searchField.loading = false;
            navigateToPageParm("Search", {
                searchRequest: searchRequest,
                feed: sr
            });
        });
    }
    function checkIfStringIsUrlAndProcess(str) {
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
            enable: queryBox.text != ""
            onEnableChanged: tagsHistory.refresh()

            history: tagsHistory
            selection: selectedTags

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

            selection: selectedTags
        }

        // Controls.Button {
        //     text: "Create"
        //     anchors.right: parent.right
        //     flat: true
        // }
    }
}
