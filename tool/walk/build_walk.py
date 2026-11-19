"""Usage: python3.11 tool/walk/build_walk.py [studio/walk/<id>.yaml ...]

P14: builds an immersive walk (WK) from its spec into assets/walk/<id>/:

  model.glb     the prototype meshes (columns by capital, a vault bay, wall
                segments, a pilaster, the carved bases and their photograph
                faces, the deck and stair, the water, a fish), y-up, with the
                light baked into the vertex colours
  walk.json     the manifest: the grid the app instances the prototypes on
                (and mirrors in the water), the capitals' order, the special
                columns, the deck's route, the stops, callouts, reveal and
                story (from the spec's `text`), lighting and fog, the
                ambient placeholders for P22, sources and the model's hash
  *.png         procedural textures (the weeping column's pattern, the
                water's ripple), drawn here, not photographed

and lists every walk in assets/walk/index.json. Deterministic: the same spec
gives the same bytes.
"""
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import numpy as np
import yaml
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import geometry as g  # noqa: E402
from glb import write_glb  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / 'studio/walk'
ASSETS = ROOT / 'assets/walk'


def value(entry):
    return entry['value'] if isinstance(entry, dict) and 'value' in entry else entry


def grid_values(spec):
    grid = {k: value(v) for k, v in spec['grid'].items()}
    grid['pitch'] = (grid['length'] / (grid['along'] + 1), grid['width'] / (grid['across'] + 1))
    return grid


def capitals(spec, count):
    mix = spec['capitals']['mix']
    rng = random.Random(spec['capitals']['seed'])
    kinds = []
    for kind, n in sorted(mix.items()):
        kinds += [kind] * n
    while len(kinds) < count:
        kinds.append('P')
    kinds = kinds[:count]
    rng.shuffle(kinds)
    turns = [rng.randrange(4) for _ in range(count)]
    return ''.join(kinds), ''.join(str(t) for t in turns)


def weeping_texture(path):
    """The weeping column's shaft pattern, unrolled (u around, v up): rows of
    raised 'hen's eyes' (ovals with a dark rim and a bright centre) between
    slanting branch lines, drawn after photographs, not traced."""
    w, h = 256, 512
    img = Image.new('RGB', (w, h), (170, 168, 160))
    d = ImageDraw.Draw(img)
    rng = random.Random(7)
    for y in range(0, h, 4):
        shade = 160 + rng.randrange(-8, 9)
        d.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 9), width=4)
    for row in range(-1, 15):
        y0 = row * 38
        for col in range(9):
            x0 = col * 32 + (16 if row % 2 else 0)
            # A branch slanting up to the right under each eye.
            d.line([(x0 - 14, y0 + 30), (x0 + 6, y0 + 8)], fill=(118, 116, 110), width=3)
            d.ellipse([x0 - 9, y0 - 13, x0 + 9, y0 + 13], fill=(196, 193, 184), outline=(92, 90, 86), width=3)
            d.ellipse([x0 - 4, y0 - 6, x0 + 4, y0 + 6], fill=(120, 118, 112))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    img.save(path, optimize=True)


def ripple_texture(path):
    """Faint caustic lines with alpha, tiled and scrolled over the water."""
    w = h = 256
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(11)
    for _ in range(70):
        x, y = rng.randrange(w), rng.randrange(h)
        rx, ry = rng.randrange(10, 34), rng.randrange(4, 12)
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                d.ellipse([x + dx - rx, y + dy - ry, x + dx + rx, y + dy + ry],
                          outline=(255, 214, 160, rng.randrange(40, 90)), width=1)
    img = img.filter(ImageFilter.GaussianBlur(0.7))
    img.save(path, optimize=True)


