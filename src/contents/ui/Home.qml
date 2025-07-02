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
    title: `Home ・ ${categories.label}`
    onRefresh: refreshF()

    property string category: "illust"
    onCategoryChanged: refreshF()
    property Recommended feed

    function refreshF() {
        loading = true;
        piqi.RecommendedFeed(category, true, false).then(rec => {
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

    RowLayout {
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
        }
        Controls.BusyIndicator {
            visible: page.loading
        }
    }

    /*PremiumBanner {
        visible: Config.enablePremiumSuggestions && !piqi.user.isPremium
        }*/

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
                text: "Rankings"
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
                    model: page.feed.rankingIllusts
                    IllustrationButton {
                        required property var modelData
                        illust: modelData
                    }
                }
            }
        }
    }

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
