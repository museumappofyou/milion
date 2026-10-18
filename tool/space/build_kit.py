"""P09 kit: build buildings from `studio/space/<id>.yaml`.

Usage:
  python3.11 tool/space/build_kit.py                 # every spec
  python3.11 tool/space/build_kit.py studio/space/sehzade-camii.yaml

For each spec (see `kit/spec.py`): generate the parts, check every cited
dimension against the geometry (within its tolerance, 5% by default) and the
axis against the cited footprint, bake ambient occlusion, then write
  assets/space/<id>/model.glb    meshopt-compressed, one node per part
  assets/space/<id>/study.json   the SpacePlayer manifest
  studio/space/<id>.report.json  parts, triangles, dimensions, axis check
and, for all specs together,
  assets/content/sources/kit.json  the kit's source records
  assets/space/index.json          every study the app ships
A failed check stops the build. The output depends only on the specs.
"""
from pathlib import Path
import argparse
import json
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from glb import write_compressed  # noqa: E402
from kit import spec as kit  # noqa: E402
from solid import bake_ao  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SPECS = ROOT / 'studio/space'
SOURCES = ROOT / 'assets/content/sources/kit.json'
INDEX = ROOT / 'assets/space/index.json'
P08 = ['how-a-dome-stands']
BUDGET = 20500          # lib/space/study.dart triangleBudget (§3, drawing style)
AXIS_TOLERANCE = 3.0    # degrees between the spec's axis and the footprint's


def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def registry_sources(exclude):
    index = json.loads((ROOT / 'assets/content/index.json').read_text(encoding='utf-8'))
    out = {}
    for rel in index['files']['sources']:
        if ROOT / rel == exclude:
            continue
        for r in json.loads((ROOT / rel).read_text(encoding='utf-8'))['records']:
            out[r['id']] = r
    return out


def axis_check(spec):
    o = spec['orientation']
    found, long_side, short_side = kit.footprint_axis(o['footprint'])
    axis = o['axis'] % 180
    off = min(abs(axis - found), 180 - abs(axis - found))
    if o.get('long', 'y') == 'x':        # the axis runs across the outline
        off = abs(90 - off)
    return {'axis': o['axis'], 'footprintAxis': round(found, 2), 'offDegrees': round(off, 2),
            'footprint': [round(long_side, 2), round(short_side, 2)], 'source': o['source']}


def build_one(spec, known):
    parts = kit.build(spec)
    names = [n for n, _, _ in parts]
    triangles = sum(len(s[1]) for _, s, _ in parts)
    problems = []
    if triangles > BUDGET:
        problems.append(f'{triangles} triangles over the {BUDGET} budget')
    if len(parts) > 256:
        problems.append(f'{len(parts)} parts over 256')
    dims = kit.check_dimensions(spec, parts)
    problems += [f'{i}: {got:.3f} against {want} (±{tol:.0%})' for i, got, want, tol, ok in dims
                 if not ok]
    axis = axis_check(spec)
    if axis['offDegrees'] > AXIS_TOLERANCE:
        problems.append(f"axis {axis['axis']}° is {axis['offDegrees']}° off the footprint")
    steps = []
    used = []
    for s in spec['steps']:
        picked = kit.expand(s['parts'], names)
        steps.append(dict(s, parts=picked))
        used += picked
    missing = sorted(set(names) - set(used))
    if missing:
        problems.append(f'parts in no step: {missing}')
    for e in spec['epochs']:
        inside = [p for s in steps if not s['epochs'] or e['year'] in s['epochs'] for p in s['parts']]
        twice = sorted({p for p in inside if inside.count(p) > 1})
        if twice:
            problems.append(f"{e['year']}: in two steps: {twice}")
    cited = {r['id'] for r in spec.get('sources', [])} | set(spec.get('shared', []))
    for s in spec['steps']:
        problems += [f"{s['id']}: unknown source {x}" for x in s['sources'] if x not in cited]
    problems += [f"{d['id']}: unknown source {d['source']}" for d in spec.get('dimensions', [])
                 if d['source'] not in cited]
    problems += [f'shared source {x} not in the registry' for x in spec.get('shared', [])
                 if x not in known]
    if problems:
        raise SystemExit(f"{spec['id']}:\n  " + '\n  '.join(problems))
    solids = [s for _, s, _ in parts]
    ao = bake_ao(solids, solids)
    built = [{'name': n, 'positions': s[0], 'faces': s[1], 'ao': a, 'extras': extras}
             for (n, s, extras), a in zip(parts, ao)]
    return built, steps, dims, axis, triangles


