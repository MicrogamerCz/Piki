// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as Form
import org.kde.kirigamiaddons.components as KIA
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
            Cache.SynchroniseIllusts(others.illusts);
            for (let i = 0; i < others.illusts.length; i++)
                otherIllusts = others;
        });
        if (illust.user.isFollowed > 0)
            piqi.FollowDetail(illust.user).then(details => illust.user.isFollowed = (details.restriction == "private") ? 2 : 1);
        piqi.RelatedIllusts(illust).then(rels => {
            Cache.SynchroniseIllusts(rels.illusts);
            related = rels;
        });
        piqi.IllustSeriesDetails(illust).then(series => {
            page.series = series;
        });
        if (illust.pageCount > 1)
            download(0);
    }

    Instantiator {
        model: Purpose.PurposeAlternativesModel {
            id: alternativesModel
            pluginType: "ShareUrl"
            inputData: {
                'title': page.illust.title,
                'urls': ["https://pixiv.net/artworks/" + page.illust.id]
            }
        }
        delegate: Kirigami.Action {
            property int index
            text: model.display ?? ""
            icon.name: model.iconName

            onTriggered: root.share(alternativesModel, index)
        }
        onObjectAdded: (index, object) => {
            object.index = index;
            contextMenu.contentData.push(object);
        }
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

            ListView {
                anchors.fill: parent
                model: images
                clip: true
                spacing: 15
                cacheBuffer: 1000000

                delegate: Image {
                    required property string url
                    source: url
                    fillMode: Image.PreserveAspectFit
                    width: ListView.view.width
                    retainWhileLoading: true
                    sourceSize.width: page.width * 0.6
                    sourceSize.height: page.height
                }
            }

            Kirigami.AbstractCard {
                z: 5
                visible: (page.illust.pageCount > 1) && (page.illust.pageCount > images.count)
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                contentItem: Controls.ProgressBar {
                    anchors.fill: parent
                    from: 0
                    to: downloader.total
                    value: downloader.progress
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
                        Cache.SynchroniseIllusts(rels.illusts);
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
                    Kirigami.AbstractCard {
                        contentItem: Kirigami.ActionToolBar {
                            Layout.fillWidth: true
                            actions: [
                                FlatAction {
                                    iconName: "view-visible"
                                    text: page.illust.totalView
                                },
                                Kirigami.Action {
                                    separator: true
                                },
                                Kirigami.Action {
                                    checkable: true
                                    checked: page.illust.isBookmarked
                                    text: page.illust.totalBookmarks
                                    icon.name: {
                                        if (page.illust.isBookmarked === 2) {
                                            return "view-private";
                                        } else if (page.illust.isBookmarked === 1) {
                                            return "favorite-favorited";
                                        } else {
                                            return "favorite";
                                        }
                                    }
                                    icon.color: (page.illust.isBookmarked > 0) ? "gold" : Kirigami.Theme.textColor

                                    onTriggered: {
                                        if (page.illust.isBookmarked == 0)
                                            piqi.AddBookmark(page.illust, false);
                                        else
                                            piqi.RemoveBookmark(page.illust);
                                    }
                                },
                                Kirigami.Action {
                                    icon.name: "view-private"

                                    onTriggered: piqi.AddBookmark(page.illust, page.illust.isBookmarked < 2)
                                },
                                Kirigami.Action {
                                    separator: true
                                },
                                Kirigami.Action {
                                    icon.name: "emblem-shared-symbolic"
                                    onTriggered: contextMenu.popup()
                                },
                                // TODO: mute
                                // TODO: report
                                Kirigami.Action {
                                    separator: true
                                },
                                FlatAction {
                                    text: Qt.formatDateTime(page.illust.createDate, "yyyy-MM-dd hh:mm")
                                }
                            ]
                        }
                        Controls.Menu {
                            id: contextMenu
                            Kirigami.Action {
                                enabled: Config.allowR18WorksAsWallpapers != 2
                                text: "Set as wallpaper"
                                icon.name: "viewimage"
                                onTriggered: wallpaperSelections.setup()
                            }
                        }
                    }
                    IllustDetails {
                        illust: page.illust
                    }

                    // Series details
                    Kirigami.AbstractCard {
                        padding: Kirigami.Units.largeSpacing * 2
                        contentItem: ColumnLayout {
                            Kirigami.Heading {
                                text: illust.series.title
                            }

                            Kirigami.AbstractCard {
                                visible: series.illustSeriesContext.next.title != ""

                                showClickFeedback: true
                                contentItem: RowLayout {
                                    PixivImage {
                                        Layout.preferredHeight: 50
                                        Layout.preferredWidth: height
                                        source: series.illustSeriesContext.next.imageUrls.squareMedium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true

                                        Controls.Label {
                                            text: series.illustSeriesContext.next.title
                                        }
                                        Controls.Label {
                                            text: `${series.illustSeriesContext.next.pageCount} page${series.illustSeriesContext.next.pageCount > 1 ? "s" : ""}`
                                        }
                                    }
                                }
                                onClicked: navigateToPageParm("IllustView", {
                                    illust: series.illustSeriesContext.next
                                })
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                uniformCellSizes: true

                                Controls.Button {
                                    Layout.fillWidth: true
                                    flat: true
                                    text: "Add to watchlist"
                                    checkable: true
                                    checked: series.illustSeriesDetail.watchlistAdded
                                }
                                Controls.Button {
                                    Layout.fillWidth: true
                                    flat: true
                                    text: "Previous chapter"
                                }
                                Controls.Button {
                                    Layout.fillWidth: true
                                    flat: true
                                    text: "Series"
                                }
                            }
                        }
                    }

                    // Later improve by using unintended behaviour of the endpoint,
                    // finding if any of the illusts is the opened one
                    // and then show the surrounding illusts
                    ListView {
                        id: flick
                        Layout.fillWidth: true
                        orientation: ListView.Horizontal
                        implicitHeight: contentItem.childrenRect.height + 25
                        spacing: 15
                        clip: true
                        model: otherIllusts

                        delegate: IllustrationButton {
                            required property var modelData
                            illust: modelData
                            topEnabled: modelData.id != page.illust.id
                        }

                        Controls.ScrollBar.horizontal: Controls.ScrollBar {
                            policy: Controls.ScrollBar.AsNeeded
                            anchors.bottom: parent.bottom
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
    WallpaperSelections {
        id: wallpaperSelections
    }
}
