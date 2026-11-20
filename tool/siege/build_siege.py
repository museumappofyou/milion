"""Usage: python3.11 tool/siege/build_siege.py [studio/siege/<id>.yaml ...]

P15: builds a map sequence (Milestone XIX, 1453 in 53 days; TM and SB) into
assets/siege/<id>/siege.json and lists it in assets/siege/index.json.

An event's shape is either written out ([[lat, lng], ...]) or taken from
what the app already draws, so the map agrees with the Atlas and the strip:
`{feature: <id>}` (assets/atlas/historic.json), `{place: <id>}` (the
registry's point), `{gate: <id>}` (a gate feature), or `{between: [a, b]}`
(a line from one of those to another). Dates become days (1 = the first
day). Every source and every account's source must be in the registry.
"""
import json
import sys
from datetime import date
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / 'studio/siege'
ASSETS = ROOT / 'assets/siege'
HISTORIC = ROOT / 'assets/atlas/historic.json'
KINDS = {'camp', 'gun', 'chain', 'fleet', 'overland', 'bridge', 'mine', 'tower',
         'assault', 'breach', 'fort', 'legend'}
SIDES = {'byzantine', 'venetian', 'genoese', 'ottoman', 'ottomanGreek', 'slavonic', 'modern'}
CERTAINTY = {'surviving', 'traced', 'approximate', 'conjectural'}


def registry():
    index = json.loads((ROOT / 'assets/content/index.json').read_text())
    sources, places = set(), {}
    for rel in index['files']['sources']:
        sources |= {r['id'] for r in json.loads((ROOT / rel).read_text())['records']}
    for rel in index['files']['places']:
        for p in json.loads((ROOT / rel).read_text())['records']:
            places[p['id']] = p
    return sources, places


def build(path):
    spec = yaml.safe_load(Path(path).read_text(encoding='utf-8'))
    known, places = registry()
    features = {f['id']: f for f in json.loads(HISTORIC.read_text())['features']}
    first = date.fromisoformat(spec['firstDay'])

    def day(value):
        if isinstance(value, int):
            return value
        return (date.fromisoformat(str(value)) - first).days + 1

    def points(ref):
        if isinstance(ref, list):
            return [[float(p[0]), float(p[1])] for p in ref]
        if 'feature' in ref or 'gate' in ref:
            f = features[ref.get('feature') or ref.get('gate')]
            c = f['coordinates']
            if f['type'] == 'Point':
                return [[c[1], c[0]]]
            return [[p[1], p[0]] for p in c]
        if 'place' in ref:
            loc = places[ref['place']]['coordinates']
            return [[loc['lat'], loc['lng']]]
        if 'between' in ref:
            a, b = (points(r) for r in ref['between'])
            return [a[-1], b[0]]
        raise SystemExit(f'cannot resolve shape {ref}')

    refs = set(spec['sources'])
    events = []
    for e in spec['events']:
        if e['kind'] not in KINDS:
            raise SystemExit(f'{e["id"]}: unknown kind {e["kind"]}')
        if e['certainty'] not in CERTAINTY:
            raise SystemExit(f'{e["id"]}: unknown certainty {e["certainty"]}')
        if not e['accounts']:
            raise SystemExit(f'{e["id"]}: every event is attributed')
        for a in e['accounts']:
            if a['side'] not in SIDES:
                raise SystemExit(f'{e["id"]}: unknown side {a["side"]}')
            refs |= set(a['sources'])
        refs |= set(e['sources'])
        entry = {k: v for k, v in e.items() if k not in ('shape', 'day', 'until')}
        entry['shape'] = [[round(p[0], 6), round(p[1], 6)] for p in points(e['shape'])]
        entry['day'] = day(e['day'])
        if e.get('until') is not None:
            entry['until'] = day(e['until'])
        if not 1 <= entry['day'] <= spec['days']:
            raise SystemExit(f'{e["id"]}: day {entry["day"]} outside 1..{spec["days"]}')
        events.append(entry)
    ids = {e['id'] for e in events}
    beats = []
    for b in spec['beats']:
        for f in b['focus']:
            if f not in ids:
                raise SystemExit(f'{b["id"]}: names unknown event {f}')
        refs |= set(b['sources'])
        beats.append(dict(b, day=day(b['day'])))
    if spec['reveal']['event'] not in ids:
        raise SystemExit('the reveal names an unknown event')
    for s in spec['stills']:
        if s not in {b['id'] for b in beats}:
            raise SystemExit(f'still {s}: no such beat')
    missing = sorted(refs - known)
    if missing:
        raise SystemExit(f'{spec["id"]}: unknown sources {missing}')
    span = (date.fromisoformat(spec['lastDay']) - first).days + 1
    if span != spec['days']:
        raise SystemExit(f'{spec["firstDay"]}..{spec["lastDay"]} is {span} days, not {spec["days"]}')

    manifest = dict(
        schemaVersion=1, kind='siege', id=spec['id'], placeId=spec['place'],
        milestoneId=spec['milestone'], honesty=spec['honesty'], title=spec['title'],
        description=spec['description'], talkback=spec['talkback'], sources=spec['sources'],
        firstDay=spec['firstDay'], days=spec['days'], frame=spec['frame'], home=spec['home'],
        labels=spec['labels'],
        events=sorted(events, key=lambda e: (e['day'], e['id'])),
        reveal=spec['reveal'], beats=beats, stills=spec['stills'],
    )
    out = ASSETS / spec['id']
    out.mkdir(parents=True, exist_ok=True)
    (out / 'siege.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    print(f'{spec["id"]}: {len(events)} events, {len(beats)} beats, {spec["days"]} days')
    return spec['id']


def main():
    specs = [Path(p) for p in sys.argv[1:]] or sorted(STUDIO.glob('*.yaml'))
    ids = [build(p) for p in specs]
    index = ASSETS / 'index.json'
    known = json.loads(index.read_text())['maps'] if index.exists() else []
    index.write_text(json.dumps(dict(schemaVersion=1, kind='sieges',
                                     maps=sorted(set(known) | set(ids))), indent=1) + '\n')


if __name__ == '__main__':
    main()
