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
    title: i18n("Newest ・ %1", categories.label)

    property string category: "illust"
    onCategoryChanged: refresh()

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        if (category !== "novel")
            piqi.LatestGlobal(category).then(rec => {
                Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
        else
            piqi.LatestNovelsGlobal(rec => {
                // Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: page.category
            onValueChanged: page.category = value

            options: [
                {
                    label: i18n("Illustrations"),
                    value: "illust"
                },
                {
                    label: i18n("Manga"),
                    value: "manga"
                },
                {
                    label: i18n("Novel"),
                    value: "novel"
                }
            ]
        },
        Controls.BusyIndicator {
            visible: page.loading
        }
    ]
}
