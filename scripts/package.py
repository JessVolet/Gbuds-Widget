#!/usr/bin/env python3
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description='Package a committed Gbuds Widget revision.')
parser.add_argument('revision')
parser.add_argument('output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
commit = subprocess.check_output(['git', 'rev-parse', '--verify', '--end-of-options', args.revision + '^{commit}'], cwd=root, text=True).strip()
paths = ['Daemon.qml', 'Desktop.qml', 'GbudsBarWidget.qml', 'Settings.qml', 'qmldir', 'plugin.json', 'src', 'assets', 'LICENSE', 'LICENSE-GPL-3.0', 'README.md']
artifact = subprocess.check_output(['git', 'archive', '--format=tar.gz', commit, *paths], cwd=root)
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_bytes(artifact)
manifest = json.loads(subprocess.check_output(['git', 'show', commit + ':plugin.json'], cwd=root))
record = {'commit': commit, 'version': manifest['version'], 'artifact': args.output.name, 'sha256': hashlib.sha256(artifact).hexdigest()}
args.output.with_suffix(args.output.suffix + '.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record))
