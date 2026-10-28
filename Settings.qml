import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.DCommon.Widgets

PluginSettings {
    id: root
    pluginId: "gbudsWatch"

    StyledText {
        width: parent.width
        text: "Galaxy Buds"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Customize the bar appearance, battery indicators, colors, and event popups."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "Desktop widget"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    SelectionSetting {
        settingKey: "desktopLayout"
        label: "Desktop layout"
        description: "Choose Full or Compact for this widget instance. Resize the instance in the desktop editor after changing layouts."
        options: [
            { value: "full", label: "Full · controls and device settings" },
            { value: "compact", label: "Compact · live status and battery" }
        ]
        defaultValue: "full"
    }

    StyledText {
        width: parent.width
        text: "Bar Widget & Battery Style"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    SelectionSetting {
        settingKey: "batteryIndicatorStyle"
        label: "Battery indicator style"
        description: "How battery level is visualized on the earbud icons."
        options: [
            { value: "glow", label: "Glow halo [Default]" },
            { value: "border", label: "Colored border outline" },
            { value: "tint", label: "Colorize entire icon" },
            { value: "clean", label: "Clean theme icon (no battery color)" }
        ]
        defaultValue: "glow"
    }

    SelectionSetting {
        settingKey: "iconColorMode"
        label: "Icon color mode"
        description: "Auto mode dynamically matches your DMS bar theme in both Dark and Light mode."
        options: [
            { value: "auto", label: "Auto / DMS Theme (Default) [Recommended]" },
            { value: "primary", label: "Theme Primary (DMS)" },
            { value: "secondary", label: "Theme Secondary (DMS)" },
            { value: "tertiary", label: "Theme Tertiary (DMS)" },
            { value: "silver", label: "Silver / Metal" },
            { value: "white", label: "White / Clean" },
            { value: "violet", label: "Galaxy Violet" },
            { value: "mint", label: "Mint Green" },
            { value: "custom", label: "Custom color" }
        ]
        defaultValue: "auto"
    }

    ColorSetting {
        settingKey: "customColor"
        label: "Custom icon color"
        description: "Used when 'Custom color' is selected above."
        defaultValue: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "pillMode"
        label: "Bar layout"
        description: "Choose which icons to display in the bar."
        options: [
            { value: "compact", label: "Compact (earbuds)" },
            { value: "detailed", label: "Detailed (include case)" },
            { value: "icon-only", label: "Icon only" }
        ]
        defaultValue: "compact"
    }

    ToggleSetting {
        settingKey: "showBatteryPercentages"
        label: "Show battery percentage numbers"
        description: "Display numeric percentages next to the earbud icons in the bar."
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showModeIcon"
        label: "Show noise mode icon"
        description: "Show ANC or Ambient sound icon in the bar when active."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "warnOutOfEar"
        label: "Show waiting clock outside ear"
        description: "Display a small clock indicator when an earbud is removed from the ear."
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "idleColorMode"
        label: "Idle clock color"
        description: "Color for the waiting clock indicator when an earbud is outside the ear."
        options: [
            { value: "auto", label: "Bar / Theme color [Default]" },
            { value: "amber", label: "Amber (Waiting)" },
            { value: "primary", label: "Primary" },
            { value: "secondary", label: "Secondary" },
            { value: "tertiary", label: "Tertiary" },
            { value: "error", label: "Red (Alert)" },
            { value: "muted", label: "Muted Surface" },
            { value: "custom", label: "Custom color" }
        ]
        defaultValue: "auto"
    }

    StringSetting {
        settingKey: "customIdleColor"
        label: "Custom idle clock color"
        description: "Hex color for the idle clock indicator (e.g. #f59e0b)"
        placeholder: "#f59e0b"
        defaultValue: "#f59e0b"
    }

    StyledText {
        width: parent.width
        text: "Charging Case"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    SelectionSetting {
        settingKey: "caseColorMode"
        label: "Case color"
        description: "Color scheme for the charging case SVG in the widget."
        options: [
            { value: "auto", label: "Auto / DMS Theme [Recommended]" },
            { value: "silver", label: "Silver (Buds3 acrylic style)" },
            { value: "white", label: "White" },
            { value: "graphite", label: "Graphite" },
            { value: "match", label: "Match accent color" },
            { value: "custom", label: "Custom color" }
        ]
        defaultValue: "auto"
    }

    ColorSetting {
        settingKey: "customCaseColor"
        label: "Custom case color"
        description: "Used when 'Custom color' is selected for the case."
        defaultValue: "#d2dce0"
    }

    StyledText {
        width: parent.width
        text: "Status Cards & Alerts"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    ToggleSetting {
        settingKey: "showStatusCards"
        label: "Show live status cards"
        description: "Show connection, placement, and noise mode change cards."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showBatteryCards"
        label: "Show low battery warnings"
        description: "Alert when an earbud reaches 30% and 10% battery."
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "statusCardPosition"
        label: "Card corner position"
        description: "Corner where status popup notifications appear."
        options: [
            { value: "bottom-right", label: "Bottom right" },
            { value: "bottom-left", label: "Bottom left" },
            { value: "top-right", label: "Top right" },
            { value: "top-left", label: "Top left" }
        ]
        defaultValue: "bottom-right"
    }

    SelectionSetting {
        settingKey: "dismissTimeout"
        label: "Card duration"
        description: "How long status notification cards remain on screen."
        options: [
            { value: "3", label: "3 seconds" },
            { value: "5", label: "5 seconds" },
            { value: "8", label: "8 seconds" }
        ]
        defaultValue: "5"
    }

    StyledText {
        width: parent.width
        text: "Device Connection"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    StringSetting {
        settingKey: "targetMac"
        label: "Preferred device MAC"
        description: "Leave empty to automatically connect to any paired Galaxy Buds."
        placeholder: "AA:BB:CC:DD:EE:FF"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "gbudsCommand"
        label: "Gbuds executable"
        description: "Path to gbuds binary (default is from system PATH)."
        placeholder: "gbuds"
        defaultValue: "gbuds"
    }
}
