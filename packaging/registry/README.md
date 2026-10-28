# Dux plugin registry submission

Copy `jessvolet-gbuds-widget.json` to `plugins/jessvolet-gbuds-widget.json` in a fork of the [Dux plugin registry](https://github.com/duxlabs-dev/dux-plugin-registry). The manifest `id`, `name`, and capabilities match this repository's `plugin.json`. The screenshot URL becomes live after this repository and its `main` branch are published.

The entry lists Hyprland because that is the compositor used for local testing. Add other compositors after validation. `gbuds-cli` and BlueZ are external runtime requirements; the registry does not install them automatically.

Before opening or updating the registry PR, validate in the registry checkout:

```bash
python3 .github/generate.py --validate
python3 .github/validate_links.py
```

See the [official registry contribution guide](https://duxlabs.dev/docs/contributing-registry) for the current submission format.
