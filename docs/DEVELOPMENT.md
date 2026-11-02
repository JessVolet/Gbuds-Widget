# Development

Use tasks/rewrite/codestyle.md and the contracts beside it. Artwork remains in assets/approved and generated templates are rebuilt with:

```sh
python3 scripts/build-icons.py
```

Run focused policy, motion, asset and registry checks:

```sh
node tests/motion.test.cjs
node tests/daemon.test.cjs
node tests/notification-policy.test.cjs
node tests/policy.test.cjs
node tests/icons.test.cjs
python3 tests/deployment.test.py
```

The runtime check uses fake CLI processes, including failed Stop, timeout and missing-executable cases:

```sh
sh tests/run-runtime.sh
```

Run inside a Wayland session. An absolute WAYLAND_DISPLAY can be provided if the test uses a temporary XDG_RUNTIME_DIR.

Capture actual renderer samples (EVIDENCE_DIR must be an absolute writable directory):

```sh
EVIDENCE_DIR=/tmp/gbuds-motion-evidence sh tests/motion/capture.sh
python3 tests/motion/analyze.py /tmp/gbuds-motion-evidence
```

GBUDS_CAPTURE_SCENE may select tests/presentation/scene.qml or tests/motion/profile.qml by absolute path. Presentation captures use production layouts/assets with fixture Dux controls. They do not certify native Dux styling, physical Bluetooth or lock-screen input. The 30-second profile measures QML animation update cadence, not GPU presentation latency.

Package only a committed candidate:

```sh
python3 scripts/package.py rewrite-candidate-v1 /tmp/gbuds-candidate.tar.gz
python3 scripts/deploy-local.py --artifact /tmp/gbuds-candidate.tar.gz --backup-dir /tmp/gbuds-backups
```

Deployment stages the artifact outside the scanned plugins directory, preserves local Git metadata, swaps directories, uses plugin-scan reload and checks loaded status. It restores the previous directory on failure. Matching artifact hashes and loaded status are deployment evidence, not visual acceptance.

Rollback the resulting backup directory:

```sh
python3 scripts/deploy-local.py --restore /tmp/gbuds-backups/EXACT_BACKUP_DIRECTORY
```

Restoration merges the saved gbudsWatch preferences into current settings, preserving changes to other plugins. The deployment test rehearses install/restore against temporary directories. Verify native Dux settings reload and artwork/motion after an actual rollback.

Never deploy an unreviewed working directory by copying every file. Do not publish remote tags or merge the candidate before the requested testing/review stage is complete.
