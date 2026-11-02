# Visual refinement implementation checklist

Status: candidate 0.7.0-dev.9 prepared on the rewrite branch. See status.md for the implementation and remaining native/hardware acceptance. Follow PLAN.md and the repository codestyle.

## V01 — Resolve theme contrast

- [ ] Audit effective auto/custom preferences, actual bar background and generated SVG inputs.
- [x] Introduce shared theme roles and verify automatic updates while open.
- [ ] Record dark/light and custom-surface evidence with readable focus/idle/critical states.

Files: VisualTokens.qml, PartIcon.qml, ModeIcon.qml, GbudsBarWidget.qml and relevant behavior checks. Dependencies: approval. Verify contrast against actual backgrounds and retain custom-color migration. Scope: medium.

## V02 — Restore the panel hierarchy

- [x] Build header/hero/footer using main as presentation reference and actual approved assets.
- [x] Display safe contextual search hints, aligned batteries and equal noise controls.
- [ ] Remove fixed empty height and verify small-height scroll behavior and keyboard focus.

Files: DevicePanel.qml, PanelHeader.qml, PanelHero.qml, GbudsBarWidget.qml. Dependencies: V01. Verify native screenshots, no unsafe Find and stable pending feedback. Scope: medium.

## V03 — Add bounded command history

- [x] Record job start/completion/uncertainty with a maximum of 80 entries and sanitized details.
- [x] Add History page, empty state, Clear and Back without executing commands on open.
- [x] Ensure watch telemetry never grows the log per packet.

Files: CommandHistory.qml, DeviceController.qml hooks, CommandHistoryPage.qml and focused lifecycle checks. Dependencies: V02. Verify bounded growth, failures and preservation of queue/transport ownership. Scope: medium.

## Checkpoint A

- [ ] Existing behavior/QML checks pass; native panel opens and themes correctly.
- [ ] User can inspect the header, safe Find and readable command results.

## V04 — Model notification exceptions

- [x] Add persisted Advanced switch and sparse per-event settings with explicit inheritance.
- [x] Migrate existing legacy channel overrides idempotently without losing intentional choices.
- [x] Resolve popup position independently from wave origin and preserve event snapshots.

Files: Schema.js, NotificationPreferences.js, EventPolicy.js, NotificationController.qml and focused precedence/migration checks. Dependencies: V01. Verify global Waveup plus noise Popup/Center, Off/inherit and reset. Scope: medium.

## V05 — Support popup anchors and collision handling

- [x] Implement 3 × 3 popup anchors and explicit center placement.
- [ ] Keep deterministic occupancy/reflow within the screen, considering adjacent anchor collisions.
- [ ] Verify mixed Popup/Waveup overlap, independent expiry, output removal and lock suppression.

Files: ScreenPlacement.js, AlertHost.qml, PopupController.qml and placement/runtime scenarios. Dependencies: V05. Verify actual compositor captures and unchanged wave-origin/timing behavior. Scope: medium.

## V06 — Replace the flat notification editor

- [x] Add basic defaults, Advanced switch, event summaries and conditional event fields.
- [x] Add Preview/Reset and meaningful units while reusing ConfigStore/PreferenceRow.
- [x] Make inherited versus overridden values explicit at narrow widths.

Files: NotificationSettings.qml, EventNotificationEditor.qml, SettingsModel.js, Settings.qml and editor scenario. Dependencies: V05–V06. Verify each visible option affects the next production preview; opening writes no defaults. Scope: medium.

## Checkpoint B

- [ ] Requested global-Waveup / centered-noise-Popup scenario passes with simultaneous events.
- [ ] Existing animation timing, process failure and safe Stop checks remain green.

## V07 — Organize the remaining settings

- [ ] Add Device panel, Bar, Notifications, Desktop widgets and Advanced sections inside native plugin settings.
- [x] Keep global and per-instance controls separate and fix product-copy/schema duplication.
- [x] Restore the direct settings route and capability-based Sound & controls.

Files: Settings.qml, SettingsModel.js, section delegates and Schema.js as needed. Dependencies: V02, V04, V06. Split into smaller commits if more than five files become necessary. Verify keyboard navigation, conditional controls and persistence. Scope: medium per slice.

## V08 — Apply restrained motion

- [x] Add host-compatible reveal, selection, disclosure and page transitions.
- [x] Respect reduced motion, cancellation and input responsiveness.
- [x] Keep the hero clear of animated background decoration after visual review.
- [ ] Capture actual transitions without changing the shared wave engine contract.

Files: panel/hero delegates and shared motion tokens. Dependencies: V02–V07. Verify rapid edits, disposal, open/close and reduced motion. Scope: medium.

## V09 — Package and acceptance

- [x] Capture the native light/dark panel and sound-controls showcase.
- [x] Tag the reviewed commit, back up the installed candidate, package exact source, and confirm plugin reload.
- [ ] Complete physical Buds controls, visual acceptance and rollback before merge.

Files: evidence report, deployment manifest and status documentation. Dependencies: V08. Preserve the functioning base candidate and immutable tags. Scope: small; physical acceptance remains explicit.

## Research corrections before implementation

- Native integration authority: DUX-INTEGRATION-RESEARCH.md and host-api-evidence.json.
- V01: reuse Theme/Style and test DSVGIcon with the existing Qt-compatible artwork; do not introduce an independent palette engine.
- V02: use native PluginPopout implicitHeight/padding, avoiding duplicate outer chrome and opening animations.
- V07–V08: use native grouped Settings rows and explicit user-edit signals; the installed SliderSetting wrapper can save programmatic value changes.
- V09: use verified global reduced motion and host motion tokens. Existing wave sequence timing remains unchanged.
- V09: locally verified reload target is plugin-scan, whereas current web docs show plugins. Verify actual installed IPC and fresh-engine dependency loading.

## Evidence index

Checked implementation criteria map to the commit index and verification evidence in status.md. Unchecked acceptance items retain native keyboard, hardware, performance or mixed-display verification; they are not implied by fixture success.
