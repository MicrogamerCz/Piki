// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Kirigami.Dialog {
    id: accountDialog
    closePolicy: reloadingAccount ? Controls.Popup.NoAutoClose : (Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnReleaseOutside)
    title: "Accounts"
    standardButtons: Kirigami.Dialog.NoButton
    showCloseButton: false
    topPadding: 0
    padding: 15

    readonly property string defaultPfp: "../assets/pixiv_no_profile.png"
    property bool reloadingAccount: false

    ColumnLayout {
        width: 600
        spacing: 5
        AccountButton {
            name: piqi.user?.name ?? ""
            pfp: (piqi.user == null) ? accountDialog.defaultPfp : piqi.user?.profileImageUrls?.px50 ?? accountDialog.defaultPfp
            onRemoved: removeAccount(null)
            showClickFeedback: false
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            visible: LoginHandler.otherUsers.length > 0
        }
        Repeater {
            model: LoginHandler.otherUsers

            AccountButton {
                enabled: !accountDialog.reloadingAccount

                name: modelData.name
                pfp: modelData.profileImageUrls.px50

                showClickFeedback: true
                onClicked: switchAccount(modelData)
                onRemoved: removeAccount(modelData)
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        Kirigami.AbstractCard {
            showClickFeedback: true
            implicitWidth: 320
            contentItem: RowLayout {
                spacing: 15
                Kirigami.Icon {
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 50
                    source: "list-add"
                }
                Kirigami.Heading {
                    text: "Add account"
                }
            }
            onClicked: {
                navigateToPage("Login");
                accountDialog.close();
            }
        }
    }
}
