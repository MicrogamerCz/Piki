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
            piqi.RecommendedFeed("illust", true, true).then(recommended => {
                Cache.SynchroniseIllusts(recommended.illusts);
                loadingIndicator.opacity = 0;
                navigateToPageParm("Home", {
                    feed: recommended
                });

                sidebar.collapsed = false;
            });
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
