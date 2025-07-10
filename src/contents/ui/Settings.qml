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
    title: "Settings"
    property list<string> cacheLevelLabels: ["Permanent cache is disabled", "Only the image variant with the highest definition is cached permanently", "All images are cached", "All images, and illust/profile data is cached"]

    FormCard.FormHeader {
        maximumWidth: Kirigami.Units.gridUnit * 50
        title: "General"
    }
    FormCard.FormCard {
        maximumWidth: Kirigami.Units.gridUnit * 50

        FormCard.FormTextDelegate {
            text: "Cache level"
            description: page.cacheLevelLabels[Config.cacheLevel]
        }
        FormCard.FormRadioDelegate {
            text: "None"
            checked: Config.cacheLevel == 0
            onClicked: {
                Config.cacheLevel = 0;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: "Optimised"
            checked: Config.cacheLevel == 1
            onClicked: {
                Config.cacheLevel = 1;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: "Images"
            checked: Config.cacheLevel == 2
            onClicked: {
                Config.cacheLevel = 2;
                Config.save();
            }
        }
        FormCard.FormRadioDelegate {
            text: "Everything"
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
                        text: "Maximum cache size"
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
                            text: cacheLimitSlider.expval > 100 ? "Unlimited" : (cacheLimitSlider.expval + "GB")
                        }
                    }
                }
            }
        }

        FormCard.FormDelegateSeparator {
            visible: !piqi.user.isPremium
        }

        FormCard.FormCheckDelegate {
            visible: !piqi.user.isPremium
            text: "pixiv Premium suggestions"
            description: "Enable pixiv Premium sidebar button and page banner\n(doesn't apply to popular search preview)"
            checked: Config.enablePremiumSuggestions
            onCheckedChanged: {
                Config.enablePremiumSuggestions = checked;
                Config.save();
            }
        }
    }
    FormCard.FormHeader {
        maximumWidth: Kirigami.Units.gridUnit * 50
        title: "Defaults"
    }
    FormCard.FormCard {
        maximumWidth: Kirigami.Units.gridUnit * 50
        FormCard.FormRadioSelectorDelegate {
            text: "Startup page"
            actions: [
                Kirigami.Action {
                    text: "Home"
                    icon.name: "go-home-symbolic"
                },
                Kirigami.Action {
                    text: "Following"
                    icon.name: "group"
                },
                Kirigami.Action {
                    text: "Watchlist"
                    icon.name: "view-visible"

                    enabled: false
                },
                Kirigami.Action {
                    text: "My pixiv"
                    icon.source: "io.github.micro.piki"

                    enabled: false
                },
                Kirigami.Action {
                    text: "Newest"
                    icon.name: "view-pim-news"
                },
                Kirigami.Action {
                    text: "Bookmarks"
                    icon.name: "bookmarks"
                },
                Kirigami.Action {
                    text: "History"
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
            text: "R-18/R-18G wallpapers"
            description: "Default settings for 'Set wallpaper' behaviour for age restricted works"
        }
        XWorkAsWallpaperOptions {
            isSettingsComponent: true
            selectedIndex: (Config.allowR18WorksAsWallpapers <= 1) ? Config.allowR18WorksAsWallpapers : (Config.allowR18WorksAsWallpapers + 1)
        }
    }
}
