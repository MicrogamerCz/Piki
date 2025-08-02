// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KIA
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: `Watchlist ・ ${categories.label}`
    property bool isNovelCategory: false
    onIsNovelCategoryChanged: refresh()
    property SeriesDetails feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        if (isNovelCategory) {
            isNovelCategory = loading = false;
            return;
        } else
            piqi.WatchlistFeed().then(wtl => {
                // Cache.SynchroniseIllusts(rec.illusts);
                feed = wtl;
                loading = false;
            });
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: page.isNovelCategory
            onValueChanged: page.isNovelCategory = value

            options: ["Manga", "Novel"]
        },
        Controls.BusyIndicator {
            visible: page.loading
        },
        Item {
            Layout.fillWidth: true
        }
    ]

    GridLayout {
        rowSpacing: 15
        columnSpacing: 15
        columns: Math.floor((page.width - 25) / 565)

        Repeater {
            model: page.feed

            SeriesButton {
                detail: modelData
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
}
