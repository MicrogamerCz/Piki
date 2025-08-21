// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as Form
import io.github.micro.piki

Form.FormRadioSelectorDelegate {
    id: ct
    consistentWidth: false
    selectedIndex: -1
    property bool isSettingsComponent: false

    signal selectionChanged

    actions: [
        Kirigami.Action {
            text: !ct.isSettingsComponent ? i18n("Yes") : i18n("Always Ask")
        },
        Kirigami.Action {
            text: i18n("Yes (never show again)")
        },
        Kirigami.Action {
            visible: !ct.isSettingsComponent
            text: i18n("No")
        },
        Kirigami.Action {
            text: i18n("No (disable for restricted works)")
        }
    ]
    onSelectedIndexChanged: {
        switch (selectedIndex) {
        case 0:
            Config.allowR18WorksAsWallpapers = 0;
            break;
        case 1:
            Config.allowR18WorksAsWallpapers = 1;
            break;
        case 2:
            Config.allowR18WorksAsWallpapers = 0;
            break;
        case 3:
            Config.allowR18WorksAsWallpapers = 2;
            break;
        }
        Config.save();

        selectionChanged();
    }
}
