import QtQuick
Item {
    property string pluginId
    property var pluginService
    property string instanceId
    property var instanceData
    property string settingKey
    property string label
    property string description
    property var defaultValue
    property var options
    property string placeholder
    function saveValue(key, value) {}
    function loadValue(key, fallback) { return fallback; }
}
