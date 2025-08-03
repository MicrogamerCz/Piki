// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.labs.components as Kila
import io.github.micro.piki
import io.github.micro.piqi
import "../controls"
import "../controls/templates"

FeedPage {
    id: page
    title: `Series・${feed.illustSeriesDetail.title}`
    padding: 0
    header: null

    property Series feed

    Rectangle {
        id: headerLayout
        Layout.preferredHeight: 350
        Layout.fillWidth: true
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "#000000", 0.1)

        PixivImage {
            visible: source != ""
            sourceSize.width: width
            sourceSize.height: height
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: page.feed.illustSeriesDetail.coverImageUrls.medium
        }

        Kirigami.AbstractCard {
            anchors.centerIn: parent
            padding: Kirigami.Units.gridUnit

            contentItem: ColumnLayout {
                anchors.fill: parent
                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font.bold: true
                    font.pixelSize: 20
                    text: page.feed.illustSeriesDetail.title
                }
                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 16
                    text: page.feed.illustSeriesDetail.caption
                }
                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    color: Kirigami.Theme.disabledTextColor
                    text: `(${page.feed.illustSeriesDetail.seriesWorkCount} ${page.feed.illustSeriesDetail.seriesWorkCount > 1 ? "works" : "work"})`
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                RowLayout {
                    uniformCellSizes: true
                    Controls.Button {
                        Layout.fillWidth: true
                        flat: true
                        text: checked ? "In your watchlist" : "Add to watchlist"
                        checkable: true
                        checked: page.feed.illustSeriesDetail.watchlistAdded

                        onClicked: {
                            if (checked)
                                piqi.WatchlistAdd(page.feed.illustSeriesDetail, "manga");
                            else
                                piqi.WatchlistAdd(page.feed.illustSeriesDetail, "manga");
                        }
                    }
                    Controls.Button {
                        Layout.fillWidth: true
                        flat: true
                        text: "Read the latest chapter"
                    }
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit
        rowSpacing: 15
        columnSpacing: 15
        columns: Math.floor((page.width - 25) / 190)

        Repeater {
            model: page.feed

            IllustrationButton {
                illust: modelData
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
}
