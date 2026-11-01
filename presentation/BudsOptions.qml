import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    property string page: "devices"
    property var config: ({})
    property var devices: []
    property var command: ({})
    property var status: ({})
    property string selectedMac: ""
    property string detail: ""

    signal closeRequested()
    signal deviceChosen(string address)
    signal installRequested()

    width: parent.width
    height: parent.height

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusL
        color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.96)
        border.color: Theme.withAlpha(Theme.outline, 0.25)

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: Theme.spacingS

            Row {
                width: parent.width
                height: 30
                spacing: Theme.spacingS
                DButton {
                    width: 30; buttonHeight: 30; minimumWidth: 0
                    iconName: "arrow_back"; text: ""
                    Accessible.name: "Back to Galaxy Buds"
                    onClicked: root.closeRequested()
                }
                StyledText {
                    text: root.page === "devices" ? "Your devices" : "Gbuds console"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.page === "devices"
                Repeater {
                    model: root.devices
                    delegate: DButton {
                        required property var modelData
                        width: parent.width
                        text: (modelData.name || "Galaxy Buds") + (modelData.connected ? " · Connected" : "")
                        iconName: "earbuds"
                        checkable: true
                        checked: (modelData.address || "").toUpperCase() === root.selectedMac.toUpperCase()
                        backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        onClicked: root.deviceChosen(modelData.address)
                    }
                }
                StyledText {
                    visible: root.devices.length === 0
                    text: "No paired Galaxy Buds found."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.page === "terminal"
                StyledText {
                    width: parent.width
                    text: root.command.command || "gbuds watch --json"
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    height: 220
                    clip: true
                    text: root.command.result ? JSON.stringify(root.command.result, null, 2) : root.detail || JSON.stringify(root.status, null, 2)
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}