def manifest(spec, steps, triangles, citations):
    return {
        'schemaVersion': 1, 'kind': 'space', 'id': spec['id'],
        'title': spec['title'], 'description': spec['description'],
        'model': f"assets/space/{spec['id']}/model.glb",
        'honesty': spec.get('honesty', 'RECONSTRUCTION'),
        'place': spec['place'],
        'orientation': {'axis': spec['orientation']['axis'],
                        'source': spec['orientation']['source']},
        'epochs': spec['epochs'],
        'steps': [{'id': s['id'], 'parts': s['parts'], 'seconds': s['seconds'],
                   'epochs': s.get('epochs', []), 'sources': s['sources'], 'label': s['label'],
                   'caption': s['caption']} for s in steps],
        'reveal': spec['reveal'], 'choisy': spec['choisy'],
        'sources': sorted({d['source'] for d in spec.get('dimensions', [])}),
        'triangles': triangles,
        'citations': citations,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('specs', nargs='*')
    args = parser.parse_args()
    paths = [Path(p) for p in args.specs] or sorted(SPECS.glob('*.yaml'))
    every = sorted(SPECS.glob('*.yaml'))
    specs = [kit.load(p) for p in every]
    known = registry_sources(SOURCES)
    records = {}
    for spec in specs:                  # every spec's sources, so kit.json stays whole
        for r in spec.get('sources', []):
            r = dict(r, licence=r.get('licence'))
            if r['id'] in known:
                raise SystemExit(f"{spec['id']}: source {r['id']} is already in the registry; share it")
            if r['id'] in records and records[r['id']] != r:
                raise SystemExit(f"{spec['id']}: source {r['id']} differs between specs")
            records[r['id']] = r
    wanted = {p.resolve() for p in paths}
    for path, spec in zip(every, specs):
        if path.resolve() not in wanted:
            continue
        built, steps, dims, axis, triangles = build_one(spec, known)
        out = ROOT / 'assets/space' / spec['id']
        extras = {'milion': {'units': 'm', 'up': 'z', 'axis': 'y',
                             'axisAzimuth': spec['orientation']['axis'],
                             'note': 'P09 kit; a diagram on cited dimensions, not a survey'}}
        size = write_compressed(out / 'model.glb', built, extras)
        ids = {r['id'] for r in spec.get('sources', [])}
        citations = [records[i] for i in sorted(ids)] + \
            [known[i] for i in sorted(spec.get('shared', []))]
        dump(out / 'study.json', manifest(spec, steps, triangles, citations))
        dump(SPECS / f"{spec['id']}.report.json", {
            'id': spec['id'], 'parts': len(built), 'triangles': triangles,
            'vertices': int(sum(len(p['positions']) for p in built)), 'bytes': size,
            'axis': axis,
            'dimensions': [{'id': i, 'measured': round(g, 3), 'cited': w, 'tolerance': t,
                            'error': round((g - w) / w, 4)} for i, g, w, t, _ in dims],
            'byPart': {p['name']: len(p['faces']) for p in built},
        })
        print(f"{out.relative_to(ROOT)}/model.glb: {len(built)} parts, {triangles} triangles, "
              f"{size} bytes; {len(dims)} dimensions within tolerance; axis "
              f"{axis['offDegrees']}° off the footprint")
    dump(SOURCES, {'schemaVersion': 1, 'kind': 'sources',
                   'records': [records[k] for k in sorted(records)]})
    dump(INDEX, {'schemaVersion': 1, 'kind': 'spaces',
                 'studies': P08 + [s['id'] for s in specs]})
    index_path = ROOT / 'assets/content/index.json'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    rel = 'assets/content/sources/kit.json'
    if rel not in index['files']['sources']:
        index['files']['sources'].append(rel)
        dump(index_path, index)


if __name__ == '__main__':
    main()
