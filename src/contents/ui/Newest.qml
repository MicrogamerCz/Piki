// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: `Newest ・ ${categories.label}`

    property string category: "illust"
    property Illusts feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        piqi.LatestGlobal(category).then(rec => {
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
            value: page.category
            onValueChanged: page.category = value

            options: [
                {
                    label: "Illustrations",
                    value: "illust"
                },
                {
                    label: "Manga",
                    value: "manga"
                },
                {
                    label: "Novel",
                    value: "novel"
                }
            ]
        },
        Controls.BusyIndicator {
            visible: page.loading
        }
    ]
    GridLayout {
        rowSpacing: 15
        columnSpacing: 15
        columns: Math.floor((page.width - 25) / 190)

        Repeater {
            model: page.feed
            IllustrationButton {
                required property var modelData
                illust: modelData
            }
        }
    }
}
