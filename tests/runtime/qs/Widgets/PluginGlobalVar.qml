import QtQuick
import qs.Services
Item {
required property string varName
property var defaultValue
readonly property var value: PluginService.values[varName] || defaultValue
}
