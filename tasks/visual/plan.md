# Gbuds visual refinement proposal

Status: implemented on `rewrite/modular-widget` as testing candidate 0.7.0-dev.8; see status.md. Read DUX-INTEGRATION-RESEARCH.md first: verified native integration findings supersede speculative APIs and fixed timing suggestions below.

## Reference and scope

Use local main commit `766fe60da064ff477bbf91515343a4250de3c938` as the presentation reference: BudsHero header shortcuts, three-part battery hero, Noise control, progressive Sound & controls and internal Devices/terminal pages. Keep the rewritten controllers and confirmed functional behavior. The old terminal displayed the latest result; a real bounded history is new work.

The current candidate already has theme bindings and per-event notification channel selectors. The demonstrated gaps are visual hierarchy/contrast, discoverability, and per-event placement. Do not describe automatic theming as wholly absent without tracing effective preferences and the actual bar surface. Desktop behavior is outside this visual redesign except shared icon/theme improvements and notification settings scope.

The standing contract is tasks/rewrite/codestyle.md: English UI/code/documentation, sparse explanatory comments, focused reusable modules, validated argv, bounded resources and immediate configuration feedback. These mockups are standalone SVG compositions using the repository's actual approved icons and Buds3 renders. They are proposed visuals, not runtime screenshots or validated theme contrast measurements.

## 1. Expanded widget composition

Target width approximately 400–420 logical pixels, with content-driven height capped to the available output work area. Avoid today's fixed-height empty tail. Keep the host's positioning and input/focus rules. At small heights, scroll secondary content while keeping the header reachable.

| Region | Content | Interaction |
| --- | --- | --- |
| Header | Actual device name, quiet connection state, History and Settings icon buttons | History opens an internal page; Settings opens this plugin's native settings route. All icon buttons have labels/tooltips and keyboard focus. |
| Device hero | Left render/icon, case, right render/icon; aligned labels, percentages and slim battery indicators | Each earbud remains its own Find target. Show `Click for search` only when safe/available; otherwise `In ear`, `In case`, or `Unavailable`. While searching show `Stop search`; an uncertain result retains Stop. |
| Under case | Low-emphasis `Disconnect` action | Retain the existing safe Stop-before-disconnect path. It is not the dominant call to action. |
| Noise control | ANC, Ambient/Adaptive, Off in equal-size slots, with selected state | Use the approved centered ANC and ear/power artwork. Show only capability-supported modes. Pending state is distinct from confirmed state. |
| Sound & controls | Collapsed row with native Dux cards | Expand the equalizer presets, touch lock, ambient amplification, voice detect and lights only when supported. Reuse existing intents. Unsupported controls do not leave gaps. The equalizer curve is illustrative and does not claim to measure frequency response. |
| Footer | `Manage connections` | Open the internal connections page, retaining name/header and a Back action. No second external modal is needed. |

The sample hero assumes both earbuds are out of ear so both search hints are visible. Ambient in the mockup demonstrates layout; runtime capabilities remain authoritative.

### Internal pages

- **Connections:** paired Galaxy Buds, current selection, clear Connect/Disconnect state, pending feedback and concise errors. Switching targets retains existing safety gates. Offer the native Bluetooth settings route for pairing rather than inventing a plugin scanning implementation.
- **Command history:** newest first; time, readable action, Pending/Succeeded/Failed/Uncertain, duration and expandable sanitized details/argv. Keep at most 80 entries in memory. Include one-shot CLI jobs and one lifecycle entry for each watch start/stop; never append every telemetry packet. Do not expose a free-form terminal or replay button. Opening/clearing history executes no hardware action. Raw MAC addresses and private paths are hidden in the normal view.
- **Settings:** direct native plugin settings navigation, using the route already present in main when supported. Provide an explicit fallback if that route is unavailable in the host.

## 2. Automatic light/dark appearance

Create one theme/visual token component for foreground, secondary foreground, icon, container, selected state, outline, warning and critical colors. Derive bar colors from the host bar's actual color/contrast roles, and panel colors from surface roles. Reuse the same tokens in badges, approved SVGs, case and noise icons.

