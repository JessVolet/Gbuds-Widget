import QtQuick
import qs.Common
import qs.DCommon.Common

QtObject {
    readonly property color surface:Theme.cardSurface
    readonly property color foreground:Theme.surfaceText
    readonly property color supporting:Theme.surfaceVariantText
    readonly property color selected:Theme.selectedContainer
    readonly property color onSelected:Theme.onSelectedContainer
    readonly property bool motion:!Style.reduceMotion && Theme.currentAnimationBaseDuration>0
    readonly property int duration:motion ? Theme.mediumDuration : 0
    readonly property int gap:Theme.spacingS
}