def build(spec_path):
    spec = yaml.safe_load(Path(spec_path).read_text(encoding='utf-8'))
    walk_id = spec['id']
    out = ASSETS / walk_id
    out.mkdir(parents=True, exist_ok=True)
    gv = grid_values(spec)
    lit = spec['lighting']
    mats = spec['materials']
    light = g.Light(tuple(lit['ambient']), tuple(lit['uplight']), lit['uplightHeight'],
                    lit['uplightOffset'], lit['reach'])
    px, pz = gv['pitch']

    prototypes = []
    for kind in ['C', 'P', 'W', 'S']:
        albedo = mats['marble']
        prototypes.append((f'column-{kind}', g.column(kind, gv, light, albedo, mats['capital'])))
    prototypes.append(('bay', g.bay(gv, light, mats['brick'], mats['arch'])))
    prototypes.append(('wall-long', g.wall_segment(gv, light, mats['plaster'], px, pz)))
    prototypes.append(('wall-short', g.wall_segment(gv, light, mats['plaster'], pz, px)))
    prototypes.append(('pilaster', g.pilaster(gv, light, mats['plaster'])))
    base_size = (1.05, gv['baseHeight'], 1.05)
    for special in ['medusa-sideways', 'medusa-inverted']:
        block, face = g.carved_base(gv, light, mats['stone'], 'z', base_size)
        prototypes.append((special, block))
        prototypes.append((f'{special}-face', face))
    route = [(a * px, c * pz) for a, c in spec['route']]
    deck = g.walkway(route, gv, tuple(mats['deck']), tuple(mats['rail']), tuple(mats['strip']))
    st = spec['stair']
    sx, sz = st['from'][0] * px, st['from'][1] * pz
    deck.extend(g.stair(sx + st['direction'] * gv['deckWidth'] / 2, sz, st['direction'], gv,
                        st['steps'], st['rise'], st['run'], st['width'], tuple(mats['stone'])))
    prototypes.append(('deck', deck))
    prototypes.append(('water', g.plane(0, gv['length'], 0, gv['width'], gv['waterLevel'],
                                        (1, 1, 1), uv_scale=(gv['length'] / 6, gv['width'] / 6))))
    prototypes.append(('fish', g.fish(0.42, (0.62, 0.42, 0.3), (0.78, 0.7, 0.6))))

    turned = {name: m.orient() for name, m in prototypes}
    model = out / 'model.glb'
    write_glb(model, prototypes)
    weeping_texture(out / 'weeping.png')
    ripple_texture(out / 'ripple.png')

    count = gv['along'] * gv['across']
    caps, turns = capitals(spec, count)
    triangles = {name: m.triangles for name, m in prototypes}
    manifest = dict(
        schemaVersion=1,
        kind='walk',
        id=walk_id,
        placeId=spec['place'],
        milestoneId=spec['milestone'],
        honesty=spec['honesty'],
        model=f'assets/walk/{walk_id}/model.glb',
        modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),
        textures=dict(weeping=f'assets/walk/{walk_id}/weeping.png',
                      ripple=f'assets/walk/{walk_id}/ripple.png'),
        grid=dict(length=gv['length'], width=gv['width'], along=gv['along'], across=gv['across'],
                  pitch=[round(px, 4), round(pz, 4)], columnHeight=gv['columnHeight'],
                  springing=round(gv['columnHeight'] + gv['impostHeight'], 4),
                  vaultRise=gv['vaultRise'], waterLevel=gv['waterLevel'], deckHeight=gv['deckHeight'],
                  eyeHeight=gv['eyeHeight']),
        capitals=caps,
        turns=turns,
        specials=spec['specials'],
        route=[[round(x, 3), round(z, 3)] for x, z in route],
        lighting=dict(fog=lit['fog'], water=lit['water']),
        prototypes=triangles,
        estimated=sorted(k for k, v in spec['grid'].items() if isinstance(v, dict) and v.get('estimated')),
    )
    text = dict(spec.get('text', {}))

    def metres(p):
        return [round(p[0] * px, 3), round(p[2], 3), round(p[1] * pz, 3)]

    def nearest_column(kind, hint):
        best = None
        for k in range(count):
            a, b = k // gv['across'] + 1, k % gv['across'] + 1
            if caps[k] != kind or any(tuple(s['column']) == (a, b) for s in spec['specials']):
                continue
            d = (a - hint[0]) ** 2 + (b - hint[1]) ** 2
            if best is None or d < best[0]:
                best = (d, a, b)
        _, a, b = best
        return [round(a * px, 3), round(gv['columnHeight'] - 0.35, 3), round(b * pz, 3)]

    if 'stops' in text:
        text['stops'] = [dict(s, eye=metres(s['eye']), look=metres(s['look'])) for s in text['stops']]
    if 'callouts' in text:
        out_callouts = []
        for c in text['callouts']:
            c = dict(c)
            if 'nearest' in c:
                c['anchor'] = nearest_column(c.pop('nearest'), c.pop('hint'))
            else:
                c['anchor'] = metres(c['anchor'])
            out_callouts.append(c)
        text['callouts'] = out_callouts
    for key in ['title', 'description', 'talkback', 'stops', 'callouts', 'reveal',
                'stills', 'start', 'ambient', 'fish', 'sources', 'photos']:
        if key in text:
            manifest[key] = text[key]
    (out / 'walk.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + '\n',
                                   encoding='utf-8')
    print('re-wound:', {k: v for k, v in turned.items() if v})
    return walk_id, triangles


def main():
    specs = [Path(p) for p in sys.argv[1:]] or sorted(STUDIO.glob('*.yaml'))
    ids = []
    for spec in specs:
        walk_id, triangles = build(spec)
        ids.append(walk_id)
        print(walk_id, sum(triangles.values()), 'prototype triangles', triangles)
    index = ASSETS / 'index.json'
    known = json.loads(index.read_text())['walks'] if index.exists() else []
    walks = sorted(set(known) | set(ids))
    index.write_text(json.dumps(dict(schemaVersion=1, kind='walks', walks=walks), indent=1) + '\n')


if __name__ == '__main__':
    main()
