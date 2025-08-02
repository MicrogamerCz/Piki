import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi

Controls.ItemDelegate {
    id: card
    hoverEnabled: true
    width: 550
    height: 300

    property SeriesDetail detail
    readonly property real bgalpha: 0.3 + (hovered ? 0.1 : 0) + (pressed ? 0.1 : 0)

    implicitWidth: implicitBackgroundWidth
    implicitHeight: implicitBackgroundHeight

    background: Rectangle {
        width: 550
        height: 300
        color: Qt.rgba(0, 0, 0, card.bgalpha)
        radius: Kirigami.Units.cornerRadius
        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)

        ColumnLayout {
            anchors.centerIn: parent

            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                text: card.detail.title
            }
            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                level: 3
                text: `(${card.detail.seriesWorkCount} ${card.detail.seriesWorkCount > 1 ? "works" : "work"})`
            }
        }

        PixivImage {
            z: -1
            sourceSize.width: 548
            sourceSize.height: 298
            cache: true
            source: card.detail.coverImageUrls.medium
            anchors.fill: parent
            anchors.margins: 1
            layer {
                enabled: GraphicsInfo.api !== GraphicsInfo.Software
                effect: Kirigami.ShadowedTexture {
                    color: "transparent"
                    radius: Kirigami.Units.cornerRadius
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
}
