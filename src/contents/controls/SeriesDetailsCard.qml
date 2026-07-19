// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

// import "../controls"

Kirigami.AbstractCard {
    id: sd

    property Illustration illust
    property IllustSeries series

    visible: illust.series.id != 0
    padding: Kirigami.Units.largeSpacing * 2

    contentItem: ColumnLayout {
        Kirigami.Heading {
            text: sd.illust.series.title
        }

        ColumnLayout {
            visible: sd.series?.illustSeriesContext?.next != null
            Kirigami.Heading {
                level: 2
                text: i18n("Next Chapter:")
                color: Kirigami.Theme.disabledTextColor
            }

            Component {
                id: nextSeriesCardComp
                SeriesChapterCard {
                    chapter: sd.series?.illustSeriesContext?.next
                }
            }
            Loader {
                active: sd.series != null
                asynchronous: true
                sourceComponent: nextSeriesCardComp

                Layout.fillWidth: true
            }
        }

        Kirigami.Separator {
            visible: (sd.series?.illustSeriesContext?.prev != null) && (sd.series?.illustSeriesContext?.next != null)
            Layout.fillWidth: true
        }

        ColumnLayout {
            visible: sd.series?.illustSeriesContext?.prev != null
            Kirigami.Heading {
                level: 2
                text: i18n("Previous Chapter:")
                color: Kirigami.Theme.disabledTextColor
            }

            Component {
                id: prevSeriesCardComp
                SeriesChapterCard {
                    chapter: sd.series?.illustSeriesContext?.prev
                }
            }
            Loader {
                active: sd.series != null
                asynchronous: true
                sourceComponent: prevSeriesCardComp

                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            uniformCellSizes: true

            Controls.Button {
                Layout.fillWidth: true
                flat: true
                text: checked ? i18n("In your watchlist") : i18n("Add to watchlist")
                checkable: true
                checked: sd.series?.illustSeriesDetail?.watchlistAdded ?? false

                onClicked: {
                    if (checked)
                        sd.series.illustSeriesDetail.WatchlistAdd();
                    else
                        sd.series.illustSeriesDetail.WatchlistDelete();
                }
            }
            Controls.Button {
                Layout.fillWidth: true
                flat: true
                text: i18n("Series")

                onClicked: {
                    piqi.SeriesFeed(sd.series.illustSeriesDetail.id).then(series => {
                        navigateToPageParm("Series", {
                            feed: series
                        });
                    });
                }
            }
        }
    }
}
