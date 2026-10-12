"""Load and check a plate.yaml.

Input: `studio/plates/<id>/plate.yaml` (schema below). Output: a `Spec` with
resolved absolute paths. Unknown keys are errors, like the Dart manifest.

    id, milestone, artwork, title{en,tr}, description{en,tr}, manualMinutes
    source: {corpus: <path under $MILION_CAPTURES> | repo: <repo path>,
             sha256, url|null, credit{en,tr}}
    segments: [{id, box[l,t,r,b], points[[x,y]], prior, weight, mask?}]
    depth: {model, modelWeight, provided?, measure?[models]}
    gold: {heuristic, hand?, provided?}
    layers: {depth?, reconstruction?{asset, mask}}
    flow?: {mask, period, distance}     spiral?: {mask, center: auto|[x,y]}
    rig?: {path, maxVertices}
    lookUp?: {center, rimCenter, rimRadii, rimElevation, rimNote}
    popup?: [{id, segment, lift}]       mesh: {maxVertices}
    beats: [{detail, duration, light, window?, caption?, sources?, flow?,
             spiral?, gesture?}]
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
        return corpus_root() / 'chora-scenes' / s['corpus'] if 'corpus' in s else ROOT / s['repo']

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
    for b in data['beats'] + [data['reveal']]:
        if b.get('light', 'none') not in LIGHTS:
            fail(path, f'{b["detail"]}: light must be one of {sorted(LIGHTS)}')
    return Spec(path, data)
