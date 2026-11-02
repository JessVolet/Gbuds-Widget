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
mkdir -p "${EVIDENCE_DIR:?}"
XDG_RUNTIME_DIR="$fixture/runtime" QT_QPA_PLATFORM=wayland timeout 40 qs -p "$fixture/qs" --no-color
