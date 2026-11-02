pragma Singleton
import QtQuick
QtObject {
property bool dark: false
property color cardSurface:surfaceContainer
property color selectedContainer:primaryContainer
property color onSelectedContainer:onPrimaryContainer
property color contrastLight:"#ffffff"
property color contrastDark:"#000000"
property color widgetBaseBackgroundColor:surfaceContainer
property int currentAnimationBaseDuration:250
property int mediumDuration:150
property color primary: dark ? "#f2b5cb" : "#824559"
property color secondary: primary
property color tertiary: primary
property color surfaceText: dark ? "#f7e9ee" : "#2b2026"
property color surfaceVariantText: dark ? "#d3bfc7" : "#705d66"
property color surfaceContainer: dark ? "#30282e" : "#fff1f6"
property color surfaceContainerHighest: dark ? "#4b3e46" : "#ead7e0"
property color surfaceContainerHigh: dark ? "#3b3037" : "#f0dfe7"
property color surfaceContainerLowest: surfaceContainer
property color surface: surfaceContainer
property color primaryContainer: dark ? "#60374a" : "#f7cddd"
property color onPrimaryContainer: dark ? "#ffdae8" : "#3d1227"
property color outline: surfaceVariantText
property color widgetIconColor: primary
property color widgetInactiveIconColor: surfaceVariantText
property color widgetTextColor: surfaceText
property color error: "#ba2942"
property color warning: "#9a640a"
property color success: "#38744a"
property int spacingXXS: 2
property int spacingXS: 4
property int spacingS: 8
property int spacingM: 12
property int cornerRadiusS: 8
property int cornerRadiusM: 12
property int cornerRadiusL: 20
property int fontSizeSmall: 12
property int fontSizeMedium: 14
property int fontSizeLarge: 18
property int iconSize: 20
function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a); }
}
