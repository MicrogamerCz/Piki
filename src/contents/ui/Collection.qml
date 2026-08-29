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
    title: i18n("Bookmarks ・ %1", categories.label)

    property string tag: "All"
    onTagChanged: refresh()
    property bool isNovelCategory: false
    onIsNovelCategoryChanged: refresh()
    property bool restrict: false
    onRestrictChanged: refresh()

    property PikiBookmarkTags tags: PikiBookmarkTags {}

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        // Empty tag returns all bookmarked works, uncategorized is hardcoded to use the const tag
        let queryTag = tag;
        if (queryTag == "All")
            queryTag = "";
        else if (queryTag == "Uncategorized")
            queryTag = "未分類";
        let type = isNovelCategory ? "novel" : "illust";
        piqi.bookmarksFeed(piqi.user, restrict, queryTag, type).then(response => {
            if (response.isSuccessful)
                feed = response.data;
            else
                showResponseError(response);
            loading = false;
        });
    }

    Component.onCompleted: {
        piqi.bookmarkTags(isNovelCategory ? "novel" : "illust", restrict).then(response => {
            if (response.isSuccessful)
                tags.Extend(response.data);
            else
                showResponseError(response);
        });
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
            model: page.tags
            textRole: "name"
            displayText: {
                if (currentText == "All" || currentText != "Uncategorized")
                    return i18n(currentText);
                else
                    return "#" + currentText;
            }
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
            options: [i18n("Public"), i18n("Private")]
        }
    ]
}
