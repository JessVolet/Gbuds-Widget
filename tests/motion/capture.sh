#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/gbuds-motion.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
case "${WAYLAND_DISPLAY:-}" in
    "") echo 'A Wayland session is required.' >&2; exit 1 ;;
    /*) ;;
    *) WAYLAND_DISPLAY="${XDG_RUNTIME_DIR:?}/$WAYLAND_DISPLAY"; export WAYLAND_DISPLAY ;;
esac
mkdir -m 700 "$fixture/runtime"
cp -R "$repo/tests/runtime/qs" "$fixture/qs"
cp "${GBUDS_CAPTURE_SCENE:-$repo/tests/motion/scene.qml}" "$fixture/qs/shell.qml"
ln -s "$repo" "$fixture/qs/Plugin"
if [ -n "${GBUDS_NATIVE_COMMON:-}" ]; then
    rm -rf "$fixture/qs/DCommon"
    ln -s "$GBUDS_NATIVE_COMMON" "$fixture/qs/DCommon"
fi
if [ -n "${GBUDS_NATIVE_SETTINGS:-}" ]; then
    rm -rf "$fixture/qs/Modules/Settings/Widgets"
    ln -s "$GBUDS_NATIVE_SETTINGS" "$fixture/qs/Modules/Settings/Widgets"
    cp "${GBUDS_NATIVE_SETTINGS%/Modules/Settings/Widgets}/Common/QmlUtils.js" "$fixture/qs/Common/QmlUtils.js"
fi
mkdir -p "${EVIDENCE_DIR:?}"
XDG_RUNTIME_DIR="$fixture/runtime" QT_QPA_PLATFORM=wayland timeout -k 2 40 qs -p "$fixture/qs" --no-color
