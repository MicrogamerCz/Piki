import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi

Kirigami.Card {
    id: notificationCard

    // TODO: add option to click to open the url in notification
    // showClickFeedback: true

    required property Notification notification
    property string message

    banner.radius: Kirigami.Units.cornerRadius
    banner.title: notification.viewMore?.title ?? i18n("Notification")

    topPadding: Kirigami.Units.smallSpacing
    contentItem: Controls.Label {
        text: notificationCard.message
        wrapMode: Text.Wrap
    }

    Rectangle {
        visible: !parent.notification.isRead

        anchors {
            top: parent.top
            right: parent.right
            margins: Kirigami.Units.cornerRadius * 3
        }

        color: Kirigami.Theme.positiveTextColor

        width: radius
        height: radius
        radius: 15
    }

    Component.onCompleted: {
        message = notification.content.text;

        if (notification.content.leftIcon != "")
            banner.titleIcon = notification.content.leftIcon;
        else if (notification.content.leftImage != "")
            banner.titleIcon = notification.content.leftImage;
        else if (notification.viewMore.title == "Likes")
            banner.titleIcon = "love";
        else if (notification.viewMore.title == "Someone followed you")
            banner.titleIcon = "actor";
        else {
            banner.titleIcon = "notification-active";

            if (notification.viewMore)
                message = `<b>${notification.viewMore.title}</b>: '{notification.content.text}'`;
        }
    }
}
