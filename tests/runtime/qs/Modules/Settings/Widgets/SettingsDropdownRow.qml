import QtQuick
SettingsRow { property string text; property string description; property var options:[]; property string currentValue; signal valueChanged(string value) }
