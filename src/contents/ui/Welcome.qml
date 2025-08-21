// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.Page {
    id: page
    padding: 0

    property Illusts wkt
    function runWalkthrough(i) {
        let il = wkt.illusts[i];
        downloader.Download(il.imageUrls.squareMedium).then(url => {
            walkthrough.append({
                "url": url
            });
            runWalkthrough(i + 1);
        });
    }

    Component.onCompleted: {
        runWalkthrough(0);
        overlay.opacity = 0.6;
        gridAnim.start();
        init.start();
    }
    Timer {
        id: init
        interval: 500 // Should be enough. Althrough this page has better effect as an overlay
        onTriggered: cardfadein.start()
    }

    ListModel {
        id: walkthrough
    }
    ImageDownloader {
        id: downloader
    }
    GridView {
        id: grid
        clip: true
        anchors.fill: parent
        cellWidth: (page.width / grid.columns)
        cellHeight: cellWidth
        model: walkthrough
        interactive: false

        onAtYEndChanged: {
            if (atYEnd)
                gridAnim.pause();
            else
                gridAnim.resume();
        }

        readonly property int columns: Math.round(page.width / 350)

        delegate: Image {
            required property int index
            required property var model
            property int row: Math.floor(index / grid.columns)
            property int oY: row * width
            width: grid.cellWidth
            height: grid.cellHeight
            source: model.url
        }
        add: Transition {
            NumberAnimation {
                property: "y"
                from: page.height
                to: oY
                duration: 1250
                easing.type: Easing.OutCubic
            }
        }
        NumberAnimation on contentY {
            id: gridAnim
            property int move: 0
            from: move
            to: move + 500
            onFinished: {
                move = move + 500;
                start();
            }
            duration: 10000
        }
    }
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "black"
        opacity: 0// 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutQuad
            }
        }
    }
    Kirigami.AbstractCard {
        id: welcomeCard
        anchors.horizontalCenter: parent.horizontalCenter
        width: 400
        height: 600
        clip: true

        y: page.height
        property int bY: (page.height - height) * 0.5

        Controls.SwipeView {
            id: view
            clip: true
            anchors {
                margins: 15
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: indicators.top
            }
            property bool isLastIndex: currentIndex == (count - 1)
            onIsLastIndexChanged: indicatorsAnimator.start()

            Item {
                ColumnLayout {
                    uniformCellSizes: true
                    anchors.centerIn: parent
                    Image {
                        sourceSize.width: 150
                        Layout.preferredWidth: 150
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/io.github.microgamercz.piki.svg"
                        Layout.alignment: Qt.AlignCenter
                    }
                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
                        font.bold: true
                        font.pixelSize: 24
                        text: i18n("Welcome to piki")
                    }
                }
            }
            Item {
                ColumnLayout {
                    uniformCellSizes: true
                    anchors.centerIn: parent
                    Image {
                        sourceSize.width: 150
                        Layout.preferredWidth: 150
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/folder-paint-symbolic.svg"
                        Layout.alignment: Qt.AlignCenter
                    }
                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: i18n("Illustrations, manga, and novels.\nYou can find them all on pixiv.")
                    }
                }
            }
            Item {
                ColumnLayout {
                    uniformCellSizes: true
                    anchors.centerIn: parent
                    Image {
                        sourceSize.width: 150
                        Layout.preferredWidth: 150
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/favorites-symbolic.svg"
                        Layout.alignment: Qt.AlignCenter
                    }
                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: i18n("Here, you are bound to find\nsomething you like.")
                    }
                }
            }
            Item {
                ColumnLayout {
                    uniformCellSizes: true
                    anchors.centerIn: parent
                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: i18n("Find something you like")
                    }
                    Controls.Button {
                        text: i18n("Login")
                        onClicked: navigateToPage("Login")
                    }
                }
            }
        }

        RowLayout {
            id: indicators
            uniformCellSizes: true
            anchors {
                left: parent.left
                bottom: parent.bottom
                right: parent.right
                margins: 15
            }

            Controls.Button {
                flat: true
                text: i18n("Skip")
                padding: 2
                onClicked: view.currentIndex = view.count - 1
            }
            Controls.PageIndicator {
                id: indicator
                count: view.count
                currentIndex: view.currentIndex
                Layout.alignment: Qt.AlignHCenter
            }
            Controls.Button {
                flat: true
                text: i18n("Next")
                padding: 2
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    if (!view.isLastIndex)
                        view.currentIndex++;
                }
            }

            NumberAnimation on anchors.bottomMargin {
                id: indicatorsAnimator
                running: false
                from: view.isLastIndex ? (-indicators.height) : 15
                to: !view.isLastIndex ? (-indicators.height) : 15
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        NumberAnimation on y {
            id: cardfadein
            running: false
            from: page.height
            to: (page.height - welcomeCard.height) * 0.5
            duration: 1400
            onFinished: welcomeCard.anchors.centerIn = welcomeCard.parent
            easing.type: Easing.OutExpo
        }
    }
}
