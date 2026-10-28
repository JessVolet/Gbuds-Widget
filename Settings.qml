import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "gbudsWatch"

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            width: parent.width
            text: "Gbuds Watch"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: "Configure the live watcher, notifications, device selection, and bar pill. Controls pause the watcher while a Gbuds command runs, then restart it automatically."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        StringSetting {
            settingKey: "gbudsCommand"
            label: "Gbuds executable"
            description: "Use gbuds if it is on the DMS PATH, or enter its absolute path."
            placeholder: "gbuds"
            defaultValue: "gbuds"
        }

        StringSetting {
            settingKey: "targetMac"
            label: "Preferred Buds device (optional)"
            description: "Select a paired device from the widget instead. A connected device is followed automatically when only one Galaxy Buds is connected."
            placeholder: "AA:BB:CC:DD:EE:FF"
            defaultValue: ""
        }

        SelectionSetting {
            settingKey: "pillMode"
            label: "Bar pill layout"
            description: "Choose how much battery and noise-control information the bar pill shows."
            options: [
                { value: "compact", label: "Compact" },
                { value: "minimal", label: "Minimal" },
                { value: "detailed", label: "Detailed" }
            ]
            defaultValue: "compact"
        }

        ToggleSetting {
            settingKey: "notifyStateChanges"
            label: "Notify on state changes"
            description: "Show a DMS notification when battery, placement, ANC, EQ, or touchpad state changes."
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "notifyLowBattery"
            label: "Notify on low battery"
            description: "Notify once when an earbud or case crosses the selected threshold."
            defaultValue: true
        }

        SliderSetting {
            settingKey: "lowBatteryThreshold"
            label: "Low battery threshold"
            description: "Battery level that triggers a low-battery notification."
            minimum: 5
            maximum: 50
            unit: "%"
            defaultValue: 20
        }
    }
}
