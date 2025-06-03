// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

RowLayout {
    id: ct
    // Value is either a bool or string, int, enum, etc.
    // Bool if there are only two options
    property var label
    property var value
    readonly property bool isBoolValue: (typeof value === 'boolean')
    // Options are a plain list of labels (string) if value is bool,
    // otherwise it's a list of objects (key: string, value: string)
    // consisting of label and the corresponding values that are to
    // be selected.
    property var options

    Component.onCompleted: updateLabel()
    onValueChanged: updateLabel()
    function updateLabel() {
        if (ct.isBoolValue) {
            ct.label = ct.options[ct.value ? 1 : 0];
        } else {
            for (var i = 0; i < ct.options.length; i++) {
                if (ct.options[i].value === ct.value) {
                    ct.label = ct.options[i].label;
                    break;
                }
            }
        }
    }

    RowLayout {
        Repeater {
            model: ct.options

            Controls.Button {
                required property int index
                required property var modelData

                flat: true
                checkable: true
                checked: ct.value == (ct.isBoolValue ? (index > 0) : modelData.value)
                text: ct.isBoolValue ? modelData : modelData.label
                onClicked: ct.value = (ct.isBoolValue ? (index > 0) : modelData.value)
            }
        }
    }
}
