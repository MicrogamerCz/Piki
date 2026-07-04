// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.purpose as Purpose
import org.kde.config as KConfig
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"

Kirigami.ApplicationWindow {
    id: root
    width: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 30 : Kirigami.Units.gridUnit * 55
    height: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 45 : Kirigami.Units.gridUnit * 40
    title: i18n("Piki")
    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20
    pageStack.anchors.leftMargin: sidebar.layoutWidth

    property string currentPage: pageStack.currentItem?.title ?? ""
    property bool fullscreenActive: false
    property int _pagesCreated: 0
    property int _pagesDestroyed: 0
    property int _pagesAlive: 0

    property var _compCache: ({})

    function buildObject(name, data, parent) {
        if (!_compCache[name]) {
            _compCache[name] = Qt.createComponent(name + ".qml", Component.PreferSynchronous);
        }
        let obj = _compCache[name].createObject(parent, data);
        _pagesCreated++;
        _pagesAlive++;
        console.log("[MEM] create", name, "| total created:", _pagesCreated, "| alive:", _pagesAlive, "| depth:", pageStack.depth);
        return obj;
    }
    function _logDestroy(name) {
        _pagesDestroyed++;
        _pagesAlive--;
        console.log("[MEM] destroy", name, "| total destroyed:", _pagesDestroyed, "| alive:", _pagesAlive, "| depth:", pageStack.depth);
    }
    function navigateToPageParm(name, data) {
        let oldIdx = pageStack.currentIndex;
        let doomed = [];
        for (let i = pageStack.depth - 1; i > oldIdx; i--) {
            doomed.push(pageStack.get(i));
        }
        pageStack.push(buildObject(name, data, this));
        for (let i = 0; i < doomed.length; i++) {
            _logDestroy(doomed[i].title || "?");
            doomed[i].destroy();
        }
    }
    function navigateToFeed(name, data) {
        for (let i = pageStack.depth - 1; i >= 0; i--) {
            let page = pageStack.get(i);
            if (page) {
                _logDestroy(page.title || "?");
                page.destroy();
            }
        }
        pageStack.clear();
        pageStack.push(buildObject(name, data, this));
    }
    function navigateToFeed(name, data) {
        pageStack.clear();
        pageStack.push(buildObject(name, data, this));
    }
    function navigateToPage(name) {
        navigateToPageParm(name, {});
    }
    function goBack() {
        if (pageStack.currentIndex > 0) {
            pageStack.currentIndex--;
            console.log("[MEM] goBack → idx:", pageStack.currentIndex, "/ depth:", pageStack.depth, "| alive:", _pagesAlive);
        }
    }
    function goForward() {
        if (pageStack.currentIndex < pageStack.depth - 1) {
            pageStack.currentIndex++;
            console.log("[MEM] goForward → idx:", pageStack.currentIndex, "/ depth:", pageStack.depth, "| alive:", _pagesAlive);
        }
    }
    function loggedIn(response) {
        let json = JSON.parse(response);
        piqi.SetLogin(json["access_token"], json["refresh_token"]);
        LoginHandler.SetUser(json["user"]["account"]).then(() => {
            LoginHandler.WriteToken(json["refresh_token"]).then(() => {
                LoginHandler.SaveUserToCache(JSON.stringify(json["user"]), piqi).then(() => {
                    let p1 = pageStack.currentItem; pageStack.pop();
                    if (p1) { _logDestroy(p1.title || "login"); p1.destroy(); }
                    let p2 = pageStack.currentItem; pageStack.pop();
                    if (p2) { _logDestroy(p2.title || "welcome"); p2.destroy(); }

                    piqi.RecommendedFeed("illust", true, true).then(recommended => {
                        // Cache.SynchroniseIllusts(recommended.illusts);
                        navigateToPageParm("Home", {
                            feed: recommended
                        });

                        sidebar.collapsed = false;
                    });
                });
            });
        });
    }
    function share(model, index) {
        jobView.model = model;
        jobView.index = index;

        jobView.start();
        shareTimer.start();
    }

    Component.onCompleted: Cache.Setup().then(pageStack.currentItem.beginLoginProcess)

    Piqi {
        id: piqi
    }

    KConfig.WindowStateSaver {
        configGroupName: "Window"
    }

    function pushTagAndSearch(tag) {
        hd.selectedTags.append({
            tagData: tag
        });
        hd.pushSearchPage();
    }
    header: Header {
        id: hd
        visible: true
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
        visible: true
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
    pageStack.columnView.interactive: false
    pageStack.initialPage: Loading {}

    Rectangle {
        z: 1000
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        width: 260; height: 160
        color: "#CC000000"
        radius: 6

        Column {
            anchors { fill: parent; margins: 8 }
            spacing: 4

            Text { text: "[MEM DEBUG]"; color: "#FF0"; font.bold: true; font.pointSize: 10 }
            Text { color: "white"; font.pointSize: 9
                text: "created: " + _pagesCreated + "  destroyed: " + _pagesDestroyed + "  alive: " + _pagesAlive
            }
            Text { color: "white"; font.pointSize: 9
                text: "stack depth: " + pageStack.depth + "  current idx: " + pageStack.currentIndex
            }
            Text { color: "white"; font.pointSize: 9
                text: "current page: " + (pageStack.currentItem?.title ?? "none")
            }
            Text { color: "#AAA"; font.pointSize: 8
                text: "component cache: " + Object.keys(_compCache).length
            }
        }
    }

    function showFullscreen(metaPages, metaSinglePage, pageCount) {
        if (root.fullscreenActive)
            return;
        root.fullscreenActive = true;

        let comp = Qt.createComponent("FullscreenView.qml");
        let create = function() {
            let item = comp.createObject(root, {
                z: 999,
                metaPages: metaPages,
                metaSinglePage: metaSinglePage,
                pageCount: pageCount
            });
            if (!item) {
                root.fullscreenActive = false;
                return;
            }
            item.x = 0;
            item.y = root.header.height;
            item.width = Qt.binding(function() { return root.width; });
            item.height = Qt.binding(function() { return root.height - root.header.height; });
            item.onClose = function() { root.fullscreenActive = false; };
        };
        if (comp.status === Component.Ready)
            create();
        else if (comp.status === Component.Error)
            root.fullscreenActive = false;
        else
            comp.statusChanged.connect(function() {
                if (comp.status === Component.Ready)
                    create();
                else if (comp.status === Component.Error)
                    root.fullscreenActive = false;
            });
    }

    Kirigami.Dialog {
        id: shareDialog
        implicitWidth: jobView.implicitWidth * 2
        implicitHeight: jobView.implicitHeight * 2

        contentItem: Purpose.JobView {
            id: jobView
            anchors.fill: parent

            implicitWidth: Kirigami.Units.gridUnit * 20
            implicitHeight: Kirigami.Units.gridUnit * 14

            onStateChanged: {
                if (state === Purpose.PurposeJobController.Finished) {
                    shareDialog.showNotification(job);
                    shareDialog.close();
                } else if (state === Purpose.PurposeJobController.Error) {
                    // TOOD: Show notification when share fails
                    shareDialog.close();
                } else if (state === Purpose.PurposeJobController.Cancelled) {
                    shareDialog.close();
                }
            }
        }

        Timer {
            id: shareTimer
            interval: 50 // Just a tiny interval to find out whether the job is visual (such as the QR code)
            //              or whether it does stuff in the background (Sending via KDE Connect, Tokodon, etc.)
            repeat: false

            onTriggered: {
                print(jobView.state);
                if (jobView.state === Purpose.PurposeJobController.Configuring)
                    shareDialog.open();
            }
        }

        function showNotification(job) {
            let type = String(job);
            if (type.startsWith("ClipboardJob"))
                root.showPassiveNotification(i18n("Copied to clipoboard!"));
            // else {
            //     print(JSON.stringify(job.data));
            //     print(JSON.stringify(job.output));
            // }
        }
    }
}
