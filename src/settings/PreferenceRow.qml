import QtQuick
import qs.Common
import qs.DCommon.Widgets

Column {
    id:root
    required property var definition
    property var value
    signal edited(var value)
    spacing:6
    StyledText {
        visible:root.definition.kind !== "select"
        width:parent.width; text:root.definition.label
        color:root.definition.kind === "title" ? Theme.primary : Theme.surfaceText
        font.pixelSize:root.definition.kind === "title" ? 16 : 14
        font.bold:root.definition.kind === "title"
    }
    Loader {
        width:parent.width
        active:root.visible && root.definition.kind !== "title"
        sourceComponent:root.definition.kind === "toggle" ? toggle : root.definition.kind === "slider" ? slider : root.definition.kind === "select" ? select : input
    }
    Component {
        id:toggle
        DToggle { checked:root.value === true; onToggled:value=>root.edited(value) }
    }
    Component {
        id:slider
        DSlider {
            minimum:root.definition.min; maximum:root.definition.max
            value:Number(root.value || 0)
            unit:root.definition.key === "desktopBackgroundOpacity" ? "%" : /Duration|Timeout|Interval/.test(root.definition.key) ? "s" : "px"
            onSliderValueChanged:value=>root.edited(Math.round(value))
        }
    }
    Component {
        id:select
        DDropdown {
            text:root.definition.label
            options:(root.definition.options || []).map(option=>option.label)
            currentValue:(root.definition.options || []).find(option=>option.value === root.value)?.label || String(root.value || "Use default")
            onValueChanged:value=>{
                const option=(root.definition.options || []).find(option=>option.label===value);
                if (option) root.edited(option.value);
            }
        }
    }
    Component {
        id:input
        DTextField { text:String(root.value || ""); onEditingFinished:root.edited(text) }
    }
}
