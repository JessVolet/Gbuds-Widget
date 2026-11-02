import QtQuick
import qs.Common
import qs.DCommon.Widgets

DCard {
    id:root
    required property var model
    property var config:({})
    height:236; implicitHeight:height; pad:12
    Row {
        anchors.fill:parent; spacing:4
        Repeater {
            model:["left","case","right"]
            HeroPart { required property string modelData; width:(parent.width-8)/3; height:parent.height; model:root.model; part:modelData; config:root.config }
        }
    }
}
