import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Controls.Popup {
    // Kirigami.AbstractCard {
    id: tagCard

    closePolicy: Controls.Popup.NoAutoClose

    property real targetY
    y: targetY

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.shortDuration
                easing: Easing.OutQuad
            }
            NumberAnimation {
                property: "y"
                from: 0.0
                to:　tagCard.targetY
                duration: Kirigami.Units.shortDuration
                easing: Easing.OutQuad
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Kirigami.Units.shortDuration
                easing: Easing.OutQuad
            }
            NumberAnimation {
                property: "y"
                from: tagCard.targetY
                to:　0.0
                duration: Kirigami.Units.shortDuration
                easing: Easing.OutQuad
            }
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
                        onClicked: Cache.selectTag(tag)
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
                        onClicked: Cache.selectTag(tag)
                    }
                }
            }
        }
    }
}
