// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"

// TODOs here:
// - adding new comments
// - turning '(emote)' into actual icons (probably UNICODE emotes)
// - change the way comments collapse, make the button visible only when comments > 1
// - (OPTIONAL) fetching more arts from the artist
// - clicking profile header will open profile

Kirigami.Page {
    id: page
    title: illust.title

    property Illustration illust
    property list<Comment> comments
    property Illusts related: null
    property Illusts otherIllusts: null
    property IllustSeries series: null

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
            // Cache.SynchroniseIllusts(others.illusts);
            for (let i = 0; i < others.illusts.length; i++)
                otherIllusts = others;
        });
        if (illust.user.isFollowed > 0)
            piqi.FollowDetail(illust.user).then(details => illust.user.isFollowed = (details.restriction == "private") ? 2 : 1);
        piqi.RelatedIllusts(illust).then(rels => {
            // Cache.SynchroniseIllusts(rels.illusts);
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
            Controls.SplitView.minimumWidth: page.width * 0.3
            Controls.SplitView.maximumWidth: page.width * 0.7
            Controls.SplitView.preferredWidth: page.width * 0.7

            PixivImage {
                visible: page.illust.pageCount == 1
                source: page.illust.metaSinglePage
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
            Controls.SplitView.minimumWidth: 600
            property bool loading: false
            Flickable {
                anchors.fill: parent
                contentHeight: columnLayout.height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                onAtYEndChanged: {
                    if (page.related == null || !atYEnd)
                        return;

                    parent.loading = true;
                    piqi.RelatedIllusts(page.illust).then(rels => {
                        // Cache.SynchroniseIllusts(rels.illusts);
                        page.related.Extend(rels);
                        loading = false;
                    });
                }

                ColumnLayout {
                    id: columnLayout
                    width: parent.width - page.padding
                    anchors.leftMargin: page.padding
                    anchors.rightMargin: (height > page.height) ? (sc.width + page.padding) : 0
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    IllustViewProfileCard {
                        user: page.illust.user
                    }
                    IllustToolbar {
                        illust: page.illust
                    }
                    IllustDetails {
                        illust: page.illust
                    }

                    // Series details
                    Kirigami.AbstractCard {
                        visible: page.illust.series.id != 0
                        padding: Kirigami.Units.largeSpacing * 2
                        contentItem: ColumnLayout {
                            Kirigami.Heading {
                                text: page.illust.series.title
                            }

                            ColumnLayout {
                                visible: page.series.illustSeriesContext.next != null
                                Kirigami.Heading {
                                    level: 2
                                    text: i18n("Next Chapter:")
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                SeriesChapterCard {
                                    chapter: page.series.illustSeriesContext.next
                                }
                            }
                            Kirigami.Separator {
                                visible: (page.series.illustSeriesContext.prev != null) && (page.series.illustSeriesContext.next != null)
                                Layout.fillWidth: true
                            }
                            ColumnLayout {
                                visible: page.series.illustSeriesContext.prev != null
                                Kirigami.Heading {
                                    level: 2
                                    text: i18n("Previous Chapter:")
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                SeriesChapterCard {
                                    chapter: page.series.illustSeriesContext.prev
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
                                    checked: page.series.illustSeriesDetail.watchlistAdded

                                    onClicked: {
                                        if (checked)
                                            page.series.illustSeriesDetail.WatchlistAdd();
                                        else
                                            page.series.illustSeriesDetail.WatchlistDelete();
                                    }
                                }
                                Controls.Button {
                                    Layout.fillWidth: true
                                    flat: true
                                    text: i18n("Series")

                                    onClicked: {
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

                    // Later improve by using unintended behaviour of the endpoint,
                    // finding if any of the illusts is the opened one
                    // and then show the surrounding illusts
                    Controls.ScrollView {
                        Layout.fillWidth: true
                        Layout.minimumHeight: otherIllustsView.height + effectiveScrollBarHeight
                        implicitHeight: otherIllustsView.implicitHeight

                        contentItem: ListView {
                            id: otherIllustsView
                            orientation: ListView.Horizontal
                            implicitHeight: contentItem.childrenRect.height + 25
                            spacing: 15
                            clip: true
                            model: page.otherIllusts

                            delegate: IllustrationButton {
                                topEnabled: illust.id != page.illust.id
                            }
                        }
                    }

                    CommentSection {
                        illust: page.illust
                    }
                    GridLayout {
                        rowSpacing: 15
                        columnSpacing: 15
                        columns: Math.floor(parent.width / 180)

                        Repeater {
                            model: page.related
                            IllustrationButton {
                                required property var modelData
                                illust: modelData
                                hidden: !page.isCurrentPage
                            }
                        }
                    }
                }

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    id: sc
                    policy: Controls.ScrollBar.AsNeeded
                    anchors.right: parent.right
                }
            }
            Kirigami.AbstractCard {
                z: 5
                visible: parent.loading
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: page.padding
                    rightMargin: (columnLayout.height > page.height) ? sc.width : 0
                }
                contentItem: Controls.ProgressBar {
                    indeterminate: true
                    anchors.fill: parent
                }
            }
        }
    }
}
