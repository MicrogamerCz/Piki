import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi
import "."

Kirigami.AbstractCard {
    id: card
    property Illustration chapter

    visible: chapter?.title ?? "" != ""

    showClickFeedback: true
    contentItem: RowLayout {
        PixivImage {
            Layout.preferredHeight: 50
            Layout.preferredWidth: height
            source: card.chapter?.imageUrls?.squareMedium ?? new URL("qrc:/qt/qml/io/github/micro/piki/contents/assets/pixiv_no_profile.png")
        }

        ColumnLayout {
            Layout.fillWidth: true

            Controls.Label {
                text: card.chapter?.title ?? ""
            }
            Controls.Label {
                text: i18np("%1 page", "%1 pages", card.chapter?.pageCount ?? 0)
            }
        }
    }
    onClicked: navigateToPageParm("IllustView", {
        illust: chapter
    })
}