`Follow system` is the default for new preferences. Preserve deliberate existing custom colors; display their current mode and provide `Reset to system` rather than silently replacing them. Distinguish normal theme color from warning/critical semantic accents so an amber idle marker is not mistaken for a theme failure.

Audit the effective persisted preferences and SVG generation first. Resolved icon identity must include all color/style inputs and update when the theme changes. Do not generate new SVG strings every frame; animate the surrounding surfaces/opacity, not a color-to-data-URL pipeline. Device renders retain their original materials; same-side fallback SVGs use theme colors immediately.

Verify dark/light, selected/unselected, custom bar colors, transparent backgrounds, idle and low battery. Target text contrast 4.5:1 and meaningful icon/focus contrast 3:1 against the resolved background. Theme changes must not require reopening the panel or reloading the plugin.

## 3. Settings information architecture

Use a small section selector inside the plugin's own settings content, adapting to tabs or a vertical section list with available width. The mockup's left navigation belongs to the plugin content; it does not require rewriting Dux's global settings sidebar.

1. **Device panel:** SVG/render/automatic artwork, search hints, panel motion and reduced-motion preference. Show only useful controls; retain capability-driven Sound & controls in the popout.
2. **Bar:** layout, icon size/spacing/alignment, percentages, noise icon visibility, automatic/custom icon colors and idle/battery appearance. Keep custom fields conditional on Custom.
3. **Notifications:** enable, global default style, relevant duration controls, artwork, default placement/display, Preview; then Advanced notifications.
4. **Desktop widgets:** explain global versus per-instance settings. Geometry, ordering and offline visibility remain in the instance editor; do not duplicate controls whose values cannot affect that instance.
5. **Advanced:** executable/target diagnostics and optional diagnostic detail. Command history is also directly accessible in the popout header. Technical fields are not mixed into normal appearance settings.

Reuse PreferenceRow primitives with richer definitions for descriptions, visibility and units. Separate section components replace one long flat repeater. Values still flow through the existing reactive ConfigStore; opening settings writes nothing. Remove the current `settingsStore` typo from product copy and the duplicate schema declaration during the focused configuration cleanup.

## 4. Advanced notifications

Add a persisted `Advanced notifications` switch in Notifications. When on, show an Events list and the selected event's editor. When off, all events inherit global defaults; keep custom definitions saved but inactive. Existing legacy channel overrides migrate with Advanced enabled, preserving behavior. Newly created settings default to Waveups; existing global presentation choices are preserved.

Each event summary states `Use default · Waveups` or a compact exception such as `Custom · Popup · Center`. No hidden override may disagree with its displayed summary.

### Per-event editor

- **Presentation:** Use default / Off / Popup / Waveup / Both.
- **Popup position:** Use default / Match earbud / Top left / Top center / Top right / Center left / Center / Center right / Bottom left / Bottom center / Bottom right. A 3 × 3 picker is accompanied by an explicit text label. Shown only if the resolved channel includes a popup.
- **Waveup origin:** inherit / match earbud / left / right / both, plus top/bottom corners. Shown only if the resolved channel includes Waveup. It never reinterprets Center as a wave origin.
- **Display:** inherit / active / primary / selected connected output; explain fallback for a missing output.
- **Popup duration / Wave duration:** inherit or explicit seconds, independently shown for the resolved channels.
- **Artwork:** inherit / SVG / Render / Automatic, only when there is visible popup artwork.
- **Wave appearance:** inherit by default; advanced reach/stroke/tone options are conditional. Keep the established semantic ring count and 250 ms stagger / 1000 ms repeat gap.
- **Preview event** and **Reset to default**. Preview uses the real production router/renderer with a simulated event, never a hardware command.

Events: Connected, Disconnected, Removed from ear, Back in ear, Removed from case, Stored in case, Noise mode changed, Battery at 50%, Battery at 20%, Out-of-ear reminder. Reminder frequency appears only for the reminder event when enabled. Left/right/pair/case subjects remain available as preview choices where meaningful. Noise mode can optionally be narrowed to ANC/Ambient/Off in a nested subrule later; the initial approved scope is one shared noise-change rule.

