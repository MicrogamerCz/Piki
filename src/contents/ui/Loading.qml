// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import io.github.micro.piki

Kirigami.Page {
    id: page

    function beginLoginProcess() {
        loadingIndicator.opacity = 1;
        LoginHandler.SetCacheIfNotExists(Cache).then(() => {
            let token = LoginHandler.GetToken();
            if (token == "")
                pushWalkthough();
            else
                piqi.Login(token).then(diverge);
        });
    }

    function diverge(result) {
        if (result)
            switch (Config.startupPage) {
            case 0:
                {
                    piqi.RecommendedFeed("illust", true, true).then(recommended => {
                        Cache.SynchroniseIllusts(recommended.illusts);
                        loadingIndicator.opacity = 0;
                        navigateToPageParm("Home", {
                            feed: recommended
                        });
                        sidebar.collapsed = false;
                    });
                    break;
                }
            case 1:
                {
                    piqi.FollowingFeed("illust", "all").then(following => {
                        Cache.SynchroniseIllusts(following.illusts);
                        navigateToPageParm("Following", {
                            feed: following
                        });
                        sidebar.collapsed = false;
                    });
                    break;
                }
            case 2:
                {
                    break;
                }
            case 3:
                {
                    break;
                }
            case 4:
                {
                    piqi.LatestGlobal("illust").then(latest => {
                        Cache.SynchroniseIllusts(latest.illusts);
                        navigateToPageParm("Newest", {
                            feed: latest
                        });
                        sidebar.collapsed = false;
                    });
                    break;
                }
            case 5:
                {
                    piqi.BookmarksFeed("illust", false).then(bkmarks => {
                        Cache.SynchroniseIllusts(bkmarks.illusts);
                        loadingIndicator.opacity = 0;
                        navigateToPageParm("Collection", {
                            feed: bkmarks
                        });

                        sidebar.collapsed = false;
                    });
                    break;
                }
            case 6:
                {
                    break;
                }
            }
        else
            pushWalkthough();
    }
    function pushWalkthough() {
        piqi.Walkthrough().then(walkthrough => {
            loadingIndicator.opacity = 0;
            root.navigateToPageParm("Welcome", {
                wkt: walkthrough
            });
        });
    }

    Kirigami.LoadingPlaceholder {
        id: loadingIndicator

        anchors.centerIn: parent

        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.OutQuad
            }
        }
    }
}
