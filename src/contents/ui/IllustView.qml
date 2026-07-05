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

    ImageDownloader {
        id: downloader
    }

    function downloadCurrent() {
        var targetDir = Config.downloadPath || "";
        if (targetDir === "") {
            root.showPassiveNotification(i18n("Download path not set. Set it in Settings."));
            return;
        }
        if (page.illust.pageCount > 1) {
            downloadPage(0, targetDir);
        } else {
            var url = page.illust.metaSinglePage;
            var name = url.substring(url.lastIndexOf("/") + 1);
            PikiHelper.downloadToDir(url, targetDir, name).then(function(ok) {
                root.showPassiveNotification(i18n("Image saved"));
            });
        }
    }
    function downloadPage(index, targetDir) {
        if (index >= page.illust.pageCount) {
            root.showPassiveNotification(i18np("1 page saved", "%1 pages saved", page.illust.pageCount));
            return;
        }
        var url = page.illust.metaPages[index].original;
        var name = url.substring(url.lastIndexOf("/") + 1);
        PikiHelper.downloadToDir(url, targetDir, name).then(function(ok) {
            downloadPage(index + 1, targetDir);
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
    }

    Controls.SplitView {
        id: view
        anchors.fill: parent

        Item {
            Controls.SplitView.minimumWidth: page.width * 0.425
            Controls.SplitView.maximumWidth: page.width * 0.575
            Controls.SplitView.preferredWidth: page.width * 0.575

            PixivImage {
                id: mainImage
                visible: page.illust.pageCount == 1
                source: illust.metaSinglePage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
            }

            ListView {
                id: pagesView
                visible: page.illust.pageCount > 1
                anchors.fill: parent
                model: page.illust.metaPages
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                clip: true

                delegate: PixivImage {
                    required property var modelData
                    source: modelData.original
                    fillMode: Image.PreserveAspectFit
                    width: ListView.view.width
                    height: ListView.view.height
                }
            }

            Row {
                id: pageDots
                visible: page.illust.pageCount > 1
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: Kirigami.Units.gridUnit
                }
                spacing: Kirigami.Units.smallSpacing

                property int currentIndex: pagesView.width > 0 ?
                    Math.round(pagesView.contentX / pagesView.width) : 0

                Repeater {
                    model: page.illust.pageCount

                    delegate: Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: (index === pageDots.currentIndex) ?
                            Kirigami.Theme.highlightColor :
                            Kirigami.Theme.textColor
                        opacity: (index === pageDots.currentIndex) ? 1.0 : 0.4
                    }
                }
            }

            Controls.RoundButton {
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: Kirigami.Units.mediumSpacing
                }
                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 2
                flat: true
                onClicked: root.showFullscreen(
                    page.illust.metaPages,
                    page.illust.metaSinglePage,
                    page.illust.pageCount
                )
                background: Rectangle {
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.7
                    radius: width / 2
                }
                contentItem: Item {
                    Controls.Label {
                        anchors.centerIn: parent
                        text: "\u26F6"
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 14
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
