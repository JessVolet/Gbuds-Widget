# Native visual refinement status

Installed candidate: **0.7.0-dev.7**. Branch: `rewrite/modular-widget`. Tag: `visual-candidate-v2`. Runtime commit: `ba18ece342faaf1e1cf1227b0557465d109b13be`.

The approved presentation is implemented using native Dux/DCommon cards, icon buttons, sliders, disclosures, settings rows and tabs. System glyphs identify navigation/actions/settings; approved SVGs and model renders retain the device identity.

## Delivered behavior

- Expanded panel with device name, header History/Settings, three-part battery hero, safe contextual Find hints, noise controls, native output mixer, Sound & controls and Connections.
- No fixed 560 px empty tail: native popout content sizing follows a bounded implicit height. Secondary content scrolls when needed.
- Automatic bar icon contrast uses the actual DBar fill; intentional custom colors remain preserved. Selected controls use matching theme foreground/container roles.
- Header settings navigation uses the installed host's canonical `SettingsTabs.pluginPage()` helper rather than copying main's obsolete route.
- Command history is daemon-owned, in memory, sanitized and bounded to 80 entries. Watch packets are not logged as separate commands. Canceled watcher jobs are Stopped rather than Failed.
- Audio identity must uniquely match the selected Bluetooth address before enabling the output slider. Opening the panel does not change the default output. Subscription references are released on leaving/hiding the mixer. Applications is explicitly All playback, not claimed to be Buds-routed only.
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

- **28 Node behavior checks:** prior device/event/motion/assets behavior plus notification precedence, placement collisions, history bounds/privacy/correlation, audio identity and automatic contrast.
- **28 QML integration checks:** entry points, notifications editor loading, native audio acquire/release, completed history results and the existing fake-process failure/timeout/Find/Stop/disconnect flow.
- Native DCommon panel captures in dark/light and real native Settings-row captures, using fixture theme tokens and simulated device/audio services. The settings capture verifies zero persistence writes during initialization. Two scanner warnings refer to unused native modules omitted from the isolated capture tree; the final capture has no binding/assignment/ReferenceError/TypeError warnings.
- Temporary install/rollback test passes and preserves unrelated plugin preferences.
- Native Dux restarted for new modules, then the final correction reloaded as revision 1. The first deployment found a missing DBar import; the final candidate fixes it and the fixture now supplies a non-null bar configuration. Old pre-reload warnings remain in the process log; the post-reload widget segment has no new QML binding errors.
- **120 installed files** match the exact packaged artifact byte for byte.

No physical Find/disconnect/mute/volume actions were triggered by tests. Actual hardware/audio behavior, user visual acceptance, multiple/mixed-scale outputs and a full native rollback rehearsal remain acceptance items. Main was not merged and nothing was pushed remotely.

## Commit evidence index

- 2cecea8: approved design and source-driven integration contract.
- 6da24f8: normalized per-event rules and popup geometry.
- 46bc41e: bounded history and native target-specific audio adapter.
- 920a8b0: native settings sections and event forms.
- d1671cb: panel hierarchy, semantic artwork and system navigation glyphs.
- 48fdb42: responsive event editor, nine-position picker, history correlation and native capture scenarios.
- 3668bac: canonical native settings navigation.
- ba18ece: native DBar import and non-null bar configuration regression coverage.

User-facing reports/captures and deployment hashes are delivered under outputs/gbuds-visual-implementation. Manual acceptance cells in todo.md remain pending where hardware, keyboard/focus or mixed-display evidence is absent.
