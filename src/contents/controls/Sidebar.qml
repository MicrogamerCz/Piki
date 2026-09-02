// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Rectangle {
    id: sidebar
    width: 250
    clip: true
    x: collapsed ? -width : 0
    color: "transparent"

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    property bool reloadingAccount: false
    readonly property string currentPage: root.currentPage
    property bool collapsed: true

    function switchAccount(data) {
        reloadingAccount = true;
        Cache.setCurrentUser(data).then(() => {
            if (LoginHandler.keyringProviderInstalled)
                LoginHandler.GetToken().then(token => {
                    piqi.login(token).then(response => {
                        if (!response.isSuccessful) {
                            showResponseError(response);
                            return;
                        }
                        pageStack.currentItem.refresh();
                        reloadingAccount = false;
                    });
                });
        });
    }
    function removeAccount(data) {
        reloadingAccount = true;
        Cache.removeUser(data ?? piqi.user).then(() => {
            if (Cache.otherUsers.length > 0)
                switchAccount(LoginHandler.otherUsers[0]);
            else {
                piqi.walkthrough().then(response => {
                    if (!response.isSuccessful) {
                        showResponseError(response);
                        return;
                    }
                    reloadingAccount = false;
                    accountDialog.close();
                    sidebar.collapsed = true;
                    navigateToPageParm("Welcome", {
                        wkt: response.data
                    });
                });
            }
        });
    }

    Behavior on x {
        NumberAnimation {
            easing.type: Easing.OutCubic
        }
    }
    Kirigami.Separator {
        height: parent.height
        anchors.right: parent.right
        z: 100
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Controls.ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true

            Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

            ColumnLayout {
                id: column
                width: scrollView.width
                spacing: 0

                SidebarButton {
                    text: i18n("Home")
                    icon.name: "go-home-symbolic"
                    matchPart: true
                    onClicked: {
                        loading = true;
                        piqi.recommendedFeed("illust", true, true).then(response => {
                            if (response.isSuccessful)
                                navigateToPageParm("Home", {
                                    feed: response.data
                                });
                            else
                                showResponseError(response);
                            loading = false;
                        });
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    Layout.leftMargin: Kirigami.Units.mediumSpacing
                }
                SidebarButton {
                    text: i18n("Following")
                    icon.name: "group"
                    matchPart: true
                    onClicked: {
                        loading = true;
                        piqi.followingFeed("illust", "all").then(response => {
                            if (response.isSuccessful)
                                navigateToPageParm("Following", {
                                    feed: response.data
                                });
                            else
                                showResponseError(response);
                            loading = false;
                        });
                    }
                }
                SidebarButton {
                    text: i18n("Watchlist")
                    icon.name: "view-visible"
                    matchPart: true

                    onClicked: {
                        loading = true;
                        piqi.watchlistFeed().then(response => {
                            if (response.isSuccessful)
                                navigateToPageParm("Watchlist", {
                                    feed: response.data
                                });
                            else
                                showResponseError(response);
                            loading = false;
                        });
                    }
                }
                SidebarButton {
                    text: i18n("My pixiv")
                    icon.source: "qrc:/qt/qml/io/github/micro/piki/contents/assets/io.github.microgamercz.piki.svg"
                    matchPart: true

                    enabled: false
                }
                SidebarButton {
                    text: i18n("Newest")
                    icon.name: "view-pim-news"
                    matchPart: true

                    onClicked: {
                        loading = true;
                        piqi.latestGlobal("illust").then(response => {
                            if (response.isSuccessful)
                                navigateToPageParm("Newest", {
                                    feed: response.data
                                });
                            else
                                showResponseError(response);
                            loading = false;
                        });
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    Layout.leftMargin: Kirigami.Units.mediumSpacing
                }
                SidebarButton {
                    text: i18n("Bookmarks")
                    icon.name: "bookmarks"
                    matchPart: true

                    onClicked: {
                        loading = true;
                        piqi.bookmarksFeed(null, false).then(response => {
                            if (response.isSuccessful)
                                navigateToPageParm("Collection", {
                                    feed: response.data
                                });
                            else
                                showResponseError(response);
                            loading = false;
                        });
                    }
                }
                SidebarButton {
                    text: i18n("History")
                    icon.name: "view-history"
                    matchPart: true

                    enabled: false
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.smallSpacing
        }
        SidebarButton {
            text: piqi.user?.name ?? ""
            icon.source: (piqi.user == null) ? accountDialog.defaultPfp : piqi.user?.profileImageUrls?.px50 ?? ""
            onPressAndHold: {
                if (LoginHandler.keyringProviderInstalled)
                    accountDialog.open();
            }
            onClicked: {
                loading = true;
                piqi.details(piqi.user).then(response => {
                    if (response.isSuccessful)
                        root.navigateToPageParm("ProfileView", {
                            details: response.data
                        });
                    else
                        showResponseError(response);
                    loading = false;
                });
            }

            Controls.Button {
                visible: !parent.loading && LoginHandler.keyringProviderInstalled
                flat: true
                icon.name: "folder-image-people-symbolic"
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    margins: Kirigami.Units.largeSpacing
                }
                onClicked: accountDialog.open()
            }
        }
        SidebarButton {
            text: i18n("Settings")
            icon.name: "configure"
            onClicked: root.navigateToPage("Settings")
        }
    }

    AccountsManager {
        id: accountDialog

        reloadingAccount: sidebar.reloadingAccount
    }
}
