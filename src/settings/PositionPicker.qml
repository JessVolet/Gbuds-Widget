import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../config/NotificationPreferences.js" as Rules

Column {
    id:root
    property string value:"match"
    property bool inherit:false
    signal edited(string value)
    spacing:8
    Row {
        spacing:6
        DButton { text:"Use default"; visible:root.inherit; backgroundColor:root.value==="default" ? Theme.selectedContainer : Theme.cardSurface; textColor:Theme.surfaceText; onClicked:root.edited("default") }
        DButton { text:"Match earbud"; iconName:"earbuds"; backgroundColor:root.value==="match" ? Theme.selectedContainer : Theme.cardSurface; textColor:Theme.surfaceText; onClicked:root.edited("match") }
    }
    Row {
        spacing:14
        Grid {
            columns:3; spacing:4
            Repeater {
                model:Rules.positions
                DIconButton {
                    required property string modelData
                    required property int index
                    iconName:["north_west","north","north_east","west","filter_center_focus","east","south_west","south","south_east"][index]
                    tooltipText:modelData.replace(/-/g," ")
                    variant:root.value===modelData ? "tonal" : "outlined"
                    Accessible.selected:root.value===modelData
                    onClicked:root.edited(modelData)
                }
            }
        }
        StyledText { text:root.value.replace(/-/g," "); color:Theme.surfaceVariantText; font.pixelSize:12; anchors.verticalCenter:parent.verticalCenter }
    }
}
