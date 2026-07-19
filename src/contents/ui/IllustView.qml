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
        // if (illust.user.isFollowed > 0) // ? why FollowDetail is missing?
            // piqi.FollowDetail(illust.user).then(details => illust.user.isFollowed = (details.restriction == "private") ? 2 : 1);
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
            Controls.SplitView.minimumWidth: page.width * 0.35
            // Controls.SplitView.maximumWidth: page.width * 0.575
            Controls.SplitView.preferredWidth: page.width * 0.575

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

                    boundsBehavior: ListView.StopAtBounds

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

        Controls.ScrollView {
            Controls.SplitView.fillHeight: true
            Controls.SplitView.minimumWidth: 500
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

            GridView {
                id: relatedIllusts

                property bool loading: false

                boundsBehavior: GridView.StopAtBounds
                clip: true
                cellWidth: 175 + Kirigami.Units.gridUnit // width
                cellHeight: 205 + 45 + Kirigami.Units.gridUnit // top height + bottom height
                delegate: IllustrationButton {}
                model: page.related

                leftMargin: Kirigami.Units.gridUnit
                topMargin: Kirigami.Units.gridUnit
                bottomMargin: Kirigami.Units.gridUnit
                width: parent.availableWidth - leftMargin

                onAtYEndChanged: {
                    if (page.related == null || !atYEnd)
                        return;

                    loading = true;
                    piqi.RelatedIllusts(page.illust).then(rels => {
                        // Cache.SynchroniseIllusts(rels.illusts);
                        page.related.Extend(rels);
                        loading = false;
                    });
                }

                header: ColumnLayout {
                    width: relatedIllusts.width - Kirigami.Units.gridUnit * 2

                    IllustViewProfileCard {
                        user: page.illust.user
                    }
                    IllustToolbar {
                        illust: page.illust
                    }
                    IllustDetails {
                        illust: page.illust
                    }

                    SeriesDetailsCard {
                        illust: page.illust
                        series: page.series
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
                }

                footer: Kirigami.AbstractCard {
                    z: 5
                    visible: relatedIllusts.loading

                    // anchors {
                    // left: parent.left
                    // right: parent.right
                    // bottom: parent.bottom
                    // margins: Kirigami.Units.gridUnit
                    // }

                    contentItem: Controls.ProgressBar {
                        indeterminate: true
                        anchors.fill: parent
                    }
                }
            }
        }
    }
}
