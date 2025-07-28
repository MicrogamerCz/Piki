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
    property string queries: ""
    title: `${queries} (${sortingSelection.label})`

    property string sorting: "date_desc"
    onSortingChanged: {
        if (sorting != "popular")
            searchRequest.sortAscending = sorting == "date_asc";
        refresh();
    }
    property string target: "partial"
    onTargetChanged: {
        switch (target) {
        case "partial":
            searchRequest.searchTarget = SearchRequest.PartialTagsMatch;
            break;
        case "perfect":
            searchRequest.searchTarget = SearchRequest.ExactTagsMatch;
            break;
        default:
            searchRequest.searchTarget = SearchRequest.TitleAndDescription;
            break;
        }
        refresh();
    }
    property variant searchRequest
    property variant feed

    function refresh() {
        if (!feed)
            return;

        page.flickable.contentY = 0;
        page.loading = true;

        if (sorting == "popular")
            piqi.SearchPopularPreview(searchRequest).then(sr => {
                Cache.SynchroniseIllusts(sr.illusts);
                loading = false;
                feed = sr;
            });
        else
            piqi.Search(searchRequest).then(sr => {
                Cache.SynchroniseIllusts(sr.illusts);
                loading = false;
                feed = sr;
            });
    }

    Component.onCompleted: queries = root.getHeaderQuery()

    filterSelections: [
        SelectionButtons {
            id: sortingSelection
            Layout.fillHeight: true
            value: page.sorting
            onValueChanged: page.sorting = value

            options: [
                {
                    label: "Newest",
                    value: "date_desc"
                },
                {
                    label: "Popular",
                    value: "popular"
                },
                {
                    label: "Oldest",
                    value: "date_asc"
                }
            ]
        },
        Kirigami.Separator {
            Layout.fillHeight: true
        },
        SelectionButtons {
            id: targetSelection
            Layout.fillHeight: true
            value: page.target
            onValueChanged: page.target = value

            options: [
                {
                    label: "Partial tag match",
                    value: "partial"
                },
                {
                    label: "Perfect tag match",
                    value: "perfect"
                },
                {
                    label: "Title, description",
                    value: "tides"
                }
            ]
        },
        Kirigami.Separator {
            Layout.fillHeight: true
        },
        Controls.ComboBox {
            Layout.fillHeight: true
            flat: true
            textRole: "text"
            model: [
                {
                    "text": "All periods",
                    "value": 0
                },
                {
                    "text": "24 hours",
                    "value": 1
                },
                {
                    "text": "One Week",
                    "value": 2
                },
                {
                    "text": "One Month",
                    "value": 3
                },
                {
                    "text": "6 Months",
                    "value": 4
                },
                {
                    "text": "One Year",
                    "value": 5
                },
                {
                    "text": "Indicate Date",
                    "value": 6
                }
            ]
        },
        Controls.BusyIndicator {
            visible: page.loading
        },
        Item {
            Layout.fillWidth: true
        }
    ]

    /*PremiumBanner {
        closed: page.sorting != "popular"
        }*/

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

    Controls.Label {
        visible: !piqi.user.isPremium && page.sorting == "popular"
        Layout.alignment: Qt.AlignHCenter
        font.bold: true
        font.pointSize: 24
        text: "Limited search by popularity"
    }

    Item {
        Layout.fillHeight: true
    }
}
