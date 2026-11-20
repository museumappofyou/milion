"""Usage: python3.11 tool/walk/build_walk.py [studio/walk/<id>.yaml ...]

P14: builds an immersive walk (WK) from its spec into assets/walk/<id>/:

  model.glb     the prototype meshes (spolia shafts & bases, capitals & imposts,
                groin-vault bay, 2022 seismic tie-rods, water-edge uplights,
                wall segments, pilaster, carved Medusa bases and photo faces,
                steel walkway, railings, stone stair, LED strips, dual water
                surfaces, fish), y-up, with light baked into vertex colours
  walk.json     the manifest: grid, capitals & spolia shafts order, special
                columns, deck route, stops, tappable callouts with photos and
                metrics, reveal & story, lighting & fog, ambient placeholders,
                sources and model sha256
  *.jpg / *.png real photo-derived seamless textures extracted deterministically
                from verified Wikimedia Commons photographs in
                assets/media/underground/, plus the 2022 steel grating and
                dual-layer animated water & caustic sheets.
"""
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import numpy as np
import yaml
from PIL import Image, ImageDraw, ImageFilter, ImageOps

sys.path.insert(0, str(Path(__file__).resolve().parent))
import geometry as g  # noqa: E402
from glb import write_glb  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / 'studio/walk'
ASSETS = ROOT / 'assets/walk'
MEDIA_UNDERGROUND = ROOT / 'assets/media/underground'


def value(entry):
    return entry['value'] if isinstance(entry, dict) and 'value' in entry else entry


def grid_values(spec):
    grid = {k: value(v) for k, v in spec['grid'].items()}
    grid['pitch'] = (grid['length'] / (grid['along'] + 1), grid['width'] / (grid['across'] + 1))
    return grid


def distribute(mix, seed, count, fallback):
    rng = random.Random(seed)
    kinds = []
    for kind, n in sorted(mix.items()):
        kinds += [kind] * n
    while len(kinds) < count:
        kinds.append(fallback)
    kinds = kinds[:count]
    rng.shuffle(kinds)
    return ''.join(kinds)


def capitals_and_shafts(spec, count):
    cap_spec = spec['capitals']
    caps = distribute(cap_spec['mix'], cap_spec['seed'], count, 'P')
    rng = random.Random(cap_spec['seed'] + 17)
    turns = ''.join(str(rng.randrange(4)) for _ in range(count))
    shaft_spec = spec.get('shafts', {'mix': {'M': count}, 'seed': cap_spec['seed'] + 101})
    shafts = distribute(shaft_spec['mix'], shaft_spec['seed'], count, 'M')
    return caps, turns, shafts


def _crop_frac(im, x0, y0, x1, y1):
    w, h = im.size
    return im.crop((int(w * x0), int(h * y0), int(w * x1), int(h * y1)))


