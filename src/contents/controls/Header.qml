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
    property alias queryBox: flick.footerItem

    ListModel {
        id: tags
    }
    ListModel {
        id: tagsHistory

        function refresh() {
            Cache.getTagHistory().then(hist => {
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
        // TODO: add Q_INVOKABLE to constructors of Piqi objects
        let comp = Qt.createComponent("io.github.micro.piqi", "SearchRequest", Component.PreferSynchronous, null);
        let obj = comp.createObject();
        obj.SetTags(selectedTags);

        Cache.pushTagHistory(obj.tags);

        obj.Search().then(sr => {
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
                                    Cache.suggestedTags.remove(index);
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

            RowLayout {
                anchors.fill: parent

                Kirigami.Icon {
                    id: searchIcon
                    source: "search-symbolic"

                    Layout.preferredHeight: 30
                }
                ListView {
                    id: flick

                    clip: true
                    interactive: true
                    spacing: 5
                    model: selectedTags
                    orientation: ListView.Horizontal
                    delegate: TagChip {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter

                        closable: true
                        onRemoved: {
                            selectedTags.remove(index, 1);
                        }
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    footer: TextEdit {
                        // id: queryBox
                        leftPadding: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: flick.width * (selectedTags.count > 0 ? 0.5 : 1)
                        color: Kirigami.Theme.textColor
                        property bool searching: false
                        property string lastQuery: ""

                        readonly property Kirigami.Action findAction: Kirigami.Action {
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

                            // TODO: add Q_INVOKABLE to constructors of Piqi objects
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
                                Cache.suggestedTags.clear();
                                // move code to pikicache, add global qhash func for tags, check existence in qset
                                for (let i = 0; i < tgs.length; i++) {
                                    let tag = tgs[i];
                                    if (!selectedTags.tagInSelected(tag))
                                        Cache.tags.append({
                                            tagData: tag
                                        });
                                }

                                searching = false;
                                if (queryBox.text != lastQuery)
                                    autocomplete();
                            });
                        }

                        Controls.Label {
                            leftPadding: 5
                            visible: (queryBox.text == 0) && (head.selectedTags.count == 0)
                            text: i18n("Search...")
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }
                Controls.BusyIndicator {
                    id: loadingIndicator
                    visible: searchField.loading

                    Layout.margins: 5
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter
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
