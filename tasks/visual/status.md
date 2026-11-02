# Native visual refinement status

Installed candidate: **0.7.0-dev.9**, branch `rewrite/modular-widget`, tag `visual-candidate-v4`, commit `cdae107a7a3944b507d75e7b1fa0ffde7a197216`.

The update removes all operating-system playback controls, interfaces, preferences, adapters and mocks. Sound & controls focuses on Buds equalizer presets and supported Buds features. Noise-mode buttons use Dux Material glyphs and follow the active theme. The hero keeps its clean layout without animated wave or gear decoration.

The approved presentation is implemented using native Dux/DCommon cards, icon buttons, sliders, disclosures, settings rows and tabs. System glyphs identify navigation/actions/settings; approved SVGs and model renders retain the device identity.

## Delivered behavior

- Expanded panel with device name, header History/Settings, three-part battery hero, safe contextual Find hints, noise controls, redesigned Equalizer and supported Sound & controls, and Connections.
- No fixed 560 px empty tail: native popout content sizing follows a bounded implicit height. Secondary content scrolls when needed.
- Automatic bar icon contrast uses the actual DBar fill; intentional custom colors remain preserved. Selected controls use matching theme foreground/container roles.
- Header settings navigation uses the installed host's canonical `SettingsTabs.pluginPage()` helper rather than copying main's obsolete route.
- Command history is daemon-owned, in memory, sanitized and bounded to 80 entries. Watch packets are not logged as separate commands. Canceled watcher jobs are Stopped rather than Failed.
- Sound & controls contains only controls for supported Galaxy Buds features. The equalizer exposes the named Gbuds presets; its curve is an illustrative visual guide, not a measured frequency response or manual frequency editor.
- The native Material mode glyphs follow the selected/unselected Dux theme colors in both light and dark appearances.
- Global notification defaults and sparse per-event overrides, with a persisted Advanced switch, conditional fields, nine-position picker, independent Waveup origins, display/duration/artwork/reach/stroke options, Preview and Reset.
- A wide editor displays the event list beside its rules; a narrow editor uses a compact selector. Initialization does not persist defaults.
- Native selection/disclosure motion follows global reduced motion; the panel page reveal also honors its local animation setting. Existing wave timing and safe Stop-before-disconnect behavior remain intact.

## Configure the requested example

Open the expanded widget → Settings icon → Notifications.

1. Set Default style to Waveups.
2. Enable Advanced notifications.
3. Select Noise mode changed.
4. Set Presentation to Popup and Popup position to Center.
5. Choose duration/display if desired, then Preview event.

Other events inherit global defaults. Disable Advanced to suspend saved exceptions without deleting them. Reset to default removes the selected event exception. Existing saved preferences were preserved during deployment; the example was not silently forced over user settings.

## Validation

- Native DCommon captures in dark and light show the expanded device panel beside the redesigned Sound & controls; simulated state reports ANC, touch controls and EQ. Capture completed without QML binding, assignment, ReferenceError or TypeError warnings.
- Operating-system playback controls, PipeWire adapter/service mocks and their identity policy were removed; no playback controls remain in the plugin.
- Node behavior and end-to-end suites were not rerun for this visual-only update. Physical Buds control validation, keyboard focus and multiple/mixed-scale outputs remain acceptance items.
- The previous installation is backed up at `/home/vsynlo/Documents/Codex/2026-11-01/pue/outputs/gbuds-visual-implementation/backups/gbuds-20261102T044443.452607Z`.
- Dux was restarted; `plugin-scan status gbudsWatch` reports `loaded composite`. The fresh Quickshell log shows the Gbuds daemon loaded and no QML load, binding, assignment, ReferenceError or TypeError failures.
- All **117 packaged files** match the installed plugin byte for byte.
- Artifact SHA-256: `3dfd279e55b34130e430d583b5acc353a3e1fe11b0b5d04020c664a6e8978128`.

No physical Buds commands were triggered during visual capture. Actual hardware behavior, keyboard focus, multiple/mixed-scale outputs and rollback rehearsal remain acceptance items. Main was not merged and nothing was pushed remotely.

## Commit evidence index

- 2cecea8: approved design and source-driven integration contract.
- 6da24f8: normalized per-event rules and popup geometry.
- 46bc41e: bounded command history and safe device controls.
- 920a8b0: native settings sections and event forms.
- d1671cb: panel hierarchy, semantic artwork and system navigation glyphs.
- 48fdb42: responsive event editor, nine-position picker, history correlation and native capture scenarios.
- 3668bac: canonical native settings navigation.
- ba18ece: native DBar import and non-null bar configuration regression coverage.
- 43998e5: removed operating-system playback controls and redesigned Buds sound controls.
- cdae107: removed animated hero decoration after visual review.

User-facing reports/captures and deployment hashes are delivered under outputs/gbuds-visual-implementation. Manual acceptance cells in todo.md remain pending where hardware, keyboard/focus or mixed-display evidence is absent.
