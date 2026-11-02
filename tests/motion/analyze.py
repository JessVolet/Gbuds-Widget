import json
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw

folder = Path(sys.argv[1])
rows = []
for path in sorted(folder.glob('wave-*.png'), key=lambda p: int(p.stem.split('-')[1])):
    time = int(path.stem.split('-')[1])
    image = Image.open(path)
    bounds = image.getbbox()
    phase = time % 2900
    expected = 220 * phase / 1400 if 0 < phase < 1400 else 0
    if time in (0, 1900, 2899, 2900):
        assert bounds is None, (time, bounds)
    if expected >= 1:
        assert bounds, time
        assert abs((bounds[2] - bounds[0]) / 2 - expected) < 2, (time, bounds, expected)
    rows.append({'elapsedMs': time, 'bounds': bounds, 'expectedOuterRadiusPx': round(expected, 3)})
assert len(rows) == 13
(folder / 'renderer-samples.json').write_text(json.dumps(rows, indent=2))
frames = [0, 16, 249, 266, 500, 516, 1900, 2916]
sheet = Image.new('RGB', (1000, 560), '#161616')
draw = ImageDraw.Draw(sheet)
for i, frame in enumerate(frames):
    image = Image.open(folder / f'wave-{frame}.png')
    tile = Image.new('RGBA', image.size, '#161616')
    tile.alpha_composite(image)
    tile = tile.convert('RGB').resize((250, 250))
    x, y = (i % 4) * 250, (i // 4) * 280
    sheet.paste(tile, (x, y + 25))
    draw.text((x + 10, y + 8), f'{frame} ms', fill='white')
sheet.save(folder / 'wave-contact-sheet.png')
print('PASS 13 actual renderer samples; no visible ring at zero; first visible radius < 3 px.')
