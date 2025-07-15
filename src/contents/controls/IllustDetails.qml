// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi

Kirigami.AbstractCard {
    id: card
    property Illustration illust

    clip: true
    padding: Kirigami.Units.largeSpacing * 2
    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing * 2

        Controls.Label {
            text: card.illust.title
            font.pointSize: 22
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        Controls.Label {
            visible: card.illust.caption != ""
            text: card.illust.caption
            renderType: Text.RichText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Kirigami.Separator {
            visible: card.illust.caption != ""
            Layout.fillWidth: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: card.illust.tags

                TagChip {
                    onClicked: root.pushTagAndSearch(modelData)
                }
            }
        }
    }
}
