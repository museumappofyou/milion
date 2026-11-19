"""Usage: python3.11 tool/section/build_section.py [studio/section/<id>.yaml ...]

P14: builds a drawn excavation section (Milestone XVII, PU and SB) from its
spec into assets/section/<id>/section.json and lists it in
assets/section/index.json. The spec gives the strata (depths relative to
today's sea level), the finds, the ships, the story's beats and the reveal;
this script checks every reference and source against the registry and lays
the ships out: by date where one is known (older deeper, as the harbour
silted up), the rest in a seeded order. Their places are for legibility,
not where each was found; the manifest says so (`shipsPlaced`).
"""
import json
import random
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / 'studio/section'
ASSETS = ROOT / 'assets/section'


def registry_sources():
    index = json.loads((ROOT / 'assets/content/index.json').read_text())
    ids = set()
    for rel in index['files']['sources']:
        ids |= {r['id'] for r in json.loads((ROOT / rel).read_text())['records']}
    return ids


def value(entry):
    return entry['value'] if isinstance(entry, dict) and 'value' in entry else entry


ROWS = [-1.9, -2.7, -3.5, -4.3, -5.1, -5.8]


def row_for(ship):
    date = (ship.get('date') or {}).get('en', '')
    if '7th' in date:
        return 5
    if '8th' in date or 'early 9th' in date:
        return 4
    if '9th or 10th' in date:
        return 3
    if '10th' in date:
        return 1 if 'early' not in date else 2
    return None


def glyph_length(ship):
    if ship.get('type') == 'galley':
        return 0.17
    if ship.get('length'):
        return round(0.03 + ship['length'] * 0.0042, 4)
    return 0.07


def place_ships(ships, seed=37):
    rows = {i: [] for i in range(len(ROWS))}
    unknown = []
    for s in ships:
        r = row_for(s)
        (rows[r] if r is not None else unknown).append(s)
    rng = random.Random(seed)
    rng.shuffle(unknown)
    # Fill the rows to about the same width.
    for s in unknown:
        widths = {i: sum(glyph_length(x) + 0.05 for x in rows[i]) for i in rows}
        rows[min(widths, key=lambda i: (widths[i], i))].append(s)
    placed = []
    for i, row in rows.items():
        rng.shuffle(row)
        total = sum(glyph_length(x) for x in row)
        gap = (0.92 - total) / max(1, len(row))
        x = 0.04 + gap / 2
        for k, s in enumerate(row):
            length = glyph_length(s)
            jitter = (rng.random() - 0.5) * 0.18
            placed.append(dict(s, x=round(x + length / 2, 4), depth=round(ROWS[i] + jitter, 3),
                               glyph=length))
            x += length + gap
    return sorted(placed, key=lambda s: s['yk'])


def build(path):
    spec = yaml.safe_load(Path(path).read_text(encoding='utf-8'))
    known = registry_sources()
    refs = set(spec['sources']) | set(spec['shipSources'])
    for group in ['strata', 'finds', 'beats']:
        for item in spec[group]:
            refs |= set(item['sources'])
    missing = sorted(refs - known)
    if missing:
        raise SystemExit(f'{spec["id"]}: unknown sources {missing}')
    find_ids = {f['id'] for f in spec['finds']} | {'ships'}
    for beat in spec['beats']:
        for f in beat['lift']:
            if f not in find_ids:
                raise SystemExit(f'{beat["id"]}: lifts unknown find {f}')
    beat_ids = [b['id'] for b in spec['beats']]
    for s in spec['stills']:
        if s not in beat_ids:
            raise SystemExit(f'still {s}: no such beat')
    yks = [s['yk'] for s in spec['ships']]
    if yks != list(range(1, len(yks) + 1)):
        raise SystemExit('ships must be YK 1..n in order')
    top = value(spec['top'])
    strata = spec['strata']
    if strata[0]['from'] != top or strata[-1]['to'] != spec['bottom']:
        raise SystemExit('strata must run from top to bottom')
    for a, b in zip(strata, strata[1:]):
        if a['to'] != b['from']:
            raise SystemExit(f'{a["id"]} and {b["id"]} leave a gap')
    manifest = dict(
        schemaVersion=1, kind='section', id=spec['id'], placeId=spec['place'],
        milestoneId=spec['milestone'], honesty=spec['honesty'], top=top,
        bottom=spec['bottom'], topEstimated=bool(spec['top'].get('estimated')),
        title=spec['title'], description=spec['description'], talkback=spec['talkback'],
        sources=spec['sources'], strata=strata, finds=spec['finds'],
        ships=place_ships(spec['ships']), shipSources=spec['shipSources'], shipsPlaced=True,
        reveal=spec['reveal'], beats=spec['beats'], stills=spec['stills'],
    )
    out = ASSETS / spec['id']
    out.mkdir(parents=True, exist_ok=True)
    (out / 'section.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    return spec['id']


def main():
    specs = [Path(p) for p in sys.argv[1:]] or sorted(STUDIO.glob('*.yaml'))
    ids = [build(p) for p in specs]
    index = ASSETS / 'index.json'
    known = json.loads(index.read_text())['sections'] if index.exists() else []
    index.write_text(json.dumps(dict(schemaVersion=1, kind='sections',
                                     sections=sorted(set(known) | set(ids))), indent=1) + '\n')
    print('sections:', ids)


if __name__ == '__main__':
    main()
