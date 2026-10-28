# Contributing to Gbuds Widget

Changes are welcome: model support, bug fixes, translations, accessibility, design refinements, and documentation. Open an issue or pull request describing the user-visible behavior and, where relevant, the Dux Shell and `gbuds-cli` versions used.

For model compatibility reports, include the marketing name, model code, firmware version, CLI command, and observed result. The first-generation SM-R170 protocol is not implemented by `gbuds-cli`. Do not share Bluetooth addresses or serial numbers in public logs.

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for a local Dux Shell setup and a real-device test checklist. Please run `git diff --check` and validate `plugin.json` against the Dux schema before submitting. A change to a model-specific control should be tested on that device or clearly marked as unverified.

The project uses AI-assisted code and documentation. AI-assisted contributions are welcome, but contributors should review their changes, describe what they verified, and avoid claiming untested model support.
