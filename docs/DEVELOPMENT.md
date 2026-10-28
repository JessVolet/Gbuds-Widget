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
3. Enable Gbuds Watch and check that both the bar pill and desktop card show the same battery and noise-control state.
4. Change state using Samsung's app. Confirm the desktop event line and the two surfaces update from the next telemetry event.
5. Disconnect and reconnect the Buds. The card should enter its waiting state and retry without restarting the shell.

If DMS cannot find the CLI, set **Gbuds executable** in plugin settings to its absolute path. If `gbuds` is not installed, the desktop widget links to the [Gbuds installation guide](https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md).

## Current environment notes

- Dux Shell installed in the development machine: `dms (git) v2.0.0-5380`.
- `gbuds info --json` is queried once at startup to choose an available device render; the persistent status stream is `gbuds watch --json`.
- The developer has Galaxy Buds FE and Galaxy Buds3 available for hardware testing. Other models need user validation; missing artwork falls back to Material icons.
- Copied GalaxyBudsClient renders are documented separately in `assets/README.md`; check individual redistribution rights before publishing a binary bundle.
