// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: `Bookmarks ・ ${categories.label}`

    property string tag: "All"
    onTagChanged: refresh()
    property bool isNovelCategory: false
    onIsNovelCategoryChanged: refresh()
    property bool restrict: false
    onRestrictChanged: refresh()
    property var feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        // Empty tag returns all bookmarked works, uncategorized is hardcoded to use the const tag
        let queryTag = tag;
        if (queryTag == "All")
            queryTag = "";
        else if (queryTag == "Uncategorized")
            queryTag = "未分類";
        if (!isNovelCategory)
            piqi.BookmarksFeed(restrict, queryTag).then(rec => {
                Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
        else
            piqi.NovelsBookmarksFeed(restrict, queryTag).then(rec => {
                // Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
    }

    Component.onCompleted: {
        piqi.BookmarkIllustTags(restrict).then(tags_ => {
            tags.Extend(tags_);
        });
    }
    PikiTags {
        id: tags
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: page.isNovelCategory
            onValueChanged: page.isNovelCategory = value
            options: ["Illustrations / Manga", "Novels"]
        },
        Kirigami.Separator {
            Layout.fillHeight: true
        },
        Controls.ComboBox {
            onCurrentTextChanged: page.tag = currentText
            editable: true
            model: tags
            displayText: (((currentText != "All") && (currentText != "Uncategorized")) ? "#" : "") + currentText
        },
        Controls.BusyIndicator {
            visible: page.loading
        },
        Item {
            Layout.fillWidth: true
        },
        SelectionButtons {
            id: restrictions
            value: page.restrict
            onValueChanged: page.restrict = value
            options: ["Public", "Private"]
        }
    ]
    GridLayout {
        rowSpacing: 15
        columnSpacing: 15
        columns: Math.floor((page.width - 25) / 190)

        Repeater {
            model: page.feed
            IllustrationButton {
                illust: modelData
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
}
