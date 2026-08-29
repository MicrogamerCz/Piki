// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.Page {
    id: page

    function beginLoginProcess() {
        if (!LoginHandler.keyringProviderInstalled) {
            missingSecretsProviderDialog.open();
            return;
        }

        loadingIndicator.opacity = 1;
        LoginHandler.cache = Cache;

        if (Cache.currentUser == null) {
            pushWalkthough()
            return;
        }

        LoginHandler.GetToken().then(token => {
            if (token == "")
                pushWalkthough();
            else
                piqi.Login(token).then(diverge);
        });
    }

    function diverge(result: PiqiResponse) {
        if (result.statusCode == 0) {
            reconnectionInterval.level = 5;
            reconnectionInterval.start();
            noConnectionDialog.open();
        }

        if (noConnectionDialog.opened)
            noConnectionDialog.close();

        if (!result.isSuccessful) {
            pushWalkthough();
            return;
        }

        switch (Config.startupPage) {
        case 0:
            {
                piqi.recommendedFeed("illust", true, true).then(response => {
                    if (response.isSuccessful) {
                        loadingIndicator.opacity = 0;
                        navigateToPageParm("Home", {
                            feed: response.data
                        });
                        sidebar.collapsed = false;
                    } else
                        showResponseError(response);
                });
                break;
            }
        case 1:
            {
                piqi.followingFeed("illust", "all").then(response => {
                    if (response.isSuccessful)
                        navigateToPageParm("Following", {
                            feed: response.data
                        });
                    else
                        showResponseError(response);
                    sidebar.collapsed = false;
                });
                break;
            }
        case 2:
            {
                piqi.watchlistFeed().then(response => {
                    if (response.isSuccessful)
                        navigateToPageParm("Watchlist", {
                            feed: response.data
                        });
                    else
                        showResponseError(response);
                    sidebar.collapsed = false;
                });
                break;
            }
        case 3:
            {
                break;
            }
        case 4:
            {
                piqi.latestGlobal("illust").then(response => {
                    if (response.isSuccessful)
                        navigateToPageParm("Newest", {
                            feed: response.data
                        });
                    else
                        showResponseError(response);
                    sidebar.collapsed = false;
                });
                break;
            }
        case 5:
            {
                piqi.bookmarksFeed(null, false).then(response => {
                    if (response.isSuccessful) {
                        loadingIndicator.opacity = 0;

                        navigateToPageParm("Collection", {
                            feed: response.data
                        });

                        sidebar.collapsed = false;
                    } else
                        showResponseError(response);
                });
                break;
            }
        case 6:
            {
                break;
            }
        }
    }
    function pushWalkthough() {
        piqi.walkthrough().then(response => {
            if (response.isSuccessful) {
                loadingIndicator.opacity = 0;
                root.navigateToPageParm("Welcome", {
                    wkt: response.data
                });
            } else
                showResponseError(response);
        });
    }

    Kirigami.Dialog {
        id: noConnectionDialog
        title: i18n("Failed to connect")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        showCloseButton: false
        onRejected: root.close()
        padding: Kirigami.Units.gridUnit

        contentItem: ColumnLayout {
            anchors.centerIn: parent

            Controls.Label {
                text: i18n("Failed to connect. Piki will try again in a few seconds")
            }
            Kirigami.Heading {
                text: (reconnectionInterval.level > 0) ? reconnectionInterval.level : "Trying to connect..."

                Timer {
                    id: reconnectionInterval
                    running: false
                    interval: 1000
                    onTriggered: level--
                    repeat: true

                    property int level: 5
                    onLevelChanged: {
                        if (level == 0) {
                            page.beginLoginProcess();
                            stop();
                        }
                    }
                }
            }
        }
    }
    Kirigami.PromptDialog {
        id: missingSecretsProviderDialog
        title: i18n("Missing keyring")
        subtitle: i18n("Failed to open keyring implementing 'org.freedesktop.secrets' api (eg. KWallet, Gnome Keyring)\nPiki will work with a single account logged in, without storing session after Piki is closed")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        showCloseButton: false

        onAccepted: {
            loadingIndicator.opacity = 1;
            page.pushWalkthough();
        }
        onRejected: root.close()
    }

    Kirigami.LoadingPlaceholder {
        id: loadingIndicator
        anchors.centerIn: parent
        opacity: 0

        Behavior on opacity {
            SmoothedAnimation {}
        }
    }
}
