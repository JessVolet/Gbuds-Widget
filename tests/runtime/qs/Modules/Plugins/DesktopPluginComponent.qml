import QtQuick
Item {
    property var pluginData: ({})
    property string pluginId: "gbudsWatch"
    property var pluginService
    property string instanceId: ""
    property var instanceData: null
    property bool lockScreen: false
    readonly property bool isInstance: instanceId !== "" && instanceData !== null
    readonly property var instanceConfig: instanceData?.config ?? ({})
    property real widgetWidth
    property real widgetHeight
    property real minWidth
    property real minHeight
}
