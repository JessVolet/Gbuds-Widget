# Device image credits

## Approved 0.3.0 icon artwork

`approved/bud-left.svg` and `bud-right.svg` preserve the path, head circle, and
sensor from the user-supplied `gemini-svg(2).svg`, with the approved opposite poses.
`mode-*.svg` use the embedded SVG ear recovered from `New Project.svg` (img3),
plus the supplied wave image (img5) traced into vector curves. The idle timer
preserves the previously supplied timer SVG. The neutral case is widget artwork.

Edit those SVG files independently, then run `python3 scripts/build-icons.py`.
That compiles `presentation/ApprovedIcons.js`, applies the QML theme color at runtime, and
flattens nested SVG viewports into equivalent transforms for Qt SVG.
The source files remain editable SVGs with no embedded raster images.

The earlier slim SVG earbud silhouettes in `icons/` are original widget artwork.
The idle timer comes from the user-supplied `timer-svgrepo-com.svg`
(SVG Repo; the supplied file does not include an author or license).
Its geometry is preserved in `icons/idle-timer.svg` and `approved/idle-timer.svg`, with
theme-controlled color. Confirm that asset's license before public distribution.

The earbud renders in this directory are copied from the GalaxyBudsClient repository:

- Source: `GalaxyBudsClient/Resources/Device/Realistic/`
- Upstream: <https://github.com/timschneeb/GalaxyBudsClient>
- Upstream commit introducing the realistic image set: `60e93cb356a6e5ae87824a5f79f588981ca96eba`
- Upstream project license: GNU GPL-3.0 (see `../LICENSE-GPL-3.0`).

Files are used as model illustrations, not as device data. The upstream commit does not document individual image authors or a separate image license. The images are distributed with that provenance note; verify image rights before redistributing a packaged release.

The screenshots in `screenshots/` show the running Gbuds Widget and include those device renders. `presentation.png` is a simple composition of the same screenshots; `presentation.svg` is its editable source. These presentation assets were assembled with AI assistance, while the UI shown in the screenshots is from the actual plugin.
