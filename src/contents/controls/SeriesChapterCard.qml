import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piqi
import "."

Kirigami.AbstractCard {
    id: card
    property Illustration chapter

    visible: chapter.title != ""

    showClickFeedback: true
    contentItem: RowLayout {
        PixivImage {
            Layout.preferredHeight: 50
            Layout.preferredWidth: height
            source: card.chapter.imageUrls.squareMedium
        }

        ColumnLayout {
            Layout.fillWidth: true

            Controls.Label {
                text: card.chapter.title
            }
            Controls.Label {
                text: `${card.chapter.pageCount} ${card.chapter.pageCount > 1 ? "pages" : "page"}`
            }
        }
    }
    onClicked: navigateToPageParm("IllustView", {
        illust: chapter
    })
}
