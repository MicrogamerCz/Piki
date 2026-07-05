// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
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
    pageStack.anchors.leftMargin: sidebar.width

    property string currentPage: pageStack.currentItem?.title ?? ""

    function buildObject(name, data, parent) {
        let comp = Qt.createComponent(name + ".qml");
        let obj = comp.createObject(parent, data);
        return obj;
    }
    function navigateToPageParm(name, data) {
        pageStack.push(buildObject(name, data, this));
    }
    function navigateToFeed(name, data) {
        pageStack.clear();
        pageStack.push(buildObject(name, data, this));
    }
    function navigateToPage(name) {
        navigateToPageParm(name, {});
    }
    function loggedIn(response) {
        let json = JSON.parse(response);
        piqi.SetLogin(json["access_token"], json["refresh_token"]);
        LoginHandler.SetUser(json["user"]["account"]).then(() => {
            LoginHandler.WriteToken(json["refresh_token"]).then(() => {
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
    pageStack.initialPage: Loading {}

    property bool fullscreenActive: false
    property var fullscreenMetaPages: null
    property string fullscreenImage: ""
    property int fullscreenPageCount: 0

    function showFullscreen(pages, singleUrl, pageCount) {
        fullscreenMetaPages = pages;
        fullscreenImage = singleUrl;
        fullscreenPageCount = pageCount;
        fullscreenActive = true;
    }

    Rectangle {
        visible: fullscreenActive
        anchors.fill: parent
        color: "black"
        z: 100
        focus: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
        Keys.onEscapePressed: fullscreenActive = false

        ListView {
            visible: fullscreenPageCount > 1
            anchors.fill: parent
            model: fullscreenMetaPages
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            clip: true

            delegate: Image {
                required property var modelData
                source: modelData.original
                fillMode: Image.PreserveAspectFit
                width: ListView.view.width
                height: ListView.view.height
                asynchronous: true
            }
        }

        Image {
            visible: fullscreenPageCount <= 1 && fullscreenImage != ""
            anchors.fill: parent
            source: fullscreenImage
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Controls.RoundButton {
            anchors {
                top: parent.top
                right: parent.right
                margins: Kirigami.Units.gridUnit
            }
            width: Kirigami.Units.gridUnit * 2
            height: Kirigami.Units.gridUnit * 2
            flat: true
            onClicked: fullscreenActive = false
            background: Rectangle {
                color: "#333333"
                opacity: 0.8
                radius: width / 2
            }
            contentItem: Item {
                Controls.Label {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 16
                    color: "white"
                }
            }
        }
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
