"""Usage: python3.11 tool/content/fetch_commons.py [--derive-only]

P12: the Hagia Sophia photographs from Wikimedia Commons, as pinned in
studio/hagia-sophia/media.json. For each record and reference:

1. The master: studio/cache/p12/commons/masters/<key>.jpg (gitignored, like
   the MILION_CAPTURES corpus). When it is missing, the pinned thumbnail URL
   is fetched (Commons serves fixed widths), its SHA-256 checked against
   `fetchedSha256`, and it is downscaled once to `masterSize` (Lanczos,
   quality 92, no chroma subsampling). The master's hash is then compared
   with `masterSha256`. A different Pillow can encode different bytes; the
   tool then stops and says which plate.yaml sha256 to re-pin.
2. The app derivative: a record whose path is under assets/media/ gets a
   1280 px (long edge), quality 82 JPEG without metadata. Records that point
   at a plate's original.jpg are written by the plate pipeline instead.

Network use is only step 1, and only for missing masters. The User-Agent
is a generic tool name.
"""
import hashlib
import io
import json
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MEDIA = ROOT / 'studio/hagia-sophia/media.json'
MASTERS = ROOT / 'studio/cache/p12/commons/masters'
UA = 'milion-dev-tool/0.1 (content build script)'
APP_EDGE = 1280


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def fetch_master(pin):
    path = MASTERS / f'{pin["key"]}.jpg'
    if path.exists():
        return path
    MASTERS.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(pin['fetched'], headers={'User-Agent': UA})
    data = urllib.request.urlopen(request, timeout=120).read()
    if sha256(data) != pin['fetchedSha256']:
        raise SystemExit(f'{pin["key"]}: Commons served different bytes than pinned')
    image = Image.open(io.BytesIO(data)).convert('RGB')
    if list(image.size) != list(pin['masterSize']):
        image = image.resize(tuple(pin['masterSize']), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    image.save(buf, 'JPEG', quality=92, subsampling=0, optimize=True)
    path.write_bytes(buf.getvalue())
    time.sleep(0.5)
    return path


def derive(record, master):
    target = ROOT / record['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(master).convert('RGB')
    image.thumbnail((APP_EDGE, APP_EDGE), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    image.save(buf, 'JPEG', quality=82, optimize=True, progressive=False)
    target.write_bytes(buf.getvalue())
    return len(buf.getvalue())


def main(derive_only=False):
    doc = json.loads(MEDIA.read_text(encoding='utf-8'))
    pins = [r['commons'] for r in doc['records']] + doc.get('references', [])
    stale = []
    for pin in pins:
        path = MASTERS / f'{pin["key"]}.jpg'
        if not derive_only:
            path = fetch_master(pin)
        if path.exists() and sha256(path.read_bytes()) != pin['masterSha256']:
            stale.append(pin['key'])
    if stale:
        raise SystemExit(f'masters differ from the pins: {stale}; re-pin media.json and the plates')
    total = 0
    for record in doc['records']:
        if record['path'].startswith('assets/media/'):
            total += derive(record, MASTERS / f'{record["commons"]["key"]}.jpg')
    print(f'{len(pins)} masters checked; app derivatives {total / 1e6:.2f} MB')


if __name__ == '__main__':
    main('--derive-only' in sys.argv)
