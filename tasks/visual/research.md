# Dux Shell integration research

Status: research and planning only. Runtime source, the installed plugin and user preferences were not modified. This addendum refines PLAN.md; verified host behavior takes precedence over generic mockup implementation suggestions.

## Platform identity and versions

The target is Dux Shell, implemented in QML on Quickshell with Go services. duxlabs.dev is its documentation/product site. The official 2.0 announcement identifies Dux Shell as the successor name of DankMaterialShell and Dux Labs as the new project organization. Historical names remain in some imports, capability identifiers and CLI/config paths; do not mechanically rename those APIs.

Observed commands on this machine:

- `dms version`: `dms v2.0.0`.
- `qs --version`: Quickshell 0.3.2, distributed by Fedora COPR avengemedia/quickshell.
- Gbuds manifest: composite plugin with daemon, dankbar-widget and desktop-widget capabilities, requiring DMS >=2.0.0.

The public release listing consulted showed v2.0.0; the announcement describes 2.0.1 as the upcoming repository migration. A v2.0.1-specific contract was not verified. A reported CLI version does not identify the exact embedded source commit. The local embedded QML files are therefore checked directly and fingerprinted in host-api-evidence.json; they must not be represented as byte-identical to the public v2.0.0 tag.

Official references: [2.0 announcement](https://duxlabs.dev/blog/v2-0-release), [release listing](https://github.com/duxlabs-dev/dux-shell/releases), [plugin overview](https://duxlabs.dev/docs/dms/plugins-overview).

## Integration findings from the installed host

The findings below come from the embedded shell source actually present on this machine. Public repository links are reference locations, not claims that an unpinned master branch matches this installed build. Treat shell-internal components as version-coupled integrations behind a small adapter.

### 1. Keep the native plugin and popout lifecycle

PluginComponent already exposes popoutContent, interactionActive, surfaceLive, parentScreen, barConfig and the host-calculated icon/text sizes. The host PluginPopout extends DPopout: it owns outside-click dismissal, Escape/focus handling, content padding and the trigger output. Its content loader binds contentHeight to the loaded item's implicitHeight plus native padding.

Consequently, DevicePanel should expose a meaningful content-driven implicitHeight. Remove fixed 560 px assumptions and avoid calculating implicitHeight from a parent height that depends on it. Constrain the scroll viewport against the selected output's available geometry without double-counting host padding. Do not create another PanelWindow for this attached popout, duplicate its outer chrome or add a second open transition.

PopoutComponent is an available optional header/details composition helper. It is not mandatory when the approved design needs a custom header with History/Settings controls.

### 2. Use the existing visual toolkit

The installed shared library has DCard, DListRow/DListItem, DIconButton, DButtonGroup, DTabBar, DCollapsibleSection, DSlider, DDropdown and DToggle. DCard carries tone-aware foreground/background, focus and accessibility behavior; DTabBar supports arrow navigation; DCollapsibleSection provides a real accessible disclosure.

The shell also has qs.Modules.Settings.Widgets with SettingsGroup, SettingsToggleRow, SettingsDropdownRow, SettingsSliderRow and navigation rows. Their current signals/properties were inspected directly. Use these grouped rows, or DCommon primitives where a generic control is sufficient, rather than imitating the shell's settings with bespoke rectangles.

SettingsGroup recognizes its row contract, including isSettingsRow and layout behavior. An arbitrary PreferenceRow Item cannot be inserted and assumed to behave as a native grouped row. Adapt the reusable editor boundary deliberately.

Official toolkit references: [development guide](https://duxlabs.dev/docs/dms/plugin-development), [dux-qml-common repository](https://github.com/duxlabs-dev/dux-qml-common).

### 3. Connect to the shell theme; do not create another theme engine

The installed shell initializes DCommon Style with Theme and SettingsData. Style already exposes light mode, surface and content roles, selected-container contrast roles, spacing, radius and motion preferences. Use qs.Common Theme for shell-specific roles and qs.DCommon.Common Style for shared widgets.

A Gbuds VisualTokens component, if retained, should be a thin semantic adapter for part states and approved artwork, not a separate palette or theme singleton. Use matched container/content colors; a primary accent is not universally a readable icon foreground. Selected controls can use selectedContainer/onSelectedContainer or their verified accent counterparts.

The actual bar pill resolves its background through BarMetrics and barConfig, while Theme.widgetIconColor resolves to surfaceText in this build. That proves a global foreground is not automatically tailored to every customized pill fill. It does not prove the unique cause of the user's screenshot. Audit saved Gbuds color overrides and effective pill fill together before choosing a contrast correction.

### 4. Use native SVG tinting where the assets support it

DSVGIcon exposes source, colorOverride, corner-icon options and HiDPI raster sizing. For a compatible monochrome approved SVG, colorOverride can follow the theme without rebuilding a colored data URL each animation frame. Use DIcon for native action glyphs, DSVGIcon for approved vectors, and Image for the original material renders.

Validate the existing Qt-compatible flattened ANC cutout and separate semantic idle overlay before replacing the generated icon path. Qt's supported SVG subset still matters; native tinting does not make unsupported masks render correctly. A single color override also must not flatten a deliberately multicolored warning badge. Measure the small-layer cost instead of assuming shader tinting is always cheaper than the existing cached source.

### 5. Follow global motion settings

SettingsData.reduceMotion, Style.reduceMotion, Theme durations/curves and DCommon Common DAnim already exist. Replace the proposal's hard-coded universal 180–220 ms timings with these host tokens; those earlier numbers describe visual intent only. Native widgets already animate appropriate state changes.

Observe the plugin's interactionActive and lifecycle, so cached but closed popout content does not keep animations or optional audio work alive. Reduced motion and disabled animation speed must both be honored. Do not replace the user's established wave timing with a generic theme spring; the explicit 250 ms launch spacing and 1000 ms repeat gap remain product semantics.

### 6. Use native settings persistence without initialization writes

PluginSettings already wraps saveValue/loadValue, permission checking and pluginService integration. Keep ConfigStore as the immediate-update/batched-write boundary and persist through that API. The current manifest already grants settings_read/settings_write.

A subtle compatibility finding: the installed legacy SliderSetting wrapper saves on its value property changing, including programmatic assignments. It cannot be substituted blindly where the contract requires opening settings to write nothing. Prefer native row edit signals routed explicitly into ConfigStore and verify initialization behavior in the real host.

Global plugin values and per-instance desktop values remain distinct. Do not edit plugin_settings.json from presentation code. Keep command history in a bounded daemon-owned in-memory model/global snapshot so closing a cached or reconstructed panel does not recreate its transport controller.

### 7. Navigation has a real host API

The installed PopoutService has openSettingsWithTab(tabName, returnOrigin, reopen). Follow-up implementation inspection found that SettingsTabs.pluginPage(pluginId).id supplies the canonical plugin:<pluginId> route; main's older plugin_<pluginId> route must not be copied. Use the canonical helper. Use the corresponding native Bluetooth page for pairing once its route is confirmed. Do not guess a route solely from the visible tab label.

The visual section navigation in the mockup is inside the plugin settings content. It is not a request to patch Dux's global sidebar. Its presentation should adapt to the native settings viewport.

### 8. Per-event notification rules remain plugin logic

No built-in per-event Popup/Waveup rule editor was established in the plugin guide or inspected services. The proposed notification resolver/editor is Gbuds functionality, rendered with native controls. Clearly distinguish that feature from a Dux API.

Keep the existing single event detector, lifetime controller and wave renderer. Add sparse per-event overrides and separately resolved popup anchors/wave origins. Centering a notification belongs to output geometry and alert placement, not to the attached PluginPopout.

The platform uses Quickshell PanelWindow/Wayland layers for custom alert surfaces. Verify anchors, margins, output scale, empty wave input regions and no alert keyboard focus against this installed Quickshell build. The public Quickshell links retrieved redirected to older v0.1 documentation; those pages are conceptual background, not a verified 0.3.2 API reference.

### 9. Reload commands are build-sensitive

The current web guide shows `dms ipc call plugins reload <id>`. The installed PluginService registers target `plugin-scan`, including the reload/status methods used successfully in this session. Keep the locally verified command rather than replacing it solely to match a newer or differently packaged guide.

The prior native deployment exposed imported-script cache retention. A fresh-process load remains part of release validation after module changes. Do not restart the user's full shell automatically on every visual edit; reserve a managed restart for evidence of stale dependencies or the final isolated integration check.

## Consequences for the approved-design proposal

- Keep the visual composition and approved assets, but implement cards, header buttons, tabs, disclosures and grouped settings with native components.
- Replace speculative fixed motion timings with host motion tokens and the confirmed reduced-motion setting.
- Replace a generic theme subsystem with a small adapter over Theme/Style; test the actual customized bar background.
- Size the panel through native implicitHeight/padding rules and bound its secondary scroll area.
- Keep Sound & controls limited to implemented Galaxy Buds capabilities; presets and ambient amplification are device controls, not operating-system audio controls.
- Keep Advanced notifications as a custom event policy/editor using native form rows; it is not an undocumented Dux feature.
- Keep code/UI in English, the functional controllers unchanged where possible, and use focused compatibility adapters for shell-internal APIs.

Implementation remains awaiting the user's confirmation. No runtime changes or deployment were performed during research.
