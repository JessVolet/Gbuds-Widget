import QtQuick
Item { property string pluginId; property string settingKey; property string label; property string description; property var defaultValue; property bool value: defaultValue === true; property var options; property string placeholder }
