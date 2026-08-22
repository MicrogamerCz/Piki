import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.AbstractCard {
    id: tagCard

    property bool enable
    property int animD: 150
    property variant animE: Easing.OutQuad

    opacity: enable ? 1 : 0
    visible: opacity != 0
    z: 10

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
                    model: Cache.historyTags

                    TagChip {
                        // required property int index

                        onClicked: {
                            Cache.selectTag(tag);
                            // Cache.selectedTags.append(tag);
                            // Cache.historyTags.remove(index);
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
                    model: Cache.suggestedTags

                    TagChip {
                        // required property int index

                        onClicked: {
                            Cache.selectTag(tag);
                            // Cache.selectedTags.append(tag);
                            // Cache.suggestedTags.remove(index);
                        }
                    }
                }
            }
        }
    }
}
