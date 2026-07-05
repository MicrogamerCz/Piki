// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as Form
import org.kde.kirigamiaddons.components as KIA
import io.github.micro.piki
import io.github.micro.piqi
import "."
import "../controls"

Kirigami.AbstractCard {
    id: toolbar
    property Illustration illust

    contentItem: Kirigami.ActionToolBar {
        spacing: Kirigami.Units.largeSpacing
        actions: [
            FlatAction {
                iconName: "view-visible"
                text: toolbar.illust.totalView
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                checkable: true
                checked: toolbar.illust.isBookmarked
                text: toolbar.illust.totalBookmarks
                icon.name: {
                    if (toolbar.illust.isBookmarked === 2) {
                        return "view-private";
                    } else if (toolbar.illust.isBookmarked === 1) {
                        return "favorite-favorited";
                    } else {
                        return "favorite";
                    }
                }
                icon.color: (toolbar.illust.isBookmarked > 0) ? "gold" : Kirigami.Theme.textColor

                onTriggered: {
                    if (toolbar.illust.isBookmarked == 0)
                        toolbar.illust.AddBookmark(false);
                    else
                        toolbar.illust.RemoveBookmark(toolbar.illust);
                }
            },
            Kirigami.Action {
                icon.name: "view-private"

                onTriggered: toolbar.illust.AddBookmark(toolbar.illust.isBookmarked < 2)
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                icon.name: "emblem-shared-symbolic"
                onTriggered: contextMenu.popup()
            },
            // TODO: mute
            // TODO: report
            Kirigami.Action {
                separator: true
            },
            FlatAction {
                text: Qt.formatDateTime(toolbar.illust.createDate, "yyyy-MM-dd hh:mm")
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                icon.name: "download"
                text: i18n("Download")
                onTriggered: {
                    if (typeof page !== 'undefined' && page.downloadCurrent)
                        page.downloadCurrent();
                }
            }
        ]
    }
    Controls.Menu {
        id: contextMenu
        Kirigami.Action {
            enabled: !(Config.allowR18WorksAsWallpapers != 2 && toolbar.illust.xRestrict > 0)
            text: i18n("Set as wallpaper")
            icon.name: "viewimage"
            onTriggered: wallpaperSelections.setup()
        }
    }

    Instantiator {
        model: Purpose.PurposeAlternativesModel {
            id: alternativesModel
            pluginType: "ShareUrl"
            inputData: {
                'title': toolbar.illust.title,
                'urls': ["https://pixiv.net/artworks/" + toolbar.illust.id]
            }
        }
        delegate: Kirigami.Action {
            property int index
            text: model.display ?? ""
            icon.name: model.iconName

            onTriggered: root.share(alternativesModel, index)
        }
        onObjectAdded: (index, object) => {
            object.index = index;
            contextMenu.contentData.push(object);
        }
    }
    WallpaperSelections {
        id: wallpaperSelections
    }
}
