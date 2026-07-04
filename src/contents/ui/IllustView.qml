// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi
import io.github.micro.piki
import "../controls"

Kirigami.Page {
    id: page
    title: illust.title

    property var illust
    property var related: null
    property var otherIllusts: null
    property var series: null

    ListModel {
        id: images
    }

    ImageDownloader {
        id: downloader
    }
    function download(index) {
        downloader.Download(illust.metaPages[index].original).then(img => {
            images.append({
                url: img
            });
            download(index + 1);
        });
    }

    Component.onCompleted: {
        piqi.UserIllusts(illust.user, "illust").then(others => {
            page.otherIllusts = others;
        });
        if (illust.user.isFollowed > 0)
            piqi.FollowDetail(illust.user).then(details => illust.user.isFollowed = (details.restriction == "private") ? 2 : 1);
        piqi.RelatedIllusts(illust).then(rels => {
            related = rels;
        });
        if (illust.series != null)
            piqi.IllustSeriesDetails(illust).then(series => {
                page.series = series;
            });
        if (illust.pageCount > 1)
            download(0);
    }

    Controls.SplitView {
        id: view
        anchors.fill: parent

        Item {
            Controls.SplitView.minimumWidth: page.width * 0.425
            Controls.SplitView.maximumWidth: page.width * 0.575
            Controls.SplitView.preferredWidth: page.width * 0.575

            PixivImage {
                visible: page.illust.pageCount == 1
                source: illust.metaSinglePage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
            }

            Controls.ScrollView {
                anchors.fill: parent
                ListView {
                    model: images
                    clip: true
                    spacing: 15

                    delegate: Image {
                        required property string url
                        source: url
                        fillMode: Image.PreserveAspectFit
                        width: ListView.view.width
                        retainWhileLoading: true
                        asynchronous: true
                        sourceSize.width: page.width * 0.6
                        sourceSize.height: page.height
                    }

                    footerPositioning: ListView.OverlayFooter
                    footer: Kirigami.AbstractCard {
                        z: 5
                        visible: (page.illust.pageCount > 1) && (page.illust.pageCount > images.count)
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: Kirigami.Units.mediumSpacing
                            rightMargin: Kirigami.Units.mediumSpacing
                            bottomMargin: Kirigami.Units.largeSpacing
                        }
                        contentItem: Controls.ProgressBar {
                            anchors.fill: parent
                            from: 0
                            to: downloader.total
                            value: downloader.progress
                        }
                    }
                }
            }
        }

        Item {
            Controls.SplitView.fillHeight: true
            Controls.SplitView.minimumWidth: 300

            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: columnLayout.implicitHeight
                clip: true

                onAtYEndChanged: {
                    if (page.related == null || !atYEnd)
                        return;
                    piqi.RelatedIllusts(page.illust).then(rels => {
                        page.related.Extend(rels);
                    });
                }

                ColumnLayout {
                    id: columnLayout
                    width: parent.width
                    spacing: Kirigami.Units.mediumSpacing
                    anchors.leftMargin: Kirigami.Units.mediumSpacing

                    IllustViewProfileCard {
                        user: page.illust.user
                    }
                    IllustToolbar {
                        illust: page.illust
                    }
                    IllustDetails {
                        illust: page.illust
                    }

                    Kirigami.AbstractCard {
                        visible: page.illust.series.id != 0
                        padding: Kirigami.Units.largeSpacing * 2
                        contentItem: ColumnLayout {
                            Kirigami.Heading {
                                text: page.illust.series.title
                            }

                            ColumnLayout {
                                visible: page.series?.illustSeriesContext?.next != null
                                Kirigami.Heading {
                                    level: 2
                                    text: i18n("Next Chapter:")
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                SeriesChapterCard {
                                    chapter: page.series?.illustSeriesContext?.next
                                }
                            }
                            Kirigami.Separator {
                                visible: (page.series?.illustSeriesContext?.prev != null) && (page.series?.illustSeriesContext?.next != null)
                                Layout.fillWidth: true
                            }
                            ColumnLayout {
                                visible: page.series?.illustSeriesContext?.prev != null
                                Kirigami.Heading {
                                    level: 2
                                    text: i18n("Previous Chapter:")
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                SeriesChapterCard {
                                    chapter: page.series?.illustSeriesContext?.prev
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
                                    checked: page.series?.illustSeriesDetail?.watchlistAdded ?? false

                                    onClicked: {
                                        if (checked)
                                            page.series?.illustSeriesDetail?.WatchlistAdd();
                                        else
                                            page.series?.illustSeriesDetail?.WatchlistDelete();
                                    }
                                }
                                Controls.Button {
                                    Layout.fillWidth: true
                                    flat: true
                                    text: i18n("Series")

                                    onClicked: {
                                        if (!page.series?.illustSeriesDetail) return;
                                        piqi.SeriesFeed(page.series.illustSeriesDetail.id).then(series => {
                                            navigateToPageParm("Series", {
                                                feed: series
                                            });
                                        });
                                    }
                                }
                            }
                        }
                    }

                    CommentSection {
                        illust: page.illust
                    }

                    Controls.ScrollView {
                        Layout.fillWidth: true
                        Layout.minimumHeight: otherIllustsView.implicitHeight
                        implicitHeight: otherIllustsView.implicitHeight
                        contentItem: ListView {
                            id: otherIllustsView
                            orientation: ListView.Horizontal
                            implicitHeight: contentItem.childrenRect.height + 25
                            spacing: 15
                            clip: true
                            model: page.otherIllusts
                            delegate: IllustrationButton {}
                        }
                    }

                    GridView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        cellWidth: 175 + Kirigami.Units.gridUnit
                        cellHeight: 205 + 45 + Kirigami.Units.gridUnit
                        model: page.related
                        delegate: IllustrationButton {}
                    }
                }

                Controls.ScrollBar.vertical: Controls.ScrollBar {}
            }
        }
    }
}
