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
    property ListModel history
    property ListModel selection

    opacity: enable ? 1 : 0
    visible: opacity != 0

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
                    model: tagCard.history

                    TagChip {
                        required property Tag modelData
                        tag: modelData

                        onClicked: {
                            selection.append({
                                tagData: tag
                            });
                            history.remove(index, 1);
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
                        onClicked: {
                            selection.append({
                                tagData: tag
                            });
                            Cache.suggestedTags.remove(index);
                        }
                    }
                }
            }
        }
    }
}
