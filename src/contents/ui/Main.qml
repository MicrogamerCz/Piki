// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"

Kirigami.ApplicationWindow {
    id: root
    width: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 30 : Kirigami.Units.gridUnit * 55
    height: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 45 : Kirigami.Units.gridUnit * 40
    title: "Piki"
    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20
    pageStack.anchors.leftMargin: sidebar.x + 250

    property string currentPage: pageStack.currentItem?.title ?? ""

    function buildObject(name, data, parent) {
        let comp = Qt.createComponent(name + ".qml");
        let obj = comp.createObject(parent, data);
        return obj;
    }
    function navigateToPageParm(name, data) {
        pageStack.push(buildObject(name, data, this));
    }
    function navigateToPage(name) {
        navigateToPageParm(name, {});
    }
    function loggedIn(response) {
        let json = JSON.parse(response);
        piqi.SetLogin(json["access_token"], json["refresh_token"]);
        LoginHandler.SetUser(json["user"]["account"]);
        LoginHandler.WriteToken(json["refresh_token"]);
        LoginHandler.SaveUserToCache(JSON.stringify(json["user"]), piqi).then(() => {
            pageStack.pop();
            pageStack.pop();

            piqi.RecommendedFeed("illust", true, true).then(recommended => {
                Cache.SynchroniseIllusts(recommended.illusts);
                navigateToPageParm("Home", {
                    feed: recommended
                });

                sidebar.collapsed = false;
            });
        });
    }

    Component.onCompleted: Cache.Setup().then(() => pageStack.currentItem.beginLoginProcess())

    Piqi {
        id: piqi
    }

    function pushTagAndSearch(tag) {
        hd.selectedTags.append({
            tagData: tag
        });
        hd.pushSearchPage();
    }
    header: Header {
        id: hd
        visible: !sidebar.collapsed
    }
    function getHeaderQuery() {
        const tgs = hd.selectedTags;
        let query = "";
        for (let i = 0; i < tgs.count; i++) {
            query += tgs.get(i).tagData.name + "・";
        }
        return query.slice(0, query.length - 1);
    }

    Kirigami.Separator {
        visible: !sidebar.collapsed
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Sidebar {
        id: sidebar
        height: root.pageStack.height
    }

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    pageStack.columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
    pageStack.initialPage: Loading {}
}