def _seamless(img, size, mirror_x=True, mirror_y=False):
    w, h = size
    if mirror_x:
        half = img.resize((w // 2, h), Image.Resampling.LANCZOS)
        out = Image.new('RGB', (w, h))
        out.paste(half, (0, 0))
        out.paste(ImageOps.mirror(half), (w // 2, 0))
        img = out
    else:
        img = img.resize((w, h), Image.Resampling.LANCZOS)
    if mirror_y:
        half = img.resize((w, h // 2), Image.Resampling.LANCZOS)
        out = Image.new('RGB', (w, h))
        out.paste(half, (0, 0))
        out.paste(ImageOps.flip(half), (0, h // 2))
        img = out
    return img


def _tone_albedo(pil_img, target_mean=0.80, contrast=0.88, desat=0.65, blur_r=24, per_channel=True):
    """Flat-fields a real photo patch into a clean neutral-lit albedo texture
    with soft tanh highlight shoulder so baked uplighting never clips white."""
    a = np.asarray(pil_img.convert('RGB'), dtype=np.float64) / 255.0
    blur = np.asarray(pil_img.convert('RGB').filter(ImageFilter.GaussianBlur(radius=blur_r)),
                      dtype=np.float64) / 255.0
    denom = np.maximum(0.18, blur if per_channel else blur.mean(axis=2, keepdims=True))
    flat = a / denom
    flat = flat / np.maximum(1e-4, flat.mean())
    flat = 1.0 + np.tanh((flat - 1.0) * contrast) * 0.42
    gray = flat.mean(axis=2, keepdims=True)
    bal = flat * (1.0 - desat) + gray * desat
    out = bal * target_mean
    return Image.fromarray(np.clip(out * 255.0, 28, 240).astype(np.uint8))


def build_photo_textures(out):
    """Extracts 9 real photo-derived seamless material textures from the
    verified Wikimedia Commons photographs in assets/media/underground/."""
    im_walk = Image.open(MEDIA_UNDERGROUND / 'cistern-walkway.jpg').convert('RGB')
    im_caps = Image.open(MEDIA_UNDERGROUND / 'cistern-capitals.jpg').convert('RGB')
    im_weep = Image.open(MEDIA_UNDERGROUND / 'cistern-weeping-full.jpg').convert('RGB')
    im_band = Image.open(MEDIA_UNDERGROUND / 'cistern-banded.jpg').convert('RGB')

    # 1. Smooth Proconnesian marble shaft (DD 01-03 HDR foreground column)
    c_smooth = _crop_frac(im_walk, 0.128, 0.22, 0.168, 0.62)
    _tone_albedo(_seamless(c_smooth, (256, 512), True, False),
                 0.85, 0.85, 0.72, 24, True).save(out / 'marble_smooth.jpg', quality=88, optimize=True)

    # 2. Rough-hewn hammer-dressed quarry shaft (DD 37-39 HDR foreground left column)
    c_rough = _crop_frac(im_caps, 0.100, 0.14, 0.172, 0.56)
    _tone_albedo(_seamless(c_rough, (256, 512), True, False),
                 0.84, 1.05, 0.82, 18, True).save(out / 'marble_rough.jpg', quality=88, optimize=True)

    # 3. Spliced iron-banded spolia shaft (Kurmanbek 2022 foreground left column)
    c_band = _crop_frac(im_band, 0.226, 0.18, 0.282, 0.76)
    _tone_albedo(_seamless(c_band, (256, 512), True, False),
                 0.84, 1.05, 0.55, 24, True).save(out / 'marble_banded.jpg', quality=88, optimize=True)

    # 4. Warm weathered Roman travertine/marble shaft (DD 37-39 HDR right pedestal column,
    # desaturated cleanly so it reads as aged cream-ochre stone, not bright orange).
    c_warm = _crop_frac(im_caps, 0.84, 0.12, 0.92, 0.50)
    _tone_albedo(_seamless(c_warm, (256, 512), True, False),
                 0.82, 0.85, 0.76, 22, True).save(out / 'marble_warm.jpg', quality=88, optimize=True)

    # 5. Real Hen's-Eye / Peacock-Eyed carved relief (DD 46-48 HDR center shaft):
    # cross-fade wrapped seamlessly around 360° WITHOUT hard mirror symmetry down the front.
    c_weep = _crop_frac(im_weep, 0.42, 0.35, 0.61, 0.85)
    w_strip = np.asarray(_tone_albedo(c_weep.resize((148, 512), Image.Resampling.LANCZOS),
                                      0.80, 1.05, 0.74, 20, True), dtype=np.float64)
    # Smoothly cross-fade 20px overlap so two wraps tile seamlessly around 360°.
    ov = 20
    tile_w = 128
    alpha = np.linspace(0.0, 1.0, ov)[None, :, None]
    seam = w_strip[:, :ov] * alpha + w_strip[:, tile_w:tile_w + ov] * (1.0 - alpha)
    one_wrap = np.concatenate([seam, w_strip[:, ov:tile_w]], axis=1)
    t_weep = np.concatenate([one_wrap, one_wrap], axis=1)
    Image.fromarray(np.clip(t_weep, 28, 240).astype(np.uint8)).save(
        out / 'weeping.jpg', quality=88, optimize=True)

    # 6. Real carved Corinthian acanthus capital (DD 37-39 HDR carved foliage band)
    c_cor = _crop_frac(im_caps, 0.225, 0.268, 0.320, 0.308)
    _tone_albedo(_seamless(c_cor, (256, 256), True, False),
                 0.80, 0.95, 0.68, 16, True).save(out / 'capital_corinthian.jpg', quality=88, optimize=True)

    # 7. Real rough-chiseled unfinished cushion capital (DD 46-48 HDR top capital)
    c_plain = _crop_frac(im_weep, 0.41, 0.055, 0.67, 0.185)
    plain_img = _tone_albedo(_seamless(c_plain, (256, 256), True, False),
                             0.85, 0.98, 0.80, 18, True)
    plain_img.save(out / 'capital_plain.jpg', quality=88, optimize=True)

    # 8. Seamless straight Byzantine flat-brick courses (38-40 cm x 4 cm bricks
    # in Khorasan lime mortar) enriched with real photo grain from DD 37-39 HDR,
    # eliminating mirrored square kaleidoscope seams on the groin vaults!
    bw = bh = 256
    c_bgrain = _crop_frac(im_caps, 0.38, 0.02, 0.58, 0.10).resize((bw, bh), Image.Resampling.LANCZOS)
    photo_micro = (np.asarray(_tone_albedo(c_bgrain, 0.80, 0.75, 0.85, 14, True), dtype=np.float64) / 255.0 - 0.80)
    b_img = Image.new('RGB', (bw, bh), (176, 162, 148))  # Pale Khorasan lime-brick-dust mortar
    bd = ImageDraw.Draw(b_img)
    rng_b = random.Random(532)
    rows_b, cols_b = 18, 4
    rh = bh / rows_b
    cw = bw / cols_b
    for r in range(rows_b):
        off = (cw * 0.5) if (r % 2) else 0.0
        y0 = int(round(r * rh)) + 2
        y1 = int(round((r + 1) * rh)) - 1
        for c in range(-1, cols_b + 1):
            x0 = int(round(c * cw + off)) + 2
            x1 = int(round((c + 1) * cw + off)) - 2
            dv = rng_b.randrange(-18, 19)
            dt = rng_b.randrange(-8, 9)
            # Dusty muted Roman/Byzantine aged clay brick (earthy sienna, NOT bright orange)
            col = (max(80, min(230, 178 + dv)),
                   max(65, min(205, 128 + dv + dt)),
                   max(55, min(190, 108 + dv + dt)))
            bd.rectangle([x0, y0, x1, y1], fill=col)
    ba = np.asarray(b_img.filter(ImageFilter.GaussianBlur(0.45)), dtype=np.float64)
    ba = np.clip(ba + photo_micro * 95.0, 42, 232)
    Image.fromarray(ba.astype(np.uint8)).save(out / 'brick.jpg', quality=88, optimize=True)

    # 9. Damp hydraulic opus signinum cistern wall plaster (blending real stone grain)
    w = h = 256
    rng = np.random.default_rng(31)
    y, x = np.mgrid[0:h, 0:w].astype(np.float64)
    u, v = x / w, y / h
    stone_grain = (np.asarray(plain_img, dtype=np.float64) / 255.0).mean(axis=2) - 0.85
    streaks = (0.05 * np.sin(2 * math.pi * u * 7 + 0.5 * np.sin(2 * math.pi * v * 2))
               + 0.03 * np.cos(2 * math.pi * u * 13))
    courses = 0.025 * np.sin(2 * math.pi * v * 14)
    noise = rng.normal(0.0, 0.025, (h, w))
    base = np.clip(0.84 + stone_grain * 0.7 + streaks + courses + noise, 0.52, 0.98)
    rgb = np.stack([base * 236, base * 212, base * 194], axis=-1).astype(np.uint8)
    Image.fromarray(rgb, 'RGB').filter(ImageFilter.GaussianBlur(0.5)).save(
        out / 'plaster.jpg', quality=88, optimize=True)

    # 10. Carved Roman limestone for Medusa base sides & dressed entrance stair
    m_base = np.clip(0.86 + stone_grain * 0.85 + 0.04 * np.sin(2 * math.pi * (u * 2 + v * 3)),
                     0.55, 0.98)
    m_rgb = np.stack([m_base * 238, m_base * 224, m_base * 200], axis=-1).astype(np.uint8)
    Image.fromarray(m_rgb, 'RGB').filter(ImageFilter.GaussianBlur(0.4)).save(
        out / 'medusa_stone.jpg', quality=88, optimize=True)


def deck_grating_texture(path):
    """Modular dark industrial steel-grating walkway matching the 2022
    restoration platform photographed in DD 01-03 HDR."""
    w = h = 256
    img = Image.new('RGB', (w, h), (78, 76, 74))
    d = ImageDraw.Draw(img)
    for y in range(0, h, 8):
        d.line([(0, y), (w, y)], fill=(128, 126, 122), width=2)
    for x in range(0, w, 16):
        d.line([(x, 0), (x, h)], fill=(116, 114, 110), width=2)
    for pos in (0, 128):
        d.rectangle([0, pos, w, pos + 6], fill=(162, 158, 152))
        d.rectangle([pos, 0, pos + 6, h], fill=(156, 152, 146))
    img.filter(ImageFilter.GaussianBlur(0.3)).save(path, quality=90, optimize=True)


def water_textures(surface_path, caustics_path):
    """Dual-layer animated water textures:
    1) `water_surface.png`: full-coverage translucent dark emerald-amber liquid
       surface (alpha 68..165 everywhere, never 0!) with organic wave crests and
       a faint hint of the submerged 40x40 cm Byzantine brick floor.
    2) `water_caustics.png`: counter-drifting golden-amber caustic filaments
       that interfere dynamically with layer 1 to create living liquid shimmer."""
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float64)
    u, v = xx / 256.0, yy / 256.0
    w1 = np.sin(2 * math.pi * (u * 3 + v * 2) + 0.7 * np.sin(2 * math.pi * (u * 2 - v * 3)))
    w2 = np.sin(2 * math.pi * (u * 5 - v * 4) + 0.5 * np.cos(2 * math.pi * (u * 3 + v * 5)))
    w3 = np.sin(2 * math.pi * (u * 9 + v * 7))
    wave = 0.5 + 0.25 * w1 + 0.15 * w2 + 0.10 * w3
    crest = np.clip((wave - 0.55) / 0.45, 0.0, 1.0) ** 2.2
    tile = 0.06 * ((np.abs(np.sin(math.pi * u * 4)) < 0.07)
                   | (np.abs(np.sin(math.pi * v * 4)) < 0.07))
    r = np.clip(48 + crest * 185 - tile * 30, 0, 255)
    g_ch = np.clip(62 + crest * 145 - tile * 30, 0, 255)
    b = np.clip(54 + crest * 92 - tile * 20, 0, 255)
    alpha = np.clip(82 + crest * 78 + tile * 18, 72, 168)
    Image.fromarray(np.stack([r, g_ch, b, alpha], axis=-1).astype(np.uint8), 'RGBA').save(
        surface_path, optimize=True)

    c1 = np.abs(np.sin(2 * math.pi * (u * 4 - v * 3) + 0.9 * np.sin(2 * math.pi * (u * 3 + v * 4))))
    c2 = np.abs(np.sin(2 * math.pi * (u * 3 + v * 5) + 0.8 * np.cos(2 * math.pi * (u * 4 - v * 2))))
    caustic = np.clip((1.0 - c1) ** 6 + (1.0 - c2) ** 6, 0.0, 1.0)
    cr = np.clip(220 + caustic * 35, 0, 255)
    cg = np.clip(162 + caustic * 62, 0, 255)
    cb = np.clip(98 + caustic * 54, 0, 255)
    ca = np.clip(caustic * 142, 0, 160)
    Image.fromarray(np.stack([cr, cg, cb, ca], axis=-1).astype(np.uint8), 'RGBA').filter(
        ImageFilter.GaussianBlur(0.6)).save(caustics_path, optimize=True)


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
    # Six real spolia shaft+base prototypes + three real capital+impost prototypes.
    shaft_albedos = {
        'M': mats['marble'],
        'R': mats.get('roughStone', mats['stone']),
        'T': mats.get('bandedMarble', mats['marble']),
        'D': mats.get('warmMarble', mats['stone']),
        'W': mats['marble'],
        'S': mats['marble'],
    }
    for style in ['M', 'R', 'T', 'D', 'W', 'S']:
        prototypes.append((f'shaft-{style}', g.column_shaft(style, gv, light, shaft_albedos[style])))
    for kind in ['C', 'B', 'P']:
        prototypes.append((f'cap-{kind}', g.column_capital(kind, gv, light, mats['capital'])))

    prototypes.append(('bay', g.bay(gv, light, mats['brick'], mats['arch'])))
    prototypes.append(('tie-rods', g.tie_rods(gv, tuple(mats['rail']))))
    lamp_body, lamp_glow = g.uplamp(gv, tuple(mats['rail']), tuple(mats['strip']))
    prototypes.append(('uplamp-body', lamp_body))
    prototypes.append(('uplamp-glow', lamp_glow))
    prototypes.append(('wall-long', g.wall_segment(gv, light, mats['plaster'], px, pz)))
    prototypes.append(('wall-short', g.wall_segment(gv, light, mats['plaster'], pz, px)))
    prototypes.append(('pilaster', g.pilaster(gv, light, mats['plaster'])))
    base_size = (1.05, gv['baseHeight'], 1.05)
    for special in ['medusa-sideways', 'medusa-inverted']:
        block, face = g.carved_base(gv, light, mats['stone'], 'z', base_size)
        prototypes.append((special, block))
        prototypes.append((f'{special}-face', face))
    gv['_carved_cols'] = [s['column'] for s in spec.get('specials', [])
                          if s['prototype'].startswith('medusa')]
    route = [(a * px, c * pz) for a, c in spec['route']]
    deck, rail, strip = g.walkway(route, gv, tuple(mats['deck']), tuple(mats['rail']), tuple(mats['strip']))
    st = spec['stair']
    sx, sz = st['from'][0] * px, st['from'][1] * pz
    st_mesh, st_rail, door_mesh = g.stair(
        sx + st['direction'] * gv['deckWidth'] / 2, sz, st['direction'], gv,
        st['steps'], st['rise'], st['run'], st['width'], tuple(mats['stone']),
        tuple(mats['rail']), tuple(mats['strip']))
    rail.extend(st_rail)
    strip.extend(door_mesh)
    prototypes.append(('deck', deck))
    prototypes.append(('deck-rail', rail))
    prototypes.append(('stair', st_mesh))
    prototypes.append(('deck-strip', strip))
    # Dual water planes: primary translucent ripple surface + counter-drifting caustic sheen.
    prototypes.append(('water', g.plane(0, gv['length'], 0, gv['width'], gv['waterLevel'],
                                        (1, 1, 1), uv_scale=(gv['length'] / 4.8, gv['width'] / 4.8))))
    prototypes.append(('water-caustics', g.plane(0, gv['length'], 0, gv['width'], gv['waterLevel'] + 0.008,
                                                 (1, 1, 1), uv_scale=(gv['length'] / 3.6, gv['width'] / 3.6))))
    prototypes.append(('fish', g.fish(0.42, (0.76, 0.50, 0.30), (0.86, 0.78, 0.66))))

    turned = {name: m.orient() for name, m in prototypes}
    model = out / 'model.glb'
    write_glb(model, prototypes)
    build_photo_textures(out)
    deck_grating_texture(out / 'deck.jpg')
    water_textures(out / 'water_surface.png', out / 'water_caustics.png')

    count = gv['along'] * gv['across']
    caps, turns, shafts = capitals_and_shafts(spec, count)
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
        textures=dict(
            weeping=f'assets/walk/{walk_id}/weeping.jpg',
            ripple=f'assets/walk/{walk_id}/water_surface.png',
            caustics=f'assets/walk/{walk_id}/water_caustics.png',
            marbleSmooth=f'assets/walk/{walk_id}/marble_smooth.jpg',
            marbleRough=f'assets/walk/{walk_id}/marble_rough.jpg',
            marbleBanded=f'assets/walk/{walk_id}/marble_banded.jpg',
            marbleWarm=f'assets/walk/{walk_id}/marble_warm.jpg',
            capCorinthian=f'assets/walk/{walk_id}/capital_corinthian.jpg',
            capPlain=f'assets/walk/{walk_id}/capital_plain.jpg',
            brick=f'assets/walk/{walk_id}/brick.jpg',
            plaster=f'assets/walk/{walk_id}/plaster.jpg',
            deck=f'assets/walk/{walk_id}/deck.jpg',
            medusaStone=f'assets/walk/{walk_id}/medusa_stone.jpg',
        ),
        grid=dict(length=gv['length'], width=gv['width'], along=gv['along'], across=gv['across'],
                  pitch=[round(px, 4), round(pz, 4)], columnHeight=gv['columnHeight'],
                  springing=round(gv['columnHeight'] + gv['impostHeight'], 4),
                  vaultRise=gv['vaultRise'], waterLevel=gv['waterLevel'], deckHeight=gv['deckHeight'],
                  eyeHeight=gv['eyeHeight']),
        capitals=caps,
        shafts=shafts,
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

    def nearest_column(kind, hint, use_shaft=False, anchor_y=None):
        seq = shafts if use_shaft else caps
        best = None
        for k in range(count):
            a, b = k // gv['across'] + 1, k % gv['across'] + 1
            if seq[k] != kind or any(tuple(s['column']) == (a, b) for s in spec['specials']):
                continue
            d = (a - hint[0]) ** 2 + (b - hint[1]) ** 2
            if best is None or d < best[0]:
                best = (d, a, b)
        _, a, b = best
        ay = anchor_y if anchor_y is not None else (gv['columnHeight'] - 0.35)
        return [round(a * px, 3), round(ay, 3), round(b * pz, 3)]

    if 'stops' in text:
        text['stops'] = [dict(s, eye=metres(s['eye']), look=metres(s['look'])) for s in text['stops']]
    if 'callouts' in text:
        out_callouts = []
        for c in text['callouts']:
            c = dict(c)
            if 'nearest' in c:
                c['anchor'] = nearest_column(c.pop('nearest'), c.pop('hint'))
            elif 'nearestShaft' in c:
                ay = c.pop('anchorY', 3.4)
                c['anchor'] = nearest_column(c.pop('nearestShaft'), c.pop('hint'), use_shaft=True, anchor_y=ay)
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
