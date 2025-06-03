// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
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

    Controls.BusyIndicator {
        id: loadingIndicator
        opacity: 0
        anchors.centerIn: parent
        width: Math.min(page.width, page.height) * 0.5
        height: width

        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.OutQuad
            }
        }
    }
}
