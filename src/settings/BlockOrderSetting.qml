import QtQuick
import qs.Common
import qs.DCommon.Widgets
Column {
    id:root
    property string order:"name,parts,noise,disconnect"
    signal changed(string value)
    spacing:6
    function move(index, delta) {
        const parts=order.split(","), next=index+delta;
        if (next<0 || next>=parts.length) return;
        const value=parts.splice(index,1)[0]; parts.splice(next,0,value);
        changed(parts.join(","));
    }
    StyledText { text:"Block order"; color:Theme.surfaceText; font.pixelSize:14 }
    Repeater {
        model:root.order.split(",")
        Row {
            required property int index
            required property string modelData
            width:root.width; spacing:6
            StyledText { width:parent.width-84; height:32; verticalAlignment:Text.AlignVCenter; text:({name:"Device name",parts:"Earbuds",noise:"Noise control",disconnect:"Disconnect"})[modelData] || modelData; color:Theme.surfaceVariantText; font.pixelSize:12 }
            DButton { width:36; minimumWidth:0; text:""; iconName:"arrow_upward"; enabled:index>0; Accessible.name:"Move block up"; onClicked:root.move(index,-1) }
            DButton { width:36; minimumWidth:0; text:""; iconName:"arrow_downward"; enabled:index<3; Accessible.name:"Move block down"; onClicked:root.move(index,1) }
        }
    }
}
