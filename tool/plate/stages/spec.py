"""Load and check a plate.yaml.

Input: `studio/plates/<id>/plate.yaml` (schema below). Output: a `Spec` with
resolved absolute paths. Unknown keys are errors, like the Dart manifest.

    id, milestone, artwork, title{en,tr}, description{en,tr}, manualMinutes
    source: {corpus: <path under $MILION_CAPTURES> | repo: <repo path> |
             cache: <path under studio/cache, fetched by a recorded script>,
             sha256, url|null, credit{en,tr}}
    segments: [{id, box[l,t,r,b], points[[x,y]], prior, weight, mask?}]
    depth: {model, modelWeight, provided?, measure?[models]}
    gold: {heuristic, hand?, provided?}
    layers: {depth?, reconstruction?{asset, mask, recipe?}, imagined?{asset, mask, recipe?}}
    flow?: {mask, period, distance, motion? (scroll|sway), from?[{segment,
            direction[dx,dy]}], feather?}   spiral?: {mask, center: auto|[x,y]}
    rig?: {path, maxVertices}
    lookUp?: {center, rimCenter, rimRadii, rimElevation, rimNote}
    popup?: [{id, segment, lift}]       mesh: {maxVertices}
    beats: [{detail, duration, light, window?, caption?, sources?, flow?,
             spiral?, gesture?, layer? (reconstruction|imagined: wiped in)}]
    reveal: {detail, light, flow?, spiral?, window?, caption?, sources?, moment}
    sources: [ids]
"""
import os
from dataclasses import dataclass, field
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[3]
KEYS = {'id', 'milestone', 'artwork', 'title', 'description', 'manualMinutes',
        'source', 'segments', 'depth', 'gold', 'layers', 'flow', 'spiral', 'rig',
        'lookUp', 'popup', 'mesh', 'beats', 'reveal', 'sources'}
PRIORS = {'none', 'planar', 'bulge'}
LIGHTS = {'none', 'gilded', 'raking', 'candle'}
MOTIONS = {'scroll', 'sway'}   # P13: sway moves pixels back and forth (the animals)


def corpus_root():
    """`MILION_CAPTURES` (default: ../chora-ar/captures next to the repo)."""
    return Path(os.environ.get('MILION_CAPTURES', ROOT.parent / 'chora-ar/captures'))


@dataclass
class Spec:
    path: Path
    data: dict
    out: Path = field(init=False)
    build: Path = field(init=False)

    def __post_init__(self):
        self.out = ROOT / 'assets/plates' / self.id
        self.build = self.path.parent / 'build'

    def __getattr__(self, key):
        try:
            return self.data[key]
        except KeyError as e:
            raise AttributeError(key) from e

    def get(self, key, default=None):
        return self.data.get(key, default)

    def local(self, rel):
        """A manual input next to the yaml (masks/…), or a repo path."""
        p = self.path.parent / rel
        return p if p.exists() else ROOT / rel

    @property
    def source_path(self):
        s = self.source
        if 'corpus' in s:
            return corpus_root() / 'chora-scenes' / s['corpus']
        if 'cache' in s:   # P12: a fetched photograph (tool/content/fetch_commons.py)
            return ROOT / 'studio/cache' / s['cache']
        return ROOT / s['repo']

    def asset(self, name):
        return f'assets/plates/{self.id}/{name}'


def fail(spec_path, message):
    raise SystemExit(f'{spec_path}: {message}')


def load(path):
    path = Path(path).resolve()
    data = yaml.safe_load(path.read_text())
    unknown = set(data) - KEYS
    if unknown:
        fail(path, f'unknown keys {sorted(unknown)}')
    for key in ['id', 'milestone', 'artwork', 'title', 'description', 'source',
                'beats', 'reveal', 'sources', 'manualMinutes']:
        if key not in data:
            fail(path, f'missing {key}')
    if data['id'] != path.parent.name:
        fail(path, 'id must match the folder name')
    for text in ['title', 'description']:
        if not all(data[text].get(k, '').strip() for k in ['en', 'tr']):
            fail(path, f'{text} needs en and tr')
    if not data['source'].get('sha256'):
        fail(path, 'the source hash must be pinned')
    for s in data.get('segments', []):
        if s.get('prior', 'none') not in PRIORS:
            fail(path, f'segment {s["id"]}: prior must be one of {sorted(PRIORS)}')
    flow = data.get('flow')
    if flow:
        unknown = set(flow) - {'mask', 'period', 'distance', 'motion', 'from', 'feather'}
        if unknown:
            fail(path, f'flow: unknown keys {sorted(unknown)}')
        if flow.get('motion', 'scroll') not in MOTIONS:
            fail(path, f'flow motion must be one of {sorted(MOTIONS)}')
        names = {s['id'] for s in data.get('segments', [])}
        for f in flow.get('from', []):
            if f['segment'] not in names:
                fail(path, f'flow.from: no segment {f["segment"]}')
    for b in data['beats'] + [data['reveal']]:
        if b.get('light', 'none') not in LIGHTS:
            fail(path, f'{b["detail"]}: light must be one of {sorted(LIGHTS)}')
        if b.get('layer') and b['layer'] not in data.get('layers', {}):
            fail(path, f'{b["detail"]}: the plate has no {b["layer"]} layer')
    return Spec(path, data)