### Requested example

Global: Waveups, 5 seconds. Advanced: enabled. Noise mode changed: Popup, Center, active display, 4 seconds. Other events: Use default. A simultaneous ear-removal event still produces its corner Waveup; the noise popup does not replace or restart it.

### Routing contract

Introduce a pure NotificationPreferences resolver: global defaults → enabled event exception → validated effective settings. Store sparse event overrides, not copies of all defaults. A reset removes that override; changing the global default updates inherited fields immediately. Define precedence explicitly: event position overrides global Match earbud, and an explicit Center never becomes a side anchor.

Resolve channel, popup placement and wave origin separately. Snapshot the resolved event settings at enqueue; ordinary settings edits affect the next event/preview, while reactive theme colors can still update visible notifications without resetting clocks. Popup occupancy must consider actual rectangle collisions across neighboring anchors, not just identical group strings. Reuse the existing lifetime controller and deterministic lane placement; support center stacking within screen bounds, reflow and bounded overflow. Keep screen selection fixed for an active event unless that output disappears. Lock suppression and no-keyboard-focus behavior remain mandatory.

## 5. Motion and presentation

- Open: use the host transition and avoid competing opening effects.
- Hero: restrained expanding rings and slow Material gear glyph rotation while visible. Stop when hidden or reduced motion is active. Hover/focus uses a small background/elevation change. Press feedback does not delay intents.
- Noise selection: 140–180 ms highlight transition with immediate pending feedback; confirmation/failure reconciles through existing state.
- Disclosures and internal pages: 160–200 ms height/opacity or short directional transition. Preserve scroll/focus and avoid recreating the device controller.
- Battery: animate the indicator only when values change; never loop while idle.
- Search: clear ongoing marker plus Stop; respect reduced motion and terminate on completion/disposal.
- Reduced motion: eliminate translation/scale and decorative sequencing, keep immediate selection/focus feedback. Use a small host preference adapter if the platform exposes reduced motion; retain an explicit plugin override.
- Existing wave engine timing and the proven zero-radius behavior stay unchanged.

## 6. Implementation map

| Responsibility | Planned location |
| --- | --- |
| Header, composition and route state | src/surfaces/DevicePanel.qml plus PanelHeader.qml and small page delegates |
| Panel-specific hero | src/surfaces/PanelHero.qml; reuse PartIcon and safe state intents, avoid coupling panel layout to desktop config |
| Noise selection and secondary controls | Existing NoiseControls.qml / AdvancedControls.qml, with shared visual tokens |
| Theme roles | src/presentation/VisualTokens.qml, consumed by bar, panel, SVG artwork and popup |
| Bounded command log | src/device/CommandHistory.qml, fed from existing job start/result hooks; no extra process owner |
| Event defaults/exceptions | src/config/NotificationPreferences.js, schema migration and existing ConfigStore |
| Event editor | src/settings/NotificationSettings.qml / EventNotificationEditor.qml; reuse PreferenceRow |
| Notification routing/placement | Existing NotificationController.qml, AlertHost.qml, ScreenPlacement.js and PopupController.qml |
| Settings composition | Settings.qml delegates to section components; existing instance editor remains scoped |

Final names may follow existing module conventions. Do not create a second command queue, event detector, animation clock or transport owner. Keep qmldir registrations and runtime harness updated with each slice. New script/module deployment must include a fresh-engine validation because the prior session demonstrated native cache retention.

## 7. Delivery and acceptance

Implementation starts only after user confirmation of these mockups and scope. Work stays on the rewrite branch, in reviewable commits with immutable milestone tags. Preserve the currently working installed candidate until a tested package is ready. Do not merge or deploy this design document itself.

Acceptance includes real native dark/light screenshots, no clipping at small output heights, theme change while open, keyboard and focus labels, correct per-event example, simultaneous center popup plus side Waveup, bounded history, target-specific audio controls, capability variants, and no regressions in the existing Find/Stop/disconnect and zero-radius wave checks. Record physical audio/connection limitations separately from fixture tests. Rehearse compatible preference migration and local rollback before the final merge gate.
