// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import io.github.micro.piki

FormCard.FormCardPage {
    id: page
    title: i18n("Settings")
    property list<string> cacheLevelLabels: [i18n("Permanent cache is disabled"), i18n("Only the image variant with the highest definition is cached permanently"), i18n("All images are cached"), i18n("All images, and illust/profile data is cached")]

    FormCard.FormHeader {
        maximumWidth: Kirigami.Units.gridUnit * 50
        title: i18n("General")
    }
    FormCard.FormCard {
        maximumWidth: Kirigami.Units.gridUnit * 50

        FormCard.FormTextDelegate {
            text: i18n("Cache level")
            description: page.cacheLevelLabels[Config.cacheLevel]
        }
        FormCard.FormRadioDelegate {
            text: i18n("None")
            checked: Config.cacheLevel == 0
            onClicked: {
                Config.cacheLevel = 0;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: i18n("Optimised")
            checked: Config.cacheLevel == 1
            onClicked: {
                Config.cacheLevel = 1;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: i18n("Images")
            checked: Config.cacheLevel == 2
            onClicked: {
                Config.cacheLevel = 2;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: i18n("Everything")
            checked: Config.cacheLevel == 3
            onClicked: {
                Config.cacheLevel = 3;
                Config.save();
            }
        }

        FormCard.AbstractFormDelegate {
            background: Item {}

            contentItem: Item {
                implicitWidth: csCol.implicitWidth
                implicitHeight: csCol.implicitHeight
                ColumnLayout {
                    id: csCol
                    anchors.fill: parent
                    spacing: Kirigami.Units.mediumSpacing
                    Controls.Label {
                        text: i18n("Maximum cache size")
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing
                        Controls.Slider {
                            id: cacheLimitSlider
                            Layout.fillWidth: true
                            property int expval: 2 ** (value - 1)
                            from: 1
                            to: 8
                            stepSize: 1
                            snapMode: Controls.Slider.SnapAlways
                            value: Config.cacheSize
                            onValueChanged: {
                                Config.cacheSize = value;
                                Config.save();
                            }
                        }
                        Controls.Label {
                            font.bold: true
                            text: cacheLimitSlider.expval > 100 ? i18n("Unlimited") : (cacheLimitSlider.expval + "GB")
                        }
                    }
                }
            }
        }
    }
    FormCard.FormHeader {
        maximumWidth: Kirigami.Units.gridUnit * 50
        title: i18n("Defaults")
    }
    FormCard.FormCard {
        maximumWidth: Kirigami.Units.gridUnit * 50
        FormCard.FormRadioSelectorDelegate {
            text: i18n("Startup page")
            actions: [
                Kirigami.Action {
                    text: i18n("Home")
                    icon.name: "go-home-symbolic"
                },
                Kirigami.Action {
                    text: i18n("Following")
                    icon.name: "group"
                },
                Kirigami.Action {
                    text: i18n("Watchlist")
                    icon.name: "view-visible"
                },
                Kirigami.Action {
                    text: i18n("My pixiv")
                    icon.source: "io.github.microgamercz.piki"

                    enabled: false
                },
                Kirigami.Action {
                    text: i18n("Newest")
                    icon.name: "view-pim-news"
                },
                Kirigami.Action {
                    text: i18n("Bookmarks")
                    icon.name: "bookmarks"
                },
                Kirigami.Action {
                    text: i18n("History")
                    icon.name: "view-history"
                    enabled: false
                }
            ]
            selectedIndex: Config.startupPage
            onSelectedIndexChanged: {
                Config.startupPage = selectedIndex;
                Config.save();
            }
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextDelegate {
            text: i18n("R-18/R-18G wallpapers")
            description: i18n("Default settings for 'Set wallpaper' behaviour for age restricted works")
        }
        XWorkAsWallpaperOptions {
            isSettingsComponent: true
            selectedIndex: (Config.allowR18WorksAsWallpapers <= 1) ? Config.allowR18WorksAsWallpapers : (Config.allowR18WorksAsWallpapers + 1)
        }
    }
}
