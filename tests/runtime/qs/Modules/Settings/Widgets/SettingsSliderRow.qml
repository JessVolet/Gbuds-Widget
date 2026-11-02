import QtQuick
SettingsRow { property string text; property string description; property real minimum:0; property real maximum:100; property real value:0; property string unit; signal sliderValueChanged(int value) }
