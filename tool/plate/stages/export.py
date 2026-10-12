"""Stage (f) outputs.

Input: the spec, the ingest/segment/depth/mesh records and arrays, and the
registry's details and sources for the plate's Milestone. Output:
  assets/plates/<id>/original.jpg  the clean master (unless kept in place)
  assets/plates/<id>/surface.webp  RGB = normal (0..1), A = height (lossless)
  assets/plates/<id>/gold.webp     R = gilded coverage (lossless)
  assets/plates/<id>/manifest.json the schema-2 PlateManifest
  studio/plates/<id>/build/mesh.bin + report.json (validation report)
and updates the Milestone record (manifestPath, prototype status, the
honesty labels the plate can show), preserving every other field and record.
The 6-second preview MP4 is rendered by build.py through a headless Flutter
test, because only the real player draws the plate truthfully.
WebP is the texture format: Flutter decodes it natively on Android; KTX2
needs a GPU-texture path the engine does not expose to Dart.
"""
import hashlib
import io
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from .spec import ROOT

TEXTURE_BUDGET = 150_000_000


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def webp(path, array):
    """Lossless, deterministic WebP; returns its SHA-256."""
    buf = io.BytesIO()
    Image.fromarray(array).save(buf, 'WEBP', lossless=True, quality=100, method=6, exact=True)
    data = buf.getvalue()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return hashlib.sha256(data).hexdigest()


def surface_rgba(height, normals):
    rgb = np.clip((normals + 1) / 2 * 255 + .5, 0, 255).astype(np.uint8)
    return np.dstack([rgb, np.clip(height * 255 + .5, 0, 255).astype(np.uint8)])


def gray_rgb(mask):
    m = np.clip(mask * 255 + .5, 0, 255).astype(np.uint8)
    return np.dstack([m, m, m])


def mask_centroid(path):
    m = cv2.imread(str(ROOT / path), cv2.IMREAD_UNCHANGED)
    r = m[..., 2] if m.ndim == 3 else m
    ys, xs = np.nonzero(r > 127)
    return [round(float(xs.mean()) / r.shape[1], 3), round(float(ys.mean()) / r.shape[0], 3)]


def lookup_overlay(master, lookup, path):
    """The authored crown and rim drawn on the master, to check them by eye."""
    h, w = master.shape[:2]
    out = cv2.cvtColor(master, cv2.COLOR_RGB2BGR)
    c, rc, rr = lookup['center'], lookup['rimCenter'], lookup['rimRadii']
    cv2.ellipse(out, (round(rc[0] * w), round(rc[1] * h)), (round(rr[0] * w), round(rr[1] * w)),
                0, 0, 360, (255, 255, 0), 2, cv2.LINE_AA)
    cv2.drawMarker(out, (round(c[0] * w), round(c[1] * h)), (0, 255, 255), cv2.MARKER_CROSS, 40, 2)
    path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(path), out, [cv2.IMWRITE_JPEG_QUALITY, 85])


def registry_records(kind):
    out = {}
    for path in sorted((ROOT / 'assets/content').rglob('*.json')):
        doc = json.loads(path.read_text())
        if doc.get('kind') == kind:
            out.update({r['id']: r for r in doc['records']})
    return out


def _beat(spec, b, i, cursor, details):
    d = details[b['detail']]
    g = b.get('gesture')
    return dict(
        id=f'{spec.id}-beat-{i}', start=cursor, duration=b['duration'], detail=b['detail'],
        window=_rect(b['window']) if b.get('window') else d['window'],
        caption=b.get('caption') or d['sentence'], sources=b.get('sources') or d['sources'],
        light=b.get('light', 'none'), flow=bool(b.get('flow')), spiral=bool(b.get('spiral')),
        gesture=None if g is None else dict(
            start=cursor + g['offset'], duration=g['duration'], strength=g['strength'],
            windows=[_rect(w) for w in g['windows']]))


def _rect(v):
    return dict(left=v[0], top=v[1], right=v[2], bottom=v[3])


def manifest(spec, master_path, maps, lookup):
    details = {k: v for k, v in registry_records('details').items() if v['milestone'] == spec.milestone}
    if not details:
        raise SystemExit(f'{spec.milestone}: no registry details; add them to build_details.py')
    beats, cursor = [], 0
    for i, b in enumerate(spec.beats, 1):
        beats.append(_beat(spec, b, i, cursor, details))
        cursor += b['duration']
    r = spec.reveal
    reveal = _beat(spec, dict(r, duration=10), 0, 0, details)
    reveal['id'] = f'{spec.id}-reveal'
    layers = [dict(id='original', asset=master_path, honesty='ORIGINAL', mask=None)]
    extra = spec.get('layers', {})
    if extra.get('depth'):
        layers.append(dict(id='depth', asset=extra['depth'], honesty='DEPTH', mask=None))
    if extra.get('reconstruction'):
        rec = extra['reconstruction']
        layers.append(dict(id='reconstruction', asset=rec['asset'], honesty='RECONSTRUCTION',
                           mask=rec['mask']))
    flow = spec.get('flow')
    spiral = spec.get('spiral')
    if spiral:
        center = spiral['center']
        spiral = dict(mask=spiral['mask'],
                      center=mask_centroid(spiral['mask']) if center == 'auto' else center)
    m = dict(schemaVersion=2, kind='plate', id='plate-' + spec.id, milestone=spec.milestone,
             artwork=spec.artwork, title=spec.title, description=spec.description,
             size=maps['size'], manifestPath=spec.asset('manifest.json'), layers=layers,
             maps=dict(surface=maps['surface'], gold=maps['gold']),
             flow=None if not flow else dict(mask=flow['mask'], period=flow['period'],
                                              distance=flow['distance']),
             spiral=spiral, rig=spec.get('rig'), lookUp=lookup,
             details=list(details.values()), beats=beats, revealSeconds=10,
             revealMoment=r['moment'], storySeconds=cursor, reveal=reveal,
             credit=spec.source['credit'], sources=spec.sources,
             originalSourceUrl=spec.source.get('url'))
    refs = set(m['sources'])
    for x in m['details'] + beats + [reveal]:
        refs.update(x['sources'])
    sources = registry_records('sources')
    missing = sorted(refs - set(sources))
    if missing:
        raise SystemExit(f'{spec.id}: unknown sources {missing}')
    m['citations'] = [sources[i] for i in sorted(refs)]
    return m


def honesty(m):
    labels = ['ORIGINAL', 'DEPTH']
    if any(l['id'] == 'reconstruction' for l in m['layers']):
        labels.append('RECONSTRUCTION')
    if m['rig'] or m['flow'] or m['spiral']:
        labels.append('IMAGINED')
    return labels


def update_milestone(m):
    """The plate owns its Milestone's manifest path, status and honesty set."""
    for path in sorted((ROOT / 'assets/content/milestones').glob('*.json')):
        doc = json.loads(path.read_text())
        for rec in doc['records']:
            if rec['id'] == m['milestone']:
                if m['artwork'] not in rec['artworks']:
                    raise SystemExit(f'{m["milestone"]}: plate artwork not in the record')
                rec['manifestPath'] = m['manifestPath']
                if rec['status'] == 'planned':
                    rec['status'] = 'prototype'
                rec['honesty'] = honesty(m)
                write_json(path, doc)
                return
    raise SystemExit(f'{m["milestone"]}: no Milestone record')


def texture_bytes(paths):
    total = 0
    for p in paths:
        with Image.open(ROOT / p) as im:
            total += im.size[0] * im.size[1] * 4
    return total
