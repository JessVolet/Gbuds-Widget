import json
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as name:
    folder = Path(name)
    installed = folder / 'installed'
    installed.mkdir()
    (installed / 'plugin.json').write_text(json.dumps({'id': 'gbudsWatch', 'version': 'before'}))
    settings = folder / 'settings.json'
    settings.write_text(json.dumps({'gbudsWatch': {'value': 1}, 'otherPlugin': {'keep': True}}))
    package = folder / 'package'
    package.mkdir()
    (package / 'plugin.json').write_text(json.dumps({'id': 'gbudsWatch', 'version': 'candidate'}))
    artifact = folder / 'candidate.tar.gz'
    with tarfile.open(artifact, 'w:gz') as archive:
        archive.add(package / 'plugin.json', arcname='plugin.json')
    base = [sys.executable, str(root / 'scripts/deploy-local.py'), '--install-path', str(installed), '--settings', str(settings), '--no-reload']
    result = json.loads(subprocess.check_output(base + ['--artifact', str(artifact), '--backup-dir', str(folder / 'backups')]))
    assert json.loads((installed / 'plugin.json').read_text())['version'] == 'candidate'
    settings.write_text(json.dumps({'gbudsWatch': {'value': 2}, 'otherPlugin': {'keep': 'new'}}))
    subprocess.run(base + ['--restore', result['backup']], check=True, capture_output=True)
    assert json.loads((installed / 'plugin.json').read_text())['version'] == 'before'
    restored = json.loads(settings.read_text())
    assert restored['gbudsWatch']['value'] == 1
    assert restored['otherPlugin']['keep'] == 'new'
    print('PASS atomic install and rollback preserve unrelated plugin settings')
