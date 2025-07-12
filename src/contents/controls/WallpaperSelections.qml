// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as Form
import io.github.micro.piki
import io.github.micro.piqi
import "."

Kirigami.Dialog {
    id: wallpaperSelections
    title: `Set '${page.title}' as Wallpaper`
    preferredWidth: Kirigami.Units.gridUnit * 32
    flatFooterButtons: true

    customFooterActions: [
        Kirigami.Action {
            visible: (wallpaperSelections.requirements > 1) || !restrictCard.visible
            enabled: displayOptions.selectedIndex >= 0
            icon.name: "answer"
            text: "Proceed"
            onTriggered: {
                wallpaperSelections.close();
                if (displayOptions.selectedIndex <= 1)
                    PikiHelper.SetWallpaper(page.illust, monitorSelector.value - 1, wallpaperSelections.imageIndex - 1);
            }
        }
    ]

    property int requirements: (page.illust.xRestrict > 0) + (wallpaperSelections.screenCount > 1) + (page.illust.pageCount > 1)
    property alias imageIndex: pageSelector.value
    property int screenCount: 0
    onOpened: {
        screenCount = PikiHelper.GetScreenCount();
        if (page.illust.pageCount > 1)
            pageSelector.refreshPreview();
    }
    function setup() {
        screenCount = PikiHelper.GetScreenCount();
        if (requirements > 0)
            open();
        else
            PikiHelper.SetWallpaper(page.illust);
    }

    Form.FormCardPage {
        topPadding: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.largeSpacing
        Form.FormCard {
            id: restrictCard
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            visible: (page.illust.xRestrict > 0) && (Config.allowR18WorksAsWallpapers != 1)
            property int option: 0
            property bool singleOption: visible && (wallpaperSelections.requirements == 1)
            Form.FormTextDelegate {
                text: "R-18 work!"
                font.bold: true
                font.pointSize: 13
            }
            Form.FormSectionText {
                text: `Warning! This work is marked as ${page.illust.xRestrict > 1 ? "R-18G" : "R-18"}! Other people might see this image on your background in public or if you don't properly hide/crop the contents from your screenshots. Do you want to proceed?`
            }
            XWorkAsWallpaperOptions {
                id: displayOptions
                onSelectionChanged: {
                    if (restrictCard.singleOption) {
                        wallpaperSelections.close();
                        if (selectedIndex <= 1)
                            PikiHelper.SetWallpaper(page.illust, 0, 0);
                    }
                }
            }
        }
        Form.FormCard {
            id: pageCard
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            visible: page.illust.pageCount > 1
            Form.FormSpinBoxDelegate {
                id: pageSelector
                from: 1
                to: page.illust.pageCount
                label: "Which image should be used for the wallpaper?"
                onValueChanged: refreshPreview()
                function refreshPreview() {
                    preview.source = images.get(value - 1).url;
                }
            }
            Form.FormDelegateSeparator {
                Layout.topMargin: Kirigami.Units.mediumSpacing
                Layout.bottomMargin: Kirigami.Units.mediumSpacing
            }
            Form.AbstractFormDelegate {
                enabled: false
                height: 320
                PixivImage {
                    id: preview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: 320
                    sourceSize.width: parent.width
                }
            }
        }
        Form.FormCard {
            id: monitorCard
            visible: wallpaperSelections.screenCount > 1
            Form.FormSpinBoxDelegate {
                id: monitorSelector
                from: 1
                to: Math.max(1, wallpaperSelections.screenCount)
                label: "Which monitor should have the wallpaper?"
            }
        }
    }
}
