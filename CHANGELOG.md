# Changelog

## 0.6.4

- Remove the Waveup center dot.
- Stagger each ring by 250 ms for a clearer wave sequence.

## 0.6.3

- Anchor each transparent Waveup surface to the full selected monitor and calculate the emitter from that monitor's actual width and height.
- Keep wave size and corner inset independent, preventing the emitter from drifting with the surface dimensions.

## 0.6.2

- Anchor Waveup emitters precisely to the selected screen corner and grow rings inward.
- Scale the transparent wave surface and ring diameters together; expose Wave size in Advanced settings.

## 0.6.1

- Stack concurrent Popup alerts so related changes remain separately visible.
- Add a global Popup/Waveup/Both choice and move per-event controls into Advanced.
- Repeat wave sequences for a configurable duration and interval.
- Translate the settings editor into English.

## 0.6.0

- New desktop instances start with the Compact SVG layout. Each instance can
  choose Compact, Minimal, Detailed, or Custom, hide while disconnected, and
  configure artwork, blocks, spacing, size, background, and monitor placement.
- Reorganized settings into per-widget desktop options and global Bar, Alerts,
  and Device sections. Added multi-display selection and synchronized placement.
- Added configurable Popup and Waveup channels per event. Popups include finite
  waves; Waveups radiate from a monitor corner without focus or pointer input.
- Added side-aware artwork selection, top/bottom and monitor routing, theme-aware
  50%/20% battery waves, reduced-motion option, and cancelable out-of-ear reminders.
- The event detector preserves simultaneous changes, snapshots device artwork
  across disconnects, coalesces paired events, and applies 5-point battery
  hysteresis. Notification previews use simulated events only.
- Lock-screen instances default to hidden while disconnected and read-only;
  optional noise controls stay within the lock-screen widget surface.
- Bar appearance settings and approved icons remain unchanged.

Validation: policy tests for defaults, migration, multi-event frames, battery
hysteresis, paired thresholds, and notification routing; full regression and
Wayland QML harness are run for this release.

## 0.4.1

- Apply the selected filled ANC shield with a transparent ear cutout, reduced
  by 15% and optically centered. Preserve all other artwork and local bar tuning.
- The interface module is versioned so Qt loads the new shared artwork during
  hot reload without restarting the desktop shell.

## 0.4.0

- Match the user's final template: diagonal Blade earbuds with opposite poses,
  shield plus the supplied ear for ANC, supplied ear with curved sound waves
  for ambient, and the supplied power symbol for OFF.
- Preserve the user's local bar tuning: glyph reduction of 5 px, zero horizontal
  spacing, noise glyph 5 px smaller and 3 px lower, and OFF hidden in the bar.
- Original SVG sources are saved under assets/source-icons/; editable themeable
  versions remain in assets/approved/.

## 0.3.0

- Apply the approved mockup using the supplied editable SVG earbuds, recovered
  ear artwork, vectorized waves, and timer. Left and right are independent assets.
- Large idle badges appear independently; noise mode icons match the bar's
  earbud size and are shared by the compact desktop, popout, and event popup.
- Compact desktop uses a taller layout with large device icons and labeled
  mode buttons. Existing placements retain their saved width/height, clamped
  to the new readable minimum of 300 × 220.
- Shared UI and its generated SVG library live in presentation/ so they load together during
  hot reload without reusing Qt's cached previous UI.

## 0.2.1

- Increase bar glyph boxes to square proportions so the narrow SVGs keep their
  height. Earbuds render about 50% taller at the default bar scale.

## 0.2.0

- Slimmer mirrored SVG earbuds, shared between the bar and compact desktop.
- User-supplied timer badge for IDLE earbuds, respecting the existing visibility
  and idle-color settings. In-case earbuds no longer appear idle.
- Theme outlines replace solid green battery icons; low battery remains amber/red
  in the compact view. A readable themed surface replaces the faint desktop panel.
- Case-color preferences now affect the bar. Existing style choices remain valid;
  glow is rendered as a soft fill rather than an expensive blur.
- Commands capture the selected device and time out after 15 seconds. Pending
  metadata is discarded on device switches and limited to 10 seconds.
- Bound command queue, command validation, cleanup during reload, and visible
  action errors. Device switching while stopping the watcher resumes queued work.
- Event popups open on the compositor's focused screen.
- Dependency metadata checks the actual executable, gbuds.

Validation: six Node regression cases, QML loading in a separate Quickshell
instance, success and timeout with a fake CLI, and light/dark QML render previews.
Bluetooth control validation with physical earbuds remains necessary.
