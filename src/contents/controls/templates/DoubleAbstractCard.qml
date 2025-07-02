// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls

Rectangle {
    id: ilb
    height: topHeight + bottomHeight + 3

    property alias topEnabled: delegateTop.hoverEnabled
    property alias topHeight: delegateTop.height
    property alias topItem: delegateTop.contentItem
    signal topItemClicked
    property alias bottomEnabled: delegateBottom.hoverEnabled
    property alias bottomHeight: delegateBottom.height
    property alias bottomItem: delegateBottom.contentItem
    signal bottomItemClicked

    property color defaultColor: Kirigami.Theme.backgroundColor
    property color hoverColor: Kirigami.ColorUtils.tintWithAlpha(defaultColor, Kirigami.Theme.highlightColor, 0.1)
    property color pressedColor: Kirigami.ColorUtils.tintWithAlpha(defaultColor, Kirigami.Theme.highlightColor, 0.3)

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    color: defaultColor
    border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
    radius: Kirigami.Units.cornerRadius
    clip: true

    Column {
        anchors.margins: 1
        anchors.fill: parent

        Controls.ItemDelegate {
            id: delegateTop
            anchors {
                left: parent.left
                right: parent.right
            }
            onClicked: ilb.topItemClicked()

            background: Rectangle {
                anchors.fill: parent
                topLeftRadius: ilb.radius
                topRightRadius: ilb.radius
                color: delegateTop.down ? ilb.pressedColor : (delegateTop.hovered ? ilb.hoverColor : ilb.defaultColor)
            }
        }
        Kirigami.Separator {
            anchors {
                left: parent.left
                right: parent.right
            }
        }
        Controls.ItemDelegate {
            id: delegateBottom
            anchors {
                left: parent.left
                right: parent.right
            }
            onClicked: ilb.bottomItemClicked()

            background: Rectangle {
                anchors.fill: parent
                bottomLeftRadius: ilb.radius
                bottomRightRadius: ilb.radius
                color: delegateBottom.down ? ilb.pressedColor : (delegateBottom.hovered ? ilb.hoverColor : ilb.defaultColor)
            }
        }
    }
}
