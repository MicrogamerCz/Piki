// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtWebEngine
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.ScrollablePage {
    id: page
    padding: 0
    title: np.title

    property string novel
    onNovelChanged: np.loadNovel(novel)

    NovelProcessor {
        id: np
    }

    Kirigami.SelectableLabel {
        id: novelBody
        text: np.text

        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit;
        anchors.bottomMargin: Kirigami.Units.gridUnit;
        anchors.leftMargin: Kirigami.Units.gridUnit * 5;
        anchors.rightMargin: Kirigami.Units.gridUnit * 5;
    }
}
