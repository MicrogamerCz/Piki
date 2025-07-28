// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

// TODOs:
// - split controls

Item {
    id: head
    height: 60

    property alias selectedTags: _selectedTags

    ListModel {
        id: tags
    }
    ListModel {
        id: tagsHistory

        function refresh() {
            Cache.GetTagHistory().then(hist => {
                clear();
                for (let i = 0; i < hist.length; i++) {
                    let tag = hist[i];
                    if (!selectedTags.tagInSelected(tag))
                        append({
                            tagData: tag
                        });
                }
            });
        }
    }
    ListModel {
        id: _selectedTags
        onRowsInserted: {
            queryBox.text = "";
            queryBox.forceActiveFocus();
        }
        onRowsRemoved: {
            queryBox.autocomplete();
            tagsHistory.refresh();

            if (currentPage.startsWith("Search"))
                pushSearchPage();
        }

        function tagInSelected(tag) {
            for (let i = 0; i < count; i++) {
                let sTag = get(i).tagData;
                let sameName = sTag.name == tag.name;
                let sameTr = sTag.translatedName == tag.translatedName;
                if (sameName && sameTr)
                    return true;
            }
            return false;
        }
    }

    function pushSearchPage() {
        searchField.loading = true;
        let comp = Qt.createComponent("io.github.micro.piqi", "SearchRequest", Component.PreferSynchronous, null);
        let obj = comp.createObject();
        obj.SetTags(selectedTags);
        Cache.PushTagHistory(obj.tags);
        piqi.Search(obj).then(sr => {
            Cache.SynchroniseIllusts(sr.illusts);
            searchField.loading = false;
            navigateToPageParm("Search", {
                searchRequest: obj,
                feed: sr
            });
        });
    }
    function checkIfStringIsUrlAndProcess(str) {
        try {
            let url = new URL(str);
            return str.substring(str.lastIndexOf("/") + 1);
        } catch (_) {
            if (!isNaN(str))
                return str;
            else
                return "";
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.margins: 5

        Controls.Label {
            id: headerLabel
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            text: root.currentPage
            font.bold: true
            font.pointSize: 14
        }

        Kirigami.AbstractCard {
            id: tagCard
            property bool enable: queryBox.text != ""// && queryBox.focus // necessary as there's a bug with the tags
            property int animD: 150
            property variant animE: Easing.OutQuad
            onEnableChanged: tagsHistory.refresh()
            opacity: enable ? 1 : 0
            visible: opacity != 0
            anchors {
                top: searchField.verticalCenter
                left: searchField.left
                right: searchField.right
                margins: 5
                topMargin: enable ? 30 : 0
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: tagCard.animD
                    easing: tagCard.animE
                }
            }
            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: tagCard.animD
                    easing: tagCard.animE
                }
            }

            contentItem: Item {
                implicitWidth: querySuggestions.implicitWidth
                implicitHeight: querySuggestions.implicitHeight
                ColumnLayout {
                    id: querySuggestions
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing

                        Repeater {
                            model: tagsHistory

                            TagChip {
                                onClicked: {
                                    selectedTags.append({
                                        tagData: modelData
                                    });
                                    tagsHistory.remove(index, 1);
                                }
                            }
                        }
                    }
                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing

                        Repeater {
                            model: tags

                            TagChip {
                                onClicked: {
                                    selectedTags.append({
                                        tagData: modelData
                                    });
                                    tags.remove(index, 1);
                                }
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            id: searchField
            property bool loading: false
            property color borderColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor
            border.color: queryBox.activeFocus ? Kirigami.Theme.highlightColor : borderColor
            radius: Kirigami.Units.cornerRadius
            width: 400
            height: 40
            anchors.centerIn: parent
            clip: true

            Kirigami.Icon {
                id: searchIcon
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                height: 30
                source: "search-symbolic"
            }
            Flickable {
                id: flick
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: searchIcon.right
                    right: loadingIndicator.left
                }
                contentWidth: row.width
                clip: true
                interactive: true

                RowLayout {
                    id: row
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: selectedTags

                        TagChip {
                            required property int index

                            closable: true
                            onRemoved: {
                                selectedTags.remove(index, 1);
                            }
                        }
                    }

                    TextEdit {
                        id: queryBox
                        Layout.minimumWidth: flick.width * (selectedTags.count > 0 ? 0.5 : 1)
                        color: Kirigami.Theme.textColor
                        property bool searching: false
                        property string lastQuery: ""

                        readonly property Kirigami.Action quitAction: Kirigami.Action {
                            shortcut: StandardKey.Find
                            onTriggered: queryBox.forceActiveFocus()
                        }

                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        Keys.onTabPressed: function (event) {
                            event.accepted = true;

                            selectedTags.append(tags.get(0));
                        }
                        Keys.onReturnPressed: function (event) {
                            event.accepted = true;

                            if (text == "") {
                                if (selectedTags.count > 0) {
                                    pushSearchPage();
                                    return;
                                }
                                return;
                            }
                            let id = checkIfStringIsUrlAndProcess(text);
                            if (id != "") {
                                piqi.IllustDetail(Number(id)).then(il => {
                                    navigateToPageParm("IllustView", {
                                        illust: il
                                    });
                                });
                                text = "";
                                return;
                            }

                            let comp = Qt.createComponent("io.github.micro.piqi", "Tag", Component.PreferSynchronous, null);
                            let obj = comp.createObject();
                            obj.name = text;

                            selectedTags.append({
                                tagData: obj
                            });

                            text = "";
                        }
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Backspace && text === "") {
                                event.accepted = true;
                                if (selectedTags.count > 0)
                                    selectedTags.remove(selectedTags.count - 1, 1);
                            }
                        }
                        Keys.onEscapePressed: function (event) {
                            event.accepted = true;
                            focus = false;
                        }
                        onTextEdited: autocomplete()
                        function autocomplete() {
                            if (searching || queryBox.text == "")
                                return;
                            searching = true;
                            lastQuery = queryBox.text;
                            piqi.SearchAutocomplete(queryBox.text).then(tgs => {
                                tags.clear();
                                for (let i = 0; i < tgs.length; i++) {
                                    let tag = tgs[i];
                                    if (!selectedTags.tagInSelected(tag))
                                        tags.append({
                                            tagData: tag
                                        });
                                }

                                searching = false;
                                if (queryBox.text != lastQuery)
                                    autocomplete();
                            });
                        }

                        Controls.Label {
                            visible: (queryBox.text == 0) && (head.selectedTags.count == 0)
                            text: "Search..."
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }
            }
            Controls.BusyIndicator {
                id: loadingIndicator
                visible: parent.loading
                anchors {
                    margins: 5
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 125
                }
            }
        }

        // Controls.Button {
        //     text: "Create"
        //     anchors.right: parent.right
        //     flat: true
        // }
    }
}
