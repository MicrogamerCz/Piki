import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Rectangle {
    id: searchField

    property bool loading: false
    property color borderColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
    property alias queryBox: flick.footerItem

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

            Layout.margins: 5
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
        }
        ListView {
            id: flick

            clip: true
            interactive: true
            spacing: 5
            model: Cache.selectedTags
            orientation: ListView.Horizontal
            delegate: TagChip {
                // required property int index
                anchors.verticalCenter: parent.verticalCenter

                closable: true
                onRemoved: {
                    Cache.unselectTag(tag);
                    Cache.getTagHistory();
                }
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            footer: TextEdit {
                id: queryBox
                leftPadding: 5
                anchors.verticalCenter: parent.verticalCenter
                width: flick.width * (Cache.selectedTags.tags.length > 0 ? 0.5 : 1)
                color: Kirigami.Theme.textColor
                enabled: !searchField.loading
                property bool searching: false
                property string lastQuery: ""

                readonly property Kirigami.Action findAction: Kirigami.Action {
                    shortcut: StandardKey.Find
                    onTriggered: queryBox.forceActiveFocus()
                }

                KeyNavigation.priority: KeyNavigation.BeforeItem
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Backspace && text === "") {
                        event.accepted = true;
                        if (Cache.selectedTags.tags.length > 0) {
                            Cache.unselectTag(Cache.selectedTags.tags[Cache.selectedTags.tags.length - 1]);
                            Cache.getTagHistory();
                        }
                    } else if (event.key === Qt.Key_Return) {
                        event.accepted = true;

                        if (text == "" && Cache.selectedTags.tags.length > 0) {
                            Cache.pushTagHistory().then(() => {
                                head.pushSearchPage();
                            });
                            return;
                        }
                        let id = verifyUrl(text);
                        if (id != "") {
                            piqi.illustDetail(Number(id)).then(response => {
                                if (!response.isSuccessful) {
                                    showResponseError(response);
                                    return;
                                }
                                navigateToPageParm("IllustView", {
                                    illust: response.data
                                });
                            });
                            text = "";
                            return;
                        }

                        let tag = new Tag();
                        tag.name = text;

                        Cache.selectTag(tag);

                        text = "";
                        forceActiveFocus();
                    } else if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        if (Cache.suggestedTags.tags.length > 0)
                            Cache.selectTag(Cache.suggestedTags.tags[0]);
                        forceActiveFocus();
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        focus = false;
                    }
                }

                onTextEdited: autocomplete()
                function autocomplete() {
                    if (searching || queryBox.text == "")
                        return;

                    searching = true;
                    lastQuery = queryBox.text;
                    piqi.searchAutocomplete(queryBox.text).then(tgs => {
                        Cache.setTagSuggestions(tgs);
                        searching = false;

                        if (queryBox.text != lastQuery)
                            autocomplete();
                    });
                }

                Connections {
                    target: Cache.selectedTags

                    function onAdded() {
                        queryBox.text = "";
                        queryBox.forceActiveFocus();
                    }
                    function onRemoved() {
                        queryBox.text = "";
                        queryBox.forceActiveFocus();
                    }
                }

                Controls.Label {
                    leftPadding: 5
                    visible: (queryBox.text == 0) && (Cache.selectedTags?.count ?? 0 == 0)
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
