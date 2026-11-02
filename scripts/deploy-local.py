#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import stat
import subprocess
import tarfile
import tempfile
from datetime import datetime, timezone
from pathlib import Path

PLUGIN = 'gbudsWatch'
parser = argparse.ArgumentParser(description='Install or restore a local Gbuds Widget artifact.')
action = parser.add_mutually_exclusive_group(required=True)
action.add_argument('--artifact', type=Path)
action.add_argument('--restore', type=Path)
parser.add_argument('--install-path', type=Path, default=Path.home() / '.config/dms/plugins/Gbuds-Widget')
parser.add_argument('--settings', type=Path, default=Path.home() / '.config/dms/plugin_settings.json')
parser.add_argument('--backup-dir', type=Path)
parser.add_argument('--no-reload', action='store_true')
args = parser.parse_args()
install = args.install_path.absolute()
settings = args.settings.absolute()


def extract(artifact, destination):
    with tarfile.open(artifact) as archive:
        for member in archive.getmembers():
            name = Path(member.name)
            if name.is_absolute() or '..' in name.parts or member.issym() or member.islnk():
                raise ValueError('Unsafe package entry: ' + member.name)
        archive.extractall(destination, filter='data')


def read_settings():
    return json.loads(settings.read_text()) if settings.exists() else {}


def reload_plugin():
    if args.no_reload:
        return 'not-requested'
    subprocess.run(['dms', 'ipc', 'call', 'plugin-scan', 'reload', PLUGIN], check=True, capture_output=True, text=True)
    result = subprocess.check_output(['dms', 'ipc', 'call', 'plugin-scan', 'status', PLUGIN], text=True).strip()
    if not result.startswith('loaded'):
        raise RuntimeError('Plugin did not load: ' + result)
    return result


install.parent.mkdir(parents=True, exist_ok=True)
staging = Path(tempfile.mkdtemp(prefix='.gbuds-stage-', dir=install.parent.parent))
previous = staging.with_name(staging.name + '-previous')
try:
    if args.artifact:
        if not args.backup_dir:
            parser.error('--backup-dir is required for installation')
        backup = args.backup_dir / datetime.now(timezone.utc).strftime('gbuds-%Y%m%dT%H%M%S.%fZ')
        backup.mkdir(parents=True, mode=0o700)
        existed = install.exists()
        with tarfile.open(backup / 'plugin.tar.gz', 'w:gz') as archive:
            if existed:
                for entry in install.iterdir():
                    archive.add(entry, arcname=entry.name)
        snapshot = {'existed': existed, 'settings': read_settings().get(PLUGIN)}
        (backup / 'before.json').write_text(json.dumps(snapshot, indent=2) + '\n')
        os.chmod(backup / 'before.json', 0o600)
        extract(args.artifact, staging)
    else:
        backup = args.restore
        snapshot = json.loads((backup / 'before.json').read_text())
        extract(backup / 'plugin.tar.gz', staging)
    manifest = json.loads((staging / 'plugin.json').read_text())
    if manifest.get('id') != PLUGIN:
        raise ValueError('Artifact is not Gbuds Widget')
    if args.artifact and (install / '.git').exists():
        git = install / '.git'
        if git.is_dir():
            shutil.copytree(git, staging / '.git', symlinks=True)
        else:
            shutil.copy2(git, staging / '.git')
    if install.exists():
        os.replace(install, previous)
    try:
        os.replace(staging, install)
    except Exception:
        if previous.exists():
            os.replace(previous, install)
        raise
    settings_before = read_settings()
    try:
        if args.restore:
            current = dict(settings_before)
            if snapshot['settings'] is None:
                current.pop(PLUGIN, None)
            else:
                current[PLUGIN] = snapshot['settings']
            settings.parent.mkdir(parents=True, exist_ok=True)
            temporary = settings.with_suffix('.gbuds-tmp')
            temporary.write_text(json.dumps(current, indent=2) + '\n')
            os.chmod(temporary, stat.S_IMODE(settings.stat().st_mode) if settings.exists() else 0o600)
            os.replace(temporary, settings)
        status = reload_plugin()
    except Exception:
        shutil.rmtree(install)
        if previous.exists():
            os.replace(previous, install)
        if args.restore:
            settings.write_text(json.dumps(settings_before, indent=2) + '\n')
        if not args.no_reload:
            reload_plugin()
        raise
    print(json.dumps({'version': manifest['version'], 'backup': str(backup), 'status': status, 'installPath': str(install)}))
finally:
    shutil.rmtree(staging, ignore_errors=True)
    if install.exists():
        shutil.rmtree(previous, ignore_errors=True)
