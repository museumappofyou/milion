"""Usage: python3.11 tool/walls/build_strip.py [studio/walls/<id>.yaml ...]

P15: builds the land walls as one strip (Milestone XVIII, PU and SB) into
assets/walls/<id>/strip.json and lists it in assets/walls/index.json.

The line is the Atlas's own (assets/atlas/historic.json): the Theodosian
land walls drawn through the inner wall's towers as the Wikidata inventory
places them, from the Marble Tower on the Sea of Marmara, then the wall of
Manuel Komnenos to the Golden Horn. Chainage is metres along that line.
Inner towers are the inventory's (numbered, surveyed); the outer wall's
towers are set midway between them (not surveyed; the spec cites why).
The Komnenian wall's towers are not in the inventory and are not drawn.
Gates are projected onto the line from their Wikidata or place positions,
so a strip position, an Atlas position and a GPS fix agree.
"""
import json
import math
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tool/atlas'))
import build_historic  # noqa: E402  (the Wikidata wall inventory loader)

STUDIO = ROOT / 'studio/walls'
ASSETS = ROOT / 'assets/walls'
HISTORIC = ROOT / 'assets/atlas/historic.json'


def registry_sources():
    index = json.loads((ROOT / 'assets/content/index.json').read_text())
    ids = set()
    for rel in index['files']['sources']:
        ids |= {r['id'] for r in json.loads((ROOT / rel).read_text())['records']}
    return ids


def registry_places():
    index = json.loads((ROOT / 'assets/content/index.json').read_text())
    out = {}
    for rel in index['files']['places']:
        for p in json.loads((ROOT / rel).read_text())['records']:
            out[p['id']] = p
    return out


def metres(a, b):
    """Local equirectangular distance between (lat, lng) points; the same
    measure lib/walls/wall_strip.dart uses to locate a GPS fix."""
    k = math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot((b[1] - a[1]) * k * 111320, (b[0] - a[0]) * 110574)


def project(line, p):
    """Chainage of the point of `line` nearest p, and the distance to it."""
    k = math.cos(math.radians(p[0]))
    best = (0.0, float('inf'))
    for (a, ca), (b, cb) in zip(line, line[1:]):
        ax, ay = (a[1] - p[1]) * k * 111320, (a[0] - p[0]) * 110574
        bx, by = (b[1] - p[1]) * k * 111320, (b[0] - p[0]) * 110574
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, (-ax * dx - ay * dy) / L2))
        cx, cy = ax + dx * t, ay + dy * t
        off = math.hypot(cx, cy)
        if off < best[1]:
            best = (ca + (cb - ca) * t, off)
    return best


