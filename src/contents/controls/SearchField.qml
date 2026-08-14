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
    property ListModel selection

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
            model: searchField.selection
            orientation: ListView.Horizontal
            delegate: TagChip {
                required property int index
                required property Tag modelData
                tag: modelData
                anchors.verticalCenter: parent.verticalCenter

                closable: true
                onRemoved: searchField.selection.remove(index, 1)
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            footer: TextEdit {
                // id: queryBox
                leftPadding: 5
                anchors.verticalCenter: parent.verticalCenter
                width: flick.width * (searchField.selection.count > 0 ? 0.5 : 1)
                color: Kirigami.Theme.textColor
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
                        if (searchField.selection.count > 0)
                            searchField.selection.remove(searchField.selection.count - 1, 1);
                    } else if (event.key === Qt.Key_Return) {
                        event.accepted = true;

                        if (text == "") {
                            if (searchField.selection.count > 0) {
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

                        let tag = new Tag();
                        tag.name = text;

                        searchField.selection.append({
                            tagData: tag
                        });

                        text = "";
                    } else if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        searchField.selection.append(tags.get(0));
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
                    piqi.SearchAutocomplete(queryBox.text).then(tgs => {
                        Cache.setSuggestedTags(tgs);
                        searching = false;

                        if (queryBox.text != lastQuery)
                            autocomplete();
                    });
                }

                Controls.Label {
                    leftPadding: 5
                    visible: (queryBox.text == 0) && (head.selection?.count ?? 0 == 0)
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
