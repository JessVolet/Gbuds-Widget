# Changelog

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
