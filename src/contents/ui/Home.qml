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
    title: i18n("Home ・ %1", categories.label)
    property string category: "illust"
    onCategoryChanged: refresh()
    property var feed

    function refresh() {
        page.flickable.contentY = 0;
        loading = true;
        if (category == "novel")
            piqi.RecommendedNovelsFeed(true, false).then(rec => {
                // Cache.SynchroniseIllusts(rec.novels);
                feed = rec;
                loading = false;
            });
        else
            piqi.RecommendedFeed(category, true, false).then(rec => {
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
        },
        Item {
            Layout.fillWidth: true
        }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: "qrc:/qt/qml/io/github/micro/piki/contents/assets/ranking.svg"
                color: "gold"
                isMask: true
                Layout.preferredHeight: 24
            }
            Controls.Label {
                text: i18n("Rankings")
                font.bold: true
                font.pointSize: 16
            }
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.minimumHeight: row.height + 25

            RowLayout {
                id: row
                spacing: 15

                Repeater {
                    model: page.feed.ranking

                    IllustrationButton {
                        illust: modelData
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }
    }

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
}
