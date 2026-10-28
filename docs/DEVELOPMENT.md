# Development and live testing

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

```bash
ln -s /home/vsynlo/Proyectos/Self/Dux-GalaxyBuds/Gbuds-Watch \\
  ~/repos/dux-shell/quickshell/PLUGINS/gbudsWatch
```

## Runtime symlink and reload

```bash
ln -s /home/vsynlo/Proyectos/Self/Dux-GalaxyBuds/Gbuds-Watch \
  ~/.config/dms/plugins/gbudsWatch
dms ipc call plugins reload gbudsWatch
```

Enable the composite plugin in **DMS Settings → Plugins**, then add the widget to the bar and place the desktop widget from **Settings → Desktop widgets**. Plugin reload only reloads plugin QML; it does not require restarting the shell.

## Real-device testing

1. Connect one paired, supported Galaxy Buds device.
2. Confirm the CLI works: `gbuds watch --json`.
3. Enable Gbuds Watch, add the bar pill, and place the desktop widget. Confirm all surfaces show the same current device and battery state.
4. Open the popout. Use the device picker if multiple Buds are paired, then verify the model art and available noise modes match `gbuds info --json`.
5. Change ANC mode, touchpad lock, and EQ from the popout. Confirm the console view shows each real command response and that the live watch resumes afterward.
6. Change placement, ANC, or battery state in Samsung's app. Confirm the bar icon turns red when either earbud leaves the ear and that connection, placement, noise-mode, 30%, and 10% transitions produce their specific cards without desktop notifications.
7. Switch between the paired FE and Buds3. The selected model, renders, supported controls, and stream should follow the active device; manually select it from the popout if BlueZ does not expose a unique connected device.
8. Disconnect and reconnect the Buds. The bar pill should switch to its disconnected icon; the widget should clear displayed battery values and retry without restarting the shell.
9. Add two desktop instances. Select **Full** for one and **Compact** for the other in their instance settings, then resize the compact instance. Confirm both update together and the compact noise-mode switcher lists only supported modes.
10. Disconnect the Buds. Confirm both desktop instances become visually and interactively transparent, then reconnect and confirm they return.
11. Trigger a connection while both Buds are in the case, remove only one earbud, then change the noise mode. Confirm the square floating card shows the case, that earbud, and the mode icon respectively; it must remain outside the widget and not appear as a DMS notification.

If DMS cannot find the CLI, set **Gbuds executable** in plugin settings to its absolute path. See the [Gbuds installation guide](https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md) if it is not installed.

## Current environment notes

- Dux Shell installed in the development machine: `dms (git) v2.0.0-5380`.
- `gbuds capabilities --json` supplies cached model metadata in parallel with the persistent `gbuds watch --json` stream; control commands resume the stream directly.
- The developer has Galaxy Buds FE and Galaxy Buds3 available for hardware testing. Other models need user validation; missing artwork falls back to Material icons.
- Copied GalaxyBudsClient renders are documented separately in `assets/README.md`; check individual redistribution rights before publishing a binary bundle.
