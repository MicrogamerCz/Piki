import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi

Controls.ItemDelegate {
    id: requestsCard
    property User user
    visible: user.isAcceptRequest
    Layout.alignment: Qt.AlignVCenter

    onClicked: Qt.openUrlExternally(`https://www.pixiv.net/users/${user.id}/request`)

    contentItem: Row {
        anchors.fill: parent

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            source: "message-new"
            color: Kirigami.Theme.positiveTextColor
        }
        Controls.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Accepting requests"
        }
    }
    background: Rectangle {
        property color defaultColor: Kirigami.Theme.positiveBackgroundColor
        property color hoverColor: Kirigami.ColorUtils.tintWithAlpha(defaultColor, Kirigami.Theme.highlightColor, 0.1)
        property color pressedColor: Kirigami.ColorUtils.tintWithAlpha(defaultColor, Kirigami.Theme.highlightColor, 0.3)

        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        border.color: Kirigami.Theme.positiveTextColor
        color: requestsCard.down ? pressedColor : (requestsCard.hovered ? hoverColor : defaultColor)
    }
}
