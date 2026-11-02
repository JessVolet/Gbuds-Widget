pragma Singleton
import QtQuick
QtObject { enum AnimationSpeed { None, Custom } property bool reduceMotion:false; function hasSetting(key) { return false; } function isDefault(keys) { return true; } function resetToDefault(keys) {} }
