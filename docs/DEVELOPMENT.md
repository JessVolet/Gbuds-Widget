# Development and live testing

## Editing the approved SVGs

The L/R drawings, timer, and noise modes live separately in `assets/approved/`.
Run `python3 scripts/build-icons.py` after editing. Keep the generated
`interface-v060/ApprovedIcons.js` in the same commit so installed plugins use the edits.
Use `node tests/icons.test.cjs` to validate the generated asset set.
The final template can be rebuilt from the originals saved in
`assets/source-icons/` using `python3 scripts/import-template.py` followed by
`python3 scripts/build-icons.py`.
After a dependency edit, Qt may cache the old local component or JavaScript;
verify the result after reload, or restart Dux if that dependency stays cached.

The 0.6.0 compact desktop starts at 336 × 232. The timer is a separate
overlay, about 57% of the glyph height, controlled independently for each side.

Run `node tests/daemon.test.cjs`, `node tests/policy.test.cjs`,
`node tests/notification-policy.test.cjs`, and `node tests/icons.test.cjs`.
They execute the functions extracted from the QML source with simulated state.
They cover device-bound requests, queue limits, failure recovery, and target-switch
races. In a Wayland session, run `sh tests/run-runtime.sh` for the real QML
process/UI flow with a fake executable and fake BlueZ state. It checks offline
Connect, the initial capability filter, individual icon clicks, Stop, stopping
before Disconnect, stale BlueZ state, and capability refresh on reconnection.
The harness never invokes the real `gbuds` binary. Hardware validation is separate.

For the 0.2.0 visuals, check light/dark themes, horizontal/vertical bars, and
desktop sizes from 260 × 140 upward. Only placement `IDLE` shows the timer;
`WEARING`, `IN_CASE`, and `DISCONNECTED` must not. Verify the toggle and custom
idle color still work, ANC highlights remain readable, and separate instances
share telemetry. Existing bar style preferences are kept.

## Dux Shell QML environment

The project follows the Dux Shell 2.0 plugin guide. Its recommended development checkout is `~/repos/dux-shell` with submodules, so the QML language server can resolve the `qs.DCommon.Widgets` imports:

```bash
mkdir -p ~/repos
git clone --recurse-submodules https://github.com/duxlabs-dev/dux-shell.git ~/repos/dux-shell
cd ~/repos/dux-shell/quickshell
touch .qmlls.ini
qs -p .
```

After Quickshell starts, stop it with Ctrl+C. The plugin's source of truth is this repository. For IDE imports, symlink its folder into `~/repos/dux-shell/quickshell/PLUGINS`; for runtime discovery, symlink it into `~/.config/dms/plugins`.

From the Gbuds Widget repository directory:

```bash
ln -s "$PWD" ~/repos/dux-shell/quickshell/PLUGINS/gbudsWatch
```

## Runtime symlink and reload

```bash
ln -s "$PWD" ~/.config/dms/plugins/gbudsWatch
dms ipc call plugins reload gbudsWatch
```

Enable the composite plugin in **DMS Settings → Plugins**, then add the widget to the bar and place the desktop widget from **Settings → Desktop widgets**. Plugin reload only reloads plugin QML; it does not require restarting the shell.

## Real-device testing

1. Connect one paired, supported Galaxy Buds device.
2. Confirm the CLI works: `gbuds watch --json`.
3. Enable Gbuds Widget, add the bar pill, and place the desktop widget. Confirm all surfaces show the same current device and battery state.
4. Open the popout. Use the device picker if multiple Buds are paired, then verify the model art and available noise modes match `gbuds info --json`.
5. Change ANC mode, touchpad lock, and EQ from the popout. Confirm the console view shows each real command response and that the live watch resumes afterward.
6. Change placement, ANC, or battery state in Samsung's app. Confirm the bar icon turns red when either earbud leaves the ear and that connection, placement, noise-mode, 50%, and 20% crossings follow the selected Popup/Waveup channel.
7. Switch between the paired FE and Buds3. The selected model, renders, supported controls, and stream should follow the active device; manually select it from the popout if BlueZ does not expose a unique connected device.
8. Disconnect and reconnect the Buds. The bar pill should switch to its disconnected icon; the widget should clear displayed battery values and retry without restarting the shell.
9. Add two desktop instances. Confirm both start Compact, then choose different presets, artwork and blocks. Select distinct monitors and compare synchronized versus independent placement.
10. Disconnect the Buds. By default both instances should disappear. Set one to **Mostrar Conectar** and the other to **Mostrar estado** to confirm their policies are independent. Click Connect to reconnect to the last selected device. With several paired Buds and no remembered selection, the button reveals a device chooser.
    Confirm the initial `capabilities` result is fetched again, so Buds3 does not
    inherit FE's Ambient option. An explicit unsupported/not-implemented feature
    must stay unavailable.
11. Use the simulated preview buttons to verify 50%, 20%, ANC, and removal without affecting real hardware. Then trigger a real one-ear removal and noise change; confirm the popup artwork follows the affected side and Waveups originate from the corresponding corner without capturing clicks.
12. With an earbud out of the ear and case (`IDLE`), click its icon to ring that
    side. Click again to stop. Worn/stored/unavailable/unknown placements cannot
    start a search. Search also requests Stop after 30 seconds or a placement
    change. **Desconectar** below CASE stops an active search before disconnecting;
    if Stop fails, it leaves Stop available and cancels that disconnect.

If DMS cannot find the CLI, set **Gbuds executable** in plugin settings to its absolute path. See the [Gbuds installation guide](https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md) if it is not installed.

## Current environment notes

- Dux Shell installed in the development machine: `dms (git) v2.0.0-5380`.
- `gbuds capabilities --json` supplies cached model metadata in parallel with the persistent `gbuds watch --json` stream; control commands resume the stream directly.
- Capability declarations describe CLI/model metadata, not a successful hardware
  probe. The current CLI reports Find/Touchpad/EQ as unknown; their controls remain
  usable where telemetry permits, without presenting them as confirmed support.
- The developer has Galaxy Buds FE and Galaxy Buds3 available for hardware testing. Other models need user validation; missing artwork falls back to Material icons.
- Copied GalaxyBudsClient renders are documented separately in `assets/README.md`; check individual redistribution rights before publishing a binary bundle.
