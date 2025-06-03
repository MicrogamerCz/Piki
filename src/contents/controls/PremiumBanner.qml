// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls

Rectangle {
    property bool closed: false
    clip: true
    Layout.fillWidth: true
    Layout.preferredHeight: closed ? 0 : 200
    opacity: closed ? 0 : 1
    radius: 8

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 15

        Controls.Label {
            Layout.alignment: Qt.AlignHCenter
            color: "white"
            font.bold: true
            font.pointSize: 28
            text: "Get 1 month of pixiv Premium for FREE"
        }
        Controls.Label {
            Layout.alignment: Qt.AlignHCenter
            color: "white"
            font.bold: true
            font.pointSize: 15
            text: "Enjoy pixiv even more with convenient features such as Search by popularity and Hide ads."
        }
        Controls.AbstractButton {
            Layout.alignment: Qt.AlignHCenter
            verticalPadding: 10
            horizontalPadding: 20
            background: Rectangle {
                color: "white"
                radius: 999
            }
            contentItem: Text {
                text: "Start free trial"
                color: "#FDAA32"
                font.bold: true
                font.pointSize: 11
            }
        }
    }

    Image {
        anchors {
            left: parent.left
            bottom: parent.bottom
            bottomMargin: -20
            leftMargin: 50
        }
        source: "../assets/premium_1.svg"
    }
    Image {
        anchors {
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 30
            rightMargin: 70
        }
        source: "../assets/premium_2.svg"
    }

    Rectangle {
        rotation: -45
        height: 32
        width: 164
        y: 20
        x: -48

        Text {
            anchors.centerIn: parent
            text: "Exclusive"
            color: "#FDAA32"
            font.bold: true
            font.pointSize: 12
            renderType: Text.CurveRendering
        }
    }

    Controls.AbstractButton {
        anchors {
            top: parent.top
            right: parent.right
            margins: 20
        }

        contentItem: Kirigami.Icon {
            width: 5
            height: 5
            color: "white"
            source: "dialog-close"
        }

        onClicked: parent.closed = true
    }

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: "#ffc61a"
        }
        GradientStop {
            position: 1.0
            color: "#ff9f1a"
        }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 200
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }
}
