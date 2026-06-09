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
    title: i18n("Following ・ %1", categories.label)

    property bool isNovelCategory: false
    onIsNovelCategoryChanged: refresh()
    property string restrict: "all"
    onRestrictChanged: refresh()

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        if (!isNovelCategory)
            piqi.FollowingFeed(restrict).then(rec => {
                Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
        else
            piqi.FollowingNovelsFeed(restrict).then(rec => {
                // Cache.SynchroniseIllusts(rec.illusts);
                feed = rec;
                loading = false;
            });
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: page.isNovelCategory
            onValueChanged: page.isNovelCategory = value
            options: [i18n("Illustrations / Manga"), i18n("Novels")]
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
            options: [
                {
                    label: i18n("All"),
                    value: "all"
                },
                {
                    label: i18n("Public only"),
                    value: "public"
                },
                {
                    label: i18n("Private only"),
                    value: "private"
                }
            ]
        }
    ]
}
