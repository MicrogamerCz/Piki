// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.purpose as Purpose
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
                // Cache.SynchroniseIllusts(recommended.illusts);
                navigateToPageParm("Home", {
                    feed: recommended
                });

                sidebar.collapsed = false;
            });
        });
    }
    function share(model, index) {
        jobView.model = model;
        jobView.index = index;

        jobView.start();
        shareTimer.start();
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
                root.showPassiveNotification("Copied to clipoboard!");
        // else {
        //     print(JSON.stringify(job.data));
        //     print(JSON.stringify(job.output));
        // }
        }
    }
}
