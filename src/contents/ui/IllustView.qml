import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as Form
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"

// TODOs here:
// - adding new comments
// - turning '(emote)' into actual icons (probably UNICODE emotes)
// - change the way comments collapse, make the button visible only when comments > 1
// - (OPTIONAL) fetching more arts from the artist
// - clicking profile header will open profile
// - clicking tags will open a query with that tag

Kirigami.Page {
    id: page
    title: illust.title

    property Illustration illust
    property list<Comment> comments
    property Illusts related: null

    ListModel {
        id: otherIllusts
    }
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
            Cache.SynchroniseIllusts(others);
            for (let i = 0; i < others.length; i++) {
                otherIllusts.append({
                    ilst: others[i]
                });
            }
        });
        if (illust.user.isFollowed > 0)
            piqi.FollowDetail(illust.user).then(details => illust.user.isFollowed = (details.restriction == "private") ? 2 : 1);
        piqi.RelatedIllusts(illust).then(rels => {
            Cache.SynchroniseIllusts(rels.illusts);
            related = rels;
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
                    anchors.rightMargin: (height > page.height) ? sc.width : 0
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    Kirigami.AbstractCard {
                        showClickFeedback: true

                        onClicked: piqi.Details(page.illust.user).then(dtls => root.navigateToPageParm("ProfileView", {
                                details: dtls
                            }))

                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            RowLayout {
                                Layout.margins: Kirigami.Units.mediumSpacing
                                spacing: Kirigami.Units.largeSpacing * 2
                                PixivImage {
                                    Layout.maximumWidth: 20
                                    Layout.maximumHeight: 20
                                    source: page.illust.user.profileImageUrls.medium
                                }
                                Controls.Label {
                                    text: page.illust.user.name
                                    font.bold: true
                                    font.pointSize: 14
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                RequestsCard {
                                    user: page.illust.user
                                }
                            }
                            Controls.Button {
                                Layout.fillWidth: true
                                checkable: true
                                checked: page.illust.user.isFollowed > 0
                                text: checked ? "Following" : "Follow"
                                icon.name: (page.illust.user.isFollowed == 2) ? "view-private" : ""
                                onClicked: {
                                    if (page.illust.user.isFollowed == 0)
                                        piqi.Follow(page.illust.user);
                                    else
                                        piqi.RemoveFollow(page.illust.user);
                                }
                                onPressAndHold: piqi.Follow(page.illust.user, page.illust.user.isFollowed < 2)
                            }
                        }
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
                                    icon.name: (page.illust.isBookmarked < 2) ? "favorite" : "view-private"
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
                                text: "Copy URL"
                                icon.name: "edit-copy-symbolic"
                                onTriggered: {
                                    PikiHelper.ShareToClipboard(page.illust);
                                    showPassiveNotification("Copied to clipboard!");
                                }
                            }
                            Kirigami.Action {
                                enabled: Config.allowR18WorksAsWallpapers != 2
                                text: "Set as wallpaper"
                                icon.name: "viewimage"
                                // TODO: Custom passive notification (+ in the copy url above)
                                onTriggered: wallpaperSelections.setup()
                            }
                        }
                    }
                    IllustDetails {
                        illust: page.illust
                    }

                    // Series details

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
                    // TODO: opening profile by clicking profile card, support for following, support for comms info(?)
                    // TODO: clicking on tabs will open a query
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
    Kirigami.Dialog {
        id: wallpaperSelections
        title: `Set '${page.title}' as Wallpaper`
        preferredWidth: Kirigami.Units.gridUnit * 32
        flatFooterButtons: true

        customFooterActions: [
            Kirigami.Action {
                visible: (wallpaperSelections.requirements > 1) || !restrictCard.visible
                enabled: displayOptions.selectedIndex >= 0
                icon.name: "answer"
                text: "Proceed"
                onTriggered: {
                    wallpaperSelections.close();
                    if (displayOptions.selectedIndex <= 1)
                        PikiHelper.SetWallpaper(page.illust, monitorSelector.value - 1, wallpaperSelections.imageIndex - 1);
                }
            }
        ]

        property int requirements: (page.illust.xRestrict > 0) + (wallpaperSelections.screenCount > 1) + (page.illust.pageCount > 1)
        property alias imageIndex: pageSelector.value
        property int screenCount: 0
        onOpened: {
            screenCount = PikiHelper.GetScreenCount();
            if (page.illust.pageCount > 1)
                pageSelector.refreshPreview();
        }
        function setup() {
            screenCount = PikiHelper.GetScreenCount();
            if (requirements > 0)
                open();
            else
                PikiHelper.SetWallpaper(page.illust);
        }

        Form.FormCardPage {
            topPadding: Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.largeSpacing
            Form.FormCard {
                id: restrictCard
                Layout.bottomMargin: Kirigami.Units.largeSpacing
                visible: (page.illust.xRestrict > 0) && (Config.allowR18WorksAsWallpapers != 1)
                property int option: 0
                property bool singleOption: visible && (wallpaperSelections.requirements == 1)
                Form.FormTextDelegate {
                    text: "R-18 work!"
                    font.bold: true
                    font.pointSize: 13
                }
                Form.FormSectionText {
                    text: `Warning! This work is marked as ${page.illust.xRestrict > 1 ? "R-18G" : "R-18"}! Other people might see this image on your background in public or if you don't properly hide/crop the contents from your screenshots. Do you want to proceed?`
                }
                XWorkAsWallpaperOptions {
                    id: displayOptions
                    onSelectionChanged: {
                        if (restrictCard.singleOption) {
                            wallpaperSelections.close();
                            if (selectedIndex <= 1)
                                PikiHelper.SetWallpaper(page.illust, 0, 0);
                        }
                    }
                }
            }
            Form.FormCard {
                id: pageCard
                Layout.bottomMargin: Kirigami.Units.largeSpacing
                visible: page.illust.pageCount > 1
                Form.FormSpinBoxDelegate {
                    id: pageSelector
                    from: 1
                    to: page.illust.pageCount
                    label: "Which image should be used for the wallpaper?"
                    onValueChanged: refreshPreview()
                    function refreshPreview() {
                        preview.source = images.get(value - 1).url;
                    }
                }
                Form.FormDelegateSeparator {
                    Layout.topMargin: Kirigami.Units.mediumSpacing
                    Layout.bottomMargin: Kirigami.Units.mediumSpacing
                }
                Form.AbstractFormDelegate {
                    enabled: false
                    height: 320
                    PixivImage {
                        id: preview
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        sourceSize.height: 320
                        sourceSize.width: parent.width
                    }
                }
            }
            Form.FormCard {
                id: monitorCard
                visible: wallpaperSelections.screenCount > 1
                Form.FormSpinBoxDelegate {
                    id: monitorSelector
                    from: 1
                    to: Math.max(1, wallpaperSelections.screenCount)
                    label: "Which monitor should have the wallpaper?"
                }
            }
        }
    }
}
