// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: `Following ・ ${categories.label}`

    property string category: "illust"
    property string restrict: "all"
    onRestrictChanged: refresh()
    property Illusts feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        piqi.FollowingFeed(category, restrict).then(rec => {
            Cache.SynchroniseIllusts(rec.illusts);
            feed = rec;
            loading = false;
        });
    }

    filterSelections: [
        SelectionButtons {
            id: categories
            value: (page.category == "novel")
            onValueChanged: page.category = value ? "novel" : "illust"
            options: ["Illustrations / Manga", "Novels"]
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
                    label: "All",
                    value: "all"
                },
                {
                    label: "Public only",
                    value: "public"
                },
                {
                    label: "Private only",
                    value: "private"
                }
            ]
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