def build(path):
    spec = yaml.safe_load(Path(path).read_text(encoding='utf-8'))
    known = registry_sources()
    places = registry_places()
    features = {f['id']: f for f in json.loads(HISTORIC.read_text())['features']}

    # The line: Theodosian walls, then the Komnenian wall, as [lat, lng].
    pts = []
    for fid in spec['line']['features']:
        coords = [(c[1], c[0]) for c in features[fid]['coordinates']]
        if pts and metres(pts[-1], coords[0]) < 1:
            coords = coords[1:]
        pts += coords
    line, at = [], 0.0
    for i, p in enumerate(pts):
        if i:
            at += metres(pts[i - 1], p)
        line.append((p, at))
    length = at
    junction = project(line, pts[len(features[spec['line']['features'][0]]['coordinates']) - 1])[0]

    def anchor(value):
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str) and '+' in value:
            # 'junction+100': metres beyond an anchor.
            base, plus = value.split('+')
            return anchor(base.strip()) + float(plus)
        if value == 'start':
            return 0.0
        if value == 'end':
            return length
        if value == 'junction':
            return junction
        for g in gates:
            if g['id'] == value:
                return g['at']
        raise SystemExit(f'unknown anchor {value}')

    # Gates, projected onto the line. A gate without its own surveyed point
    # (the military gates) sits between the two inventory towers that the
    # literature names for it (`towers: [a, b]`).
    _, _, inventory = build_historic.load_wikidata()
    gates = []
    for g in spec['gates']:
        if 'feature' in g:
            lng, lat = features[g['feature']]['coordinates']
        elif 'towers' in g:
            pair = [inventory['land'][n][1] for n in g['towers']]
            lat = sum(q[0] for q in pair) / len(pair)
            lng = sum(q[1] for q in pair) / len(pair)
        elif 'place' in g:
            loc = places[g['place']]['coordinates']
            lat, lng = loc['lat'], loc['lng']
        else:
            lat, lng = g['position']
        ch, off = project(line, (lat, lng))
        if off > spec['line']['gateTolerance']:
            raise SystemExit(f'{g["id"]}: {off:.0f} m off the line')
        entry = {k: v for k, v in g.items()
                 if k not in ('feature', 'towers', 'place', 'position', 'opens')}
        entry.update(at=round(ch, 1), lat=round(lat, 7), lng=round(lng, 7))
        if g.get('opens'):
            entry['placeId'] = g['opens']
        gates.append(entry)
    gates.sort(key=lambda g: g['at'])

    # Towers: the inventory's inner towers; outer ones midway between them.
    inner = []
    for n, (_, p) in sorted(inventory['land'].items()):
        ch, off = project(line, p)
        inner.append(dict(at=round(ch, 1), wall='inner', number=n, surveyed=True))
    inner.sort(key=lambda t: t['at'])
    # The outer wall has its own gate in front of each gate of the inner one,
    # so no tower is set where a gate stands between two great towers.
    openings = [g['at'] for g in gates if g['kind'] in ('public', 'military')]
    outer = []
    for a, b in zip(inner, inner[1:]):
        mid = (a['at'] + b['at']) / 2
        if mid < junction and b['at'] - a['at'] < spec['outerTowers']['maxGap'] and all(
                abs(mid - o) > spec['outerTowers']['gateClearance'] for o in openings):
            outer.append(dict(at=round(mid, 1), wall='outer', surveyed=False))

    segments = [dict(s, **{'from': round(anchor(s['from']), 1), 'to': round(anchor(s['to']), 1)})
                for s in spec['segments']]
    beats = [dict(b, at=round(anchor(b['at']), 1)) for b in spec['beats']]

    refs = set(spec['sources']) | set(spec['lineSources']) | set(spec['outerTowers']['sources'])
    refs |= set(spec['innerTowerHeight']['sources']) | set(spec['outerTowerHeight']['sources'])
    for group in (spec['layers'], spec['segments'], spec['gates'], spec['beats']):
        for item in group:
            refs |= set(item['sources'])
    missing = sorted(refs - known)
    if missing:
        raise SystemExit(f'{spec["id"]}: unknown sources {missing}')
    for g in gates:
        if g.get('placeId') and g['placeId'] not in places:
            raise SystemExit(f'{g["id"]}: unknown place {g["placeId"]}')
    beat_ids = [b['id'] for b in beats]
    for s in spec['stills']:
        if s not in beat_ids:
            raise SystemExit(f'still {s}: no such beat')
    layers = spec['layers']
    for a, b in zip(layers, layers[1:]):
        if a['to'] != b['from']:
            raise SystemExit(f'{a["id"]} and {b["id"]} leave a gap')

    manifest = dict(
        schemaVersion=1, kind='strip', id=spec['id'], placeId=spec['place'],
        milestoneId=spec['milestone'], honesty=spec['honesty'],
        title=spec['title'], description=spec['description'], talkback=spec['talkback'],
        sources=spec['sources'], length=round(length, 1),
        heightScale=spec['heightScale'],
        line=[[round(p[0], 7), round(p[1], 7), round(c, 1)] for p, c in line],
        lineSources=spec['lineSources'],
        layers=layers, innerTowerHeight=spec['innerTowerHeight']['value'],
        outerTowerHeight=spec['outerTowerHeight']['value'],
        segments=segments, towers=inner + outer, gates=gates,
        reveal=spec['reveal'], beats=beats, stills=spec['stills'],
    )
    out = ASSETS / spec['id']
    out.mkdir(parents=True, exist_ok=True)
    (out / 'strip.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    print(f'{spec["id"]}: {length:.0f} m, junction at {junction:.0f} m, '
          f'{len(inner)} inner and {len(outer)} outer towers, {len(gates)} gates')
    return spec['id']


def main():
    specs = [Path(p) for p in sys.argv[1:]] or sorted(STUDIO.glob('*.yaml'))
    ids = [build(p) for p in specs]
    index = ASSETS / 'index.json'
    known = json.loads(index.read_text())['strips'] if index.exists() else []
    index.write_text(json.dumps(dict(schemaVersion=1, kind='strips',
                                     strips=sorted(set(known) | set(ids))), indent=1) + '\n')


if __name__ == '__main__':
    main()
