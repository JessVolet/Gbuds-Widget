pragma Singleton
import QtQuick
QtObject {
enum AnimationSpeed { None, Custom }
property int currentAnimationSpeed:1
property color accentOnSelectedContainer:onSelectedContainer
property bool dark: false
property color cardSurface:surfaceContainer
property color selectedContainer:primaryContainer
property color onSelectedContainer
property Binding selectedBinding:Binding { target:Theme; property:"onSelectedContainer"; value:Theme.onPrimaryContainer }
property color contrastLight:"#ffffff"
property color contrastDark:"#000000"
property color widgetBaseBackgroundColor:surfaceContainer
property int currentAnimationBaseDuration:250
property int mediumDuration:150
property color primary: dark ? "#f2b5cb" : "#824559"
property color primaryText:dark ? "#3d1227" : "#ffffff"
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
property color onPrimaryContainer
property Binding primaryBinding:Binding { target:Theme; property:"onPrimaryContainer"; value:Theme.dark ? "#ffdae8" : "#3d1227" }
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

property int spacingL:16
property int spacingXL:24
property int fontSizeXXLarge:24
property int fontWeightMedium:Font.Medium
property int windowInset:12
property int focusRingOffset:2
property int focusRingWidth:2
property color focusRingColor:primary
property int avatarSize:32
property int iconSizeMedium:20
property int iconButtonSize:32
property int listItemHeight:48
property int listItemTwoLineHeight:64
property int groupedListOuterRadius:20
property int groupedListInnerRadius:4
property int groupedListGap:4
property color outlineMedium:outline
property int layerOutlineWidth:0
property color chipSurface:surfaceContainer
property color chipSurfaceNested:surfaceContainerHigh
property color floatingWindowNestedSurface:surfaceContainer
property var expressiveDurations:({expressiveFastSpatial:180,expressiveEffects:150,expressiveFastEffects:120,expressiveRipple:250,expressiveDefaultSpatial:250})
property real tonalTintAlpha:0.12
property real springShapeProgress:1
property real buttonPadding:12
function foregroundColor(color, floating) { return color; }
function fullRadius(w,h) { return Math.min(w,h)/2; }
}
