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
    pageStack.anchors.leftMargin: sidebar.x + 250

    property string currentPage: pageStack.currentItem?.title ?? ""

    readonly property var httpStatusCodes: ({
            403: i18n("Forbidden"),
            429: i18n("Too Many Requests")
        })

    function showResponseError(response: PiqiResponse) {
        if (response.isSuccessful)
            return;

        // TODO: if status code is 429, show warning about fast browsing and give a minute long grace period before allowing any browsing
        const description = httpStatusCodes[response.statusCode];
        const suffix = description ? ` ${response.statusCode} - ${description})` : ` (${response.statusCode}`;
        showPassiveNotification(JSON.stringify(response.body) + suffix);

        if (response.statusCode == 429)
            spamTimeoutDialog.open()
        // const suffix = description ? ` (${response.statusCode} - ${description})` : ` (${response.statusCode})`;
        // showPassiveNotification(i18n("Network error: ") + suffix);
    }

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
        piqi.setLogin(json["access_token"], json["refresh_token"]);
        if (!LoginHandler.keyringProviderInstalled)
            return;

        let user = new PikiUser(json["user"]);
        Cache.setCurrentUser(user).then(() => {
            LoginHandler.WriteToken(json["refresh_token"]).then(() => {
                pageStack.pop();
                pageStack.pop();

                piqi.recommendedFeed("illust", true, true).then(response => {
                    if (response.isSuccessful)
                        navigateToPageParm("Home", {
                            feed: response.data
                        });
                    else
                        showResponseError(response);

                    sidebar.collapsed = false;
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

    Component.onCompleted: Cache.setup().then(pageStack.currentItem.beginLoginProcess)

    Piqi {
        id: piqi
    }

    KConfig.WindowStateSaver {
        configGroupName: "Window"
    }

    function pushTagAndSearch(tag) {
        Cache.selectedTags.append(tag);
        hd.pushSearchPage();
    }
    header: Header {
        id: hd
        visible: !sidebar.collapsed
    }
    function getHeaderQuery() {
        const tgs = Cache.selectedTags;
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

    Kirigami.PromptDialog {
        id: spamTimeoutDialog
        closePolicy: Kirigami.Dialog.NoAutoClose
        standardButtons: Kirigami.Dialog.NoButton
        showCloseButton: false

        title: "Too many requests"
        subtitle: `You have done too many actions in a short timespan.\nPixiv API will not work for approx. ${Math.round(timeoutProgress.value / 1000)}s`

        onOpened: timeoutAnimation.restart()

        Controls.ProgressBar {
            id: timeoutProgress
            from: 0
            to: timeoutAnimation.duration

            anchors {
                left: parent.left
                right: parent.right
            }

            NumberAnimation on value {
                id: timeoutAnimation
                duration: 180000

                from: duration
                to: 0

                onFinished: spamTimeoutDialog.close()
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
