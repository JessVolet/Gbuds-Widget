#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/gbuds-widget-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
# Keep the real compositor socket address while giving this test its own runtime.
case "${WAYLAND_DISPLAY:-}" in
    "") echo 'Run this test inside a Wayland session.' >&2; exit 1 ;;
    /*) ;;
    *) WAYLAND_DISPLAY="${XDG_RUNTIME_DIR:?}/$WAYLAND_DISPLAY"; export WAYLAND_DISPLAY ;;
esac
mkdir -m 700 "$fixture/runtime"
cp -R "$repo/tests/runtime/qs" "$fixture/qs"
ln -s "$repo" "$fixture/qs/Plugin"
GBUDS_FAKE_CLI="$repo/tests/runtime/fake-gbuds.py" \
GBUDS_FAKE_FAIL_CLI="$repo/tests/runtime/fail-gbuds.py" \
XDG_RUNTIME_DIR="$fixture/runtime" QT_QPA_PLATFORM=wayland \
timeout -k 2 20 qs -p "$fixture/qs" --no-color
