# Device image credits

## Selected 0.4.0 template

`approved/bud-left.svg` and `bud-right.svg` use the selected original Blade
proposal with opposite diagonal poses, ordered as in the user's final template.
`mode-anc.svg` combines the supplied `shield-alt-1-svgrepo-com.svg` and
`ear-2-svgrepo-com.svg`. Ambient uses `ear-3-svgrepo-com.svg` including its
original curved waves, and OFF uses `power-off-svgrepo-com.svg`.
All original files are preserved under `source-icons/`; their path geometry is
retained and only placement and theme coloring are adjusted.
The idle timer preserves the previously supplied timer SVG. The neutral case
is widget artwork.

Edit those SVG files independently, then run `python3 scripts/build-icons.py`.
That compiles `interface/ApprovedIcons.js`, applies the QML theme color at runtime, and
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
