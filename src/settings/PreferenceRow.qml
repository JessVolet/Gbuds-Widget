import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "SettingsModel.js" as Model

Column {
    id:root
    required property var definition
    property var value
    signal edited(var value)
    width:parent?.width || 0
    Loader {
        width:parent.width
        active:root.visible
        sourceComponent:root.definition.kind === "title" ? heading : root.definition.kind === "toggle" ? toggle : root.definition.kind === "slider" ? slider : root.definition.kind === "select" ? select : input
    }
    Component {
        id:heading
        StyledText { text:root.definition.label; color:Theme.primary; font.pixelSize:14; font.weight:Font.DemiBold; topPadding:12; bottomPadding:4 }
    }
    Component {
        id:toggle
        SettingsToggleRow {
            text:root.definition.label
            description:root.definition.description || ""
            iconName:root.definition.icon || Model.icon(root.definition.key)
            checked:root.value === true
            onToggled:value=>root.edited(value)
        }
    }
    Component {
        id:slider
        SettingsSliderRow {
            text:root.definition.label
            description:root.definition.description || ""
            iconName:root.definition.icon || Model.icon(root.definition.key)
            minimum:root.definition.min; maximum:root.definition.max
            value:Number(root.value || 0)
            unit:root.definition.unit || (root.definition.key === "desktopBackgroundOpacity" ? "%" : /Duration|Timeout|Interval/.test(root.definition.key) ? "s" : "px")
            onSliderValueChanged:value=>root.edited(Math.round(value))
        }
    }
    Component {
        id:select
        SettingsDropdownRow {
            text:root.definition.label
            description:root.definition.description || ""
            iconName:root.definition.icon || Model.icon(root.definition.key)
            options:(root.definition.options || []).map(option=>option.label)
            currentValue:(root.definition.options || []).find(option=>option.value === root.value)?.label || "Use default"
            onValueChanged:value=>{
                const option=(root.definition.options || []).find(option=>option.label===value);
                if (option && option.value !== root.value) root.edited(option.value);
            }
        }
    }
    Component {
        id:input
        SettingsRow {
            title:root.definition.label
            subtitle:root.definition.description || ""
            iconName:root.definition.icon || Model.icon(root.definition.key)
            body: DTextField { width:parent.width; text:String(root.value || ""); Accessible.name:root.definition.label; onEditingFinished:root.edited(text) }
        }
    }
}
