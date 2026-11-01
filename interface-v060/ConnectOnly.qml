import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root
    required property string pluginId
    property bool choosing: false
    readonly property var pairedBuds: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))
    PluginGlobalVar { id: selectedDevice; varName: "selectedDevice"; defaultValue: "" }
    BudsActions { id: actions; pluginId: root.pluginId }
    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 20, 260)
        spacing: 6
        ActionButton {
            objectName: "connectButton"
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 150)
            height: 38
            text: actions.busy ? "Conectando…" : "Conectar"
            enabled: !actions.busy
            Accessible.description: actions.error
            onClicked: {
                if (!selectedDevice.value && root.pairedBuds.length > 1)
                    root.choosing = !root.choosing;
                else
                    actions.send("connect", [], "Connect Galaxy Buds");
            }
        }
        Repeater {
            model: root.choosing ? root.pairedBuds : []
            delegate: ActionButton {
                required property var modelData
                width: parent.width
                height: 32
                text: modelData.name || "Galaxy Buds"
                enabled: !actions.busy
                onClicked: {
                    PluginService.setGlobalVar(root.pluginId, "deviceSelection", modelData.address);
                    root.choosing = false;
                    actions.send("connect", [], "Connect Galaxy Buds");
                }
            }
        }
        // Failures stay visible so an unsuccessful connection is actionable.
        Text {
            width: parent.width
            visible: !!actions.error
            text: actions.error
            color: Theme.error
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
