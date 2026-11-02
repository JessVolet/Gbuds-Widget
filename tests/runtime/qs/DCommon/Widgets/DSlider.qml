import QtQuick
Item { property real minimum; property real maximum; property bool showValue:true
property real value; property string unit; signal sliderValueChanged(real newValue) }
