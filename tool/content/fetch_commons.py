"""Usage: python3.11 tool/content/fetch_commons.py [--derive-only] [--pin]

The chapters' photographs from Wikimedia Commons, as pinned in each
chapter's media.json (P12 studio/hagia-sophia/, P13 studio/imperial-core/).
For each record and reference:

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

3. A composite (P13): masters stacked top to bottom at a common width, then
   scaled so the long edge is 2,400 px, pinned by `masterSha256`; a plate
   names it with `source.cache` like any master.

`--pin` fills a new pin's missing hashes and sizes from what it fetches (the
author's step; a pinned file is never re-pinned). Network use is only step 1,
and only for missing masters. The User-Agent is a generic tool name.
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
CHAPTERS = [
    (ROOT / 'studio/hagia-sophia/media.json', ROOT / 'studio/cache/p12/commons/masters'),
    (ROOT / 'studio/imperial-core/media.json', ROOT / 'studio/cache/p13/commons/masters'),
]
UA = 'milion-dev-tool/0.1 (content build script)'
APP_EDGE = 1280
MASTER_EDGE = 2400


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def encode(image):
    buf = io.BytesIO()
    image.save(buf, 'JPEG', quality=92, subsampling=0, optimize=True)
    return buf.getvalue()


def edge(size, longest=MASTER_EDGE):
    """The size scaled down so its long edge is at most `longest`."""
    w, h = size
    k = min(1.0, longest / max(w, h))
    return [round(w * k), round(h * k)]


def fetch_master(pin, masters, pin_new=False):
    path = masters / f'{pin["key"]}.jpg'
    if path.exists():
        return path
    masters.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(pin['fetched'], headers={'User-Agent': UA})
    data = urllib.request.urlopen(request, timeout=120).read()
    if pin['fetchedSha256'] is None and pin_new:
        pin['fetchedSha256'] = sha256(data)
    if sha256(data) != pin['fetchedSha256']:
        raise SystemExit(f'{pin["key"]}: Commons served different bytes than pinned')
    image = Image.open(io.BytesIO(data)).convert('RGB')
    if pin['masterSize'] is None and pin_new:
        pin['masterSize'] = edge(image.size)
    if list(image.size) != list(pin['masterSize']):
        image = image.resize(tuple(pin['masterSize']), Image.Resampling.LANCZOS)
    path.write_bytes(encode(image))
    time.sleep(1.0)
    return path


def compose(c, masters):
    """Stack the masters top to bottom at the narrowest width, then fit the
    long edge to MASTER_EDGE."""
    images = [Image.open(masters / f'{k}.jpg').convert('RGB') for k in c['of']]
    width = min(i.width for i in images)
    images = [i if i.width == width else
              i.resize((width, round(i.height * width / i.width)), Image.Resampling.LANCZOS)
              for i in images]
    gutter = c.get('gutter', 0)
    sheet = Image.new('RGB', (width, sum(i.height for i in images) + gutter * (len(images) - 1)),
                      (238, 231, 219))
    y = 0
    for i in images:
        sheet.paste(i, (0, y))
        y += i.height + gutter
    size = edge(sheet.size)
    if list(sheet.size) != size:
        sheet = sheet.resize(tuple(size), Image.Resampling.LANCZOS)
    data = encode(sheet)
    (masters / f'{c["key"]}.jpg').write_bytes(data)
    return data, size


def derive(record, master):
    target = ROOT / record['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(master).convert('RGB')
    image.thumbnail((APP_EDGE, APP_EDGE), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    image.save(buf, 'JPEG', quality=82, optimize=True, progressive=False)
    target.write_bytes(buf.getvalue())
    return len(buf.getvalue())


def chapter(media, masters, derive_only=False, pin_new=False):
    if derive_only and not masters.exists():
        print(f'{media.parent.name}: no masters in {masters.relative_to(ROOT)}; app copies kept')
        return
    doc = json.loads(media.read_text(encoding='utf-8'))
    pins = [r['commons'] for r in doc['records']] + doc.get('references', [])
    stale, pinned = [], False
    for pin in pins:
        path = masters / f'{pin["key"]}.jpg'
        if not derive_only:
            new = pin['masterSha256'] is None
            path = fetch_master(pin, masters, pin_new)
            if new and pin_new:
                pin['masterSha256'], pinned = sha256(path.read_bytes()), True
        if path.exists() and sha256(path.read_bytes()) != pin['masterSha256']:
            stale.append(pin['key'])
    for c in doc.get('composites', []):
        if all((masters / f'{k}.jpg').exists() for k in c['of']):
            data, size = compose(c, masters)
            if c['masterSha256'] is None and pin_new:
                c['masterSha256'], c['masterSize'], pinned = sha256(data), size, True
            if sha256(data) != c['masterSha256']:
                stale.append(c['key'])
    if pinned:
        media.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if stale:
        raise SystemExit(f'masters differ from the pins: {stale}; re-pin {media.name} and the plates')
    total = 0
    for record in doc['records']:
        if record['path'].startswith('assets/media/'):
            total += derive(record, masters / f'{record["commons"]["key"]}.jpg')
    print(f'{media.parent.name}: {len(pins)} masters checked; app derivatives {total / 1e6:.2f} MB')


def main(derive_only=False, pin_new=False):
    for media, masters in CHAPTERS:
        if media.exists():
            chapter(media, masters, derive_only, pin_new)


if __name__ == '__main__':
    main('--derive-only' in sys.argv, '--pin' in sys.argv)
