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

    property string category: "illust"
    property string restrict: "public"
    onRestrictChanged: refresh()
    property Illusts feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        piqi.BookmarksFeed(category, restrict).then(rec => {
            Cache.SynchroniseIllusts(rec.illusts);
            feed = rec;
            loading = false;
        });
    }

    onFetchNext: {
        piqi.FetchNextFeed(feed).then(newFeed => {
            Cache.SynchroniseIllusts(newFeed.illusts);
            feed.Extend(newFeed);
            page.loading = false;
        });
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: (page.category == "novel")
            onValueChanged: page.category = value ? "novel" : "illust"
            options: ["Illustrations / Manga", "Novels"]
        },
        Kirigami.Separator {
            Layout.fillHeight: true
        },
        // TODO: bookmarks query field
        Controls.BusyIndicator {
            visible: page.loading
        },
        Item {
            Layout.fillWidth: true
        },
        SelectionButtons {
            id: restrictions
            value: (page.restrict == "private")
            onValueChanged: page.restrict = value ? "private" : "public"
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
                required property variant modelData
                illust: modelData
            }
        }
    }
}
