import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
Column {
    id:root
    property var preferences:["all"]
    signal changed(var values)
    spacing:6
    StyledText { text:"Displays"; color:Theme.surfaceText; font.pixelSize:14 }
    Repeater {
        model:["all"].concat(Quickshell.screens.map(s=>s.name))
        DButton {
            required property string modelData
            width:root.width; text:modelData === "all" ? "All displays" : modelData
            checkable:true; checked:root.preferences.indexOf(modelData)>=0
            onClicked: {
                let values=modelData === "all" ? ["all"] : root.preferences.filter(p=>p!=="all");
                if (modelData!=="all") values=values.indexOf(modelData)>=0 ? values.filter(p=>p!==modelData) : values.concat([modelData]);
                if (!values.length) values=["all"];
                root.preferences=values; root.changed(values);
            }
        }
    }
}
