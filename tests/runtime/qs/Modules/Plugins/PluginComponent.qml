import QtQuick
import qs.Services
Item {
property var pluginData: ({})
property string pluginId: "gbudsWatch"
property var pluginService: PluginService
property Component horizontalBarPill
property Component verticalBarPill
property Component popoutContent
property int popoutWidth
property int popoutHeight
property bool isVertical: false
property int iconSize: 22
property int widgetThickness: 32
property int textSize: 12
}
