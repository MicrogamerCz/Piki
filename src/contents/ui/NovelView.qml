// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components
import org.kde.kquickcontrols
import io.github.micro.piki

Kirigami.ScrollablePage {
    id: page
    padding: 0
    title: np.title

    property string novel
    onNovelChanged: np.loadNovel(novel)

    readonly property int minMargin: 5
    readonly property int maxMargin: 35
    property real displayMargin: minMargin

    property color viewTextColor: Kirigami.Theme.textColor
    property color viewBackgroundColor: Kirigami.Theme.backgroundColor

    NovelProcessor {
        id: np
    }

    background: Rectangle {
        color: page.viewBackgroundColor
        anchors.fill: parent
    }

    Kirigami.SelectableLabel {
        id: novelBody
        text: np.text
        color: page.viewTextColor

        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit
        anchors.bottomMargin: Kirigami.Units.gridUnit
        anchors.leftMargin: page.displayMargin * Kirigami.Units.gridUnit
        anchors.rightMargin: page.displayMargin * Kirigami.Units.gridUnit
    }

    FloatingToolBar {
        parent: page.overlay
        padding: Kirigami.Units.largeSpacing
        anchors {
            bottom: parent.bottom
            margins: Kirigami.Units.gridUnit
            horizontalCenter: parent.horizontalCenter
        }

        contentItem: Kirigami.ActionToolBar {
            actions: [
                Kirigami.Action {
                    displayComponent: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Controls.Label {
                            text: "Display width:"
                        }
                        Controls.Slider {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                            from: page.minMargin
                            to: page.maxMargin
                            stepSize: 1
                            value: page.displayMargin
                            onValueChanged: page.displayMargin = value
                        }
                        Controls.Label {
                            text: page.maxMargin - page.displayMargin
                        }
                    }
                },
                Kirigami.Action {
                    separator: true
                },
                Kirigami.Action {
                    displayComponent: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Controls.Label {
                            text: "Text color:"
                        }
                        ColorButton {
                            color: page.viewTextColor
                            onColorChanged: page.viewTextColor = color
                        }
                        Controls.Label {
                            text: "Background color:"
                        }
                        ColorButton {
                            color: page.viewBackgroundColor
                            onColorChanged: page.viewBackgroundColor = color
                        }
                    }
                }
            ]
        }
    }
}
