#!/usr/bin/python3
import json
import runpy
import sys
from pathlib import Path
if 'find' in sys.argv and sys.argv[-1] == 'stop':
    print(json.dumps({'success': False, 'error': 'Simulated Stop failure'}), flush=True)
    sys.exit(1)
runpy.run_path(str(Path(__file__).with_name('fake-gbuds.py')), run_name='__main__')
