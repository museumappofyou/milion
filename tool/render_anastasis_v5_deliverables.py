"""Fixed-camera v5 deliverables: semantic map, three validation prototypes,
full scene statics, 45-degree geometry views and the CURRENT/NEW sheet.

Everything is rendered with the camera centered and no animation, parallax
or light motion. Run after tool/build_anastasis_v5.py:

    python3.11 tool/render_anastasis_v5_deliverables.py
"""
import json
from pathlib import Path

import cv2
import numpy as np

import build_anastasis_v5 as b
import render_anastasis_v5 as rv

ROOT = b.ROOT
OUT = b.V5
V3 = ROOT / 'anastasis_25d/v3'

LEFT_ROCK = (230, 125, 830, 335)
RIGHT_ROCK = (1150, 125, 1720, 365)
FIGURES = (360, 250, 640, 700)
CENTER = (760, 260, 1260, 880)
RIGHT_FIGURES = (1290, 180, 1960, 800)
LEFT_FIGURES = (20, 160, 820, 860)
APP_WINDOWS = {'overview': None, 'left_rock': (130, 120, 870, 545), 'right_rock': (1120, 120, 1900, 545)}
BAND_RGB = {'back': (150, 118, 20), 'mid': (214, 176, 40), 'front': (255, 232, 92)}


def crop(img, box):
    x0, y0, x1, y1 = box
    return img[y0:y1, x0:x1]


def up(img, s, nearest=False):
    return cv2.resize(img, None, fx=s, fy=s, interpolation=cv2.INTER_NEAREST if nearest else cv2.INTER_CUBIC)


def save(name, img):
    cv2.imwrite(str(OUT / name), img)
    return img


def rock_only(scene, side):
    """The rock with nothing raised in front of it: figure areas are filled by
    continuing the rock surface, so the mountain is judged on its own."""
    H, planes, _ = b.build_height(scene, only={f'{side}_rock'})
    known = scene.facets.facet_id > 0
    known &= scene.rock_side[side]
    fill = (scene.field & ~scene.sky & ~known).astype(np.uint8)
    Hf = cv2.inpaint(H.astype(np.float32), fill, 9, cv2.INPAINT_TELEA)
    for _ in range(4):   # harmonic-like smoothing of the filled surface only
        Hf = np.where(fill > 0, cv2.GaussianBlur(Hf, (0, 0), 5), Hf)
    Hf[scene.sky] = 0
    Hf = b.extend_outside(scene, Hf)
    return dict(b.shading_maps(Hf), H=Hf, planes=planes)


def geometry_sheet(scene, box, side, scale=3):
    """Authored facets over a gray copy of the painting: band color, outline,
    id, in-plane tilt arrow, authored steps in red."""
    F = scene.facets.facet_id
    gray = cv2.cvtColor(cv2.cvtColor(scene.img, cv2.COLOR_BGR2GRAY), cv2.COLOR_GRAY2BGR)
    out = gray.copy().astype(np.float32)
    for f in scene.facets.facets:
        m = F == f['index']
        out[m] = .45 * out[m] + .55 * np.array(BAND_RGB[f['band']][::-1], np.float32)
    out = up(crop(out.astype(np.uint8), box), scale, nearest=True)
    x0, y0 = box[:2]
    Fc = up(crop(F, box).astype(np.uint8), scale, nearest=True).astype(np.int32)
    edge = np.zeros(Fc.shape, bool)
    edge[:, 1:] |= Fc[:, 1:] != Fc[:, :-1]
    edge[1:, :] |= Fc[1:, :] != Fc[:-1, :]
    out[edge] = (255, 255, 255)
    step_pairs = {(scene.facets.facets[[g['id'] for g in scene.facets.facets].index(a)]['index'],
                   scene.facets.facets[[g['id'] for g in scene.facets.facets].index(c)]['index'])
                  for (a, c) in scene.facets.steps}
    st = np.zeros(Fc.shape, bool)
    for a, c in step_pairs:
        A, C = Fc == a, Fc == c
        k = np.ones((5, 5), np.uint8)
        st |= (cv2.dilate(A.astype(np.uint8), k) > 0) & C | (cv2.dilate(C.astype(np.uint8), k) > 0) & A
    out[st] = (40, 40, 230)
    for f in scene.facets.facets:
        if f['side'] != side:
            continue
        ys, xs = np.nonzero(F == f['index'])
        if len(xs) == 0:
            continue
        cx, cy = xs.mean(), ys.mean()
        if not (box[0] < cx < box[2] and box[1] < cy < box[3]):
            continue
        px, py = int((cx - x0) * scale), int((cy - y0) * scale)
        gx, gy = b.facet_tilt(f)
        n = np.hypot(gx, gy)
        if n > 1e-6:
            L = 18 + 90 * n
            q = (int(px - gx / n * L), int(py - gy / n * L))   # normal leans toward -grad
            cv2.arrowedLine(out, (px, py), q, (20, 20, 20), 3, tipLength=.3)
            cv2.arrowedLine(out, (px, py), q, (255, 255, 255), 1, tipLength=.3)
        cv2.putText(out, f['id'], (px - 34, py + 22), cv2.FONT_HERSHEY_SIMPLEX, .5, (20, 20, 20), 3, cv2.LINE_AA)
        cv2.putText(out, f['id'], (px - 34, py + 22), cv2.FONT_HERSHEY_SIMPLEX, .5, (255, 255, 255), 1, cv2.LINE_AA)
    legend = [('back', BAND_RGB['back']), ('mid', BAND_RGB['mid']), ('front', BAND_RGB['front'])]
    y = 10
    for name, rgb in legend:
        cv2.rectangle(out, (10, y), (34, y + 18), rgb[::-1], -1)
        cv2.putText(out, name, (40, y + 15), cv2.FONT_HERSHEY_SIMPLEX, .55, (255, 255, 255), 2, cv2.LINE_AA)
        y += 24
    cv2.putText(out, 'white: crease   red: authored step   arrow: facing', (10, y + 15),
                cv2.FONT_HERSHEY_SIMPLEX, .55, (255, 255, 255), 2, cv2.LINE_AA)
    return out


def masked_normals(N, mask):
    v = b.normal_viz(N)
    v[~mask] = (v[~mask] * .25 + 40).astype(np.uint8)
    return v


def part_outline_sheet(scene, box, scale=2.5):
    sem = b.semantic_image(scene)
    out = up(crop(sem, box), scale, nearest=True)
    P = up(crop(scene.part_id + 1, box).astype(np.uint16), scale, nearest=True).astype(np.int32)
    edge = np.zeros(P.shape, bool)
    edge[:, 1:] |= P[:, 1:] != P[:, :-1]
    edge[1:, :] |= P[1:, :] != P[:-1, :]
    out[edge] = (250, 250, 250)
    x0, y0 = box[:2]
    for i, (layer, part) in enumerate(scene.parts):
        ys, xs = np.nonzero(scene.part_id == i)
        if len(xs) < 400:
            continue
        cx, cy = np.median(xs), np.median(ys)
        if box[0] < cx < box[2] and box[1] < cy < box[3]:
            t = f"{part['id']} ({layer['id'].split('_')[-1]})"
            p = (int((cx - x0) * scale) - 50, int((cy - y0) * scale))
            cv2.putText(out, t, p, cv2.FONT_HERSHEY_SIMPLEX, .5, (0, 0, 0), 3, cv2.LINE_AA)
            cv2.putText(out, t, p, cv2.FONT_HERSHEY_SIMPLEX, .5, (255, 255, 255), 1, cv2.LINE_AA)
    return out


def phone_frame(img, window, size=(390, 844), fov=1.0, overview=False):
    """Software stand-in for the app's centered photo framing."""
    W, Hh = size
    frame = np.zeros((Hh, W, 3), np.uint8)
    frame[:] = (24, 25, 27)
    x0, y0, x1, y1 = window or (0, 0, img.shape[1], img.shape[0])
    s = min(W / (x1 - x0), Hh / (y1 - y0)) / fov
    if overview:
        s /= .64
    M = np.float32([[s, 0, (W - (x1 - x0) * s) / 2 - x0 * s], [0, s, (Hh - (y1 - y0) * s) / 2 - y0 * s]])
    return cv2.warpAffine(img, M, (W, Hh), frame, flags=cv2.INTER_AREA, borderMode=cv2.BORDER_TRANSPARENT)


def legend_strip(width):
    items = [('background', 'background'), ('mountain back', 'mountain_back'), ('mountain mid', 'mountain_mid'),
             ('mountain front', 'mountain_front'), ('rear figures', 'rear'), ('middle figures', 'middle'),
             ('front figures', 'front'), ('Adam / Eve', 'principal'), ('mandorla', 'mandorla'), ('Christ', 'christ'),
             ('ground', 'ground'), ('tomb', 'tomb'), ('gates', 'gate'), ('pit', 'pit'), ('Hades', 'hades')]
    strip = np.full((70, width, 3), 20, np.uint8)
    x, y = 12, 12
    for name, key in items:
        (tw, _), _ = cv2.getTextSize(name, cv2.FONT_HERSHEY_SIMPLEX, .55, 1)
        if x + 30 + tw > width - 10:
            x, y = 12, y + 28
        cv2.rectangle(strip, (x, y), (x + 20, y + 18), b.COLORS[key][::-1], -1)
        cv2.rectangle(strip, (x, y), (x + 20, y + 18), (120, 120, 120), 1)
        cv2.putText(strip, name, (x + 26, y + 15), cv2.FONT_HERSHEY_SIMPLEX, .55, (235, 235, 235), 1, cv2.LINE_AA)
        x += 40 + tw
    return strip


def export_app_assets(scene, full, front, raking, sem):
    """Fixed-camera views for the Flutter viewer, all on the master pixel grid."""
    out = ROOT / 'assets/anastasis/relief_v5'
    out.mkdir(parents=True, exist_ok=True)
    jpg = [cv2.IMWRITE_JPEG_QUALITY, 92]
    views = [('relief', 'Relief', 'relief_front.jpg', front),
             ('raking', 'Raking light (debug)', 'raking_debug.jpg', raking),
             ('semantic', 'Semantic layers', 'semantic_layers.png', sem),
             ('normals', 'Normals', 'normals.jpg', b.normal_viz(full['N'])),
             ('depth', 'Height', 'height.jpg', b.height_viz(full['H']))]
    for _, _, name, image in views:
        cv2.imwrite(str(out / name), image, jpg if name.endswith('.jpg') else [])
    manifest = {
        'master': 'assets/anastasis/conch_reference.jpg',
        'size': [int(scene.shape[1]), int(scene.shape[0])],
        'generator': 'tool/build_anastasis_v5.py + tool/render_anastasis_v5_deliverables.py',
        'camera': 'centered orthographic, no parallax or animation',
        'lighting': {'direction': [round(float(v), 3) for v in b.LIGHT],
                     'reliefLightClamp': list(b.PRODUCTION['clamp']),
                     'formula': 'originalRGB * reliefLight * contactShadow * occlusion'},
        'partDepth': full['part_z'],
        'views': [{'id': i, 'label': label, 'file': f'assets/anastasis/relief_v5/{name}'}
                  for i, label, name, _ in views],
    }
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=1) + '\n')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    scene = b.Scene()
    img = scene.img
    full = b.render_all(scene)
    front = b.shade_mode(img, full, 'production')
    raking = b.shade_mode(img, full, 'debug')

    # Semantic depth mask (hard gate).
    sem = save('semantic_layers.png', b.semantic_image(scene))
    save('semantic_layers_labeled.png', np.vstack([sem, legend_strip(sem.shape[1])]))
    save('semantic_layers_390.png', cv2.resize(sem, (390, round(390 * sem.shape[0] / sem.shape[1])),
                                               interpolation=cv2.INTER_AREA))

    # Prototype 1 — left and right mountains, judged on their own.
    for side, box in (('left', LEFT_ROCK), ('right', RIGHT_ROCK)):
        r = rock_only(scene, side)
        rock_mask = crop(scene.rock_side[side], box)
        save(f'{side}_rock_original.png', up(crop(img, box), 3))
        save(f'{side}_rock_geometry.png', geometry_sheet(scene, box, side))
        save(f'{side}_rock_normals.png', up(masked_normals(crop(r['N'], box), rock_mask), 3, nearest=True))
        save(f'{side}_rock_depth.png', up(b.height_viz(crop(r['H'], box), 32), 3))
        rf = b.shade_mode(img, r, 'production')
        rd = b.shade_mode(img, r, 'debug')
        save(f'{side}_rock_front.png', up(crop(rf, box), 3))
        save(f'{side}_rock_raking_light.png', up(crop(rd, box), 3))
        sv = rv.side_view(rf, r['H'], region=box, zscale=2.0, out_scale=2.2)
        save(f'{side}_rock_side45.png', rv.label(sv, 'rock only · 45 deg · relief x2'))
        (OUT / f'{side}_rock_facets_solved.json').write_text(json.dumps(
            {k: v for k, v in r['planes'].items() if k[0] == side[0].upper()}, indent=1))

    # Prototype 2 — three overlapping witnesses (rear heads, David, Solomon).
    save('figures_original.png', up(crop(img, FIGURES), 2.5))
    save('figures_masks.png', part_outline_sheet(scene, FIGURES))
    save('figures_front.png', up(crop(front, FIGURES), 2.5))
    save('figures_raking_light.png', up(crop(raking, FIGURES), 2.5))
    sv = rv.side_view(front, full['H'], region=FIGURES, zscale=1.5, out_scale=2.0)
    save('figures_side45.png', rv.label(sv, '45 deg · relief x1.5'))

    # Prototype 3 — Christ and mandorla.
    save('christ_original.png', up(crop(img, CENTER), 1.6))
    save('christ_relief.png', up(crop(front, CENTER), 1.6))
    save('christ_raking_light.png', up(crop(raking, CENTER), 1.6))
    sv = rv.side_view(front, full['H'], region=CENTER, zscale=1.5, out_scale=1.3)
    save('christ_side45.png', rv.label(sv, '45 deg · relief x1.5'))
    tiles = []
    for yaw, pitch in ((-6, 0), (6, 0), (0, -4), (0, 4)):
        v = rv.side_view(front, full['H'], region=CENTER, yaw=yaw, pitch=pitch, zscale=1.0, out_scale=0.8)
        tiles.append(rv.label(v, f'yaw {yaw:+d}  pitch {pitch:+d}', .55))
    save('christ_parallax_test.png', rv.vstack([rv.hstack(tiles[:2]), rv.hstack(tiles[2:])]))

    # Full scene statics and geometry.
    save('full_front.png', front)
    save('full_raking_light.png', raking)
    save('full_normals.png', b.normal_viz(full['N']))
    save('full_depth.png', b.height_viz(full['H']))
    save('full_shadow_ao.png', (np.dstack([full['shadow'] * full['ao']] * 3) * 255).astype(np.uint8))
    sv = rv.side_view(front, full['H'], region=(0, 60, 2048, 1030), zscale=1.5, out_scale=.62)
    save('full_side45.png', rv.label(sv, 'full scene · 45 deg · relief x1.5'))
    for name, window in APP_WINDOWS.items():
        save(f'static_{name}_390x844_software.png',
             phone_frame(front, window, overview=name == 'overview'))
    save('static_original_390x844_software.png', phone_frame(img, None, overview=True))
    save('static_desktop_1920x1080_software.png', phone_frame(front, (0, 40, 2048, 1060), (1920, 1080)))

    # CURRENT (v3, what the app ships) vs NEW (v5), all static.
    current = cv2.imread(str(V3 / 'static_full_resolution.png'))
    rows = []
    panel_w = 900
    for title, box in (('LEFT MOUNTAIN', LEFT_ROCK), ('RIGHT MOUNTAIN', RIGHT_ROCK),
                       ('LEFT FIGURES', LEFT_FIGURES), ('RIGHT FIGURES', RIGHT_FIGURES),
                       ('CENTER', CENTER), ('FULL SCENE', (0, 40, 2048, 1060))):
        a = rv.label(rv.fit(crop(current, box), width=panel_w), 'CURRENT (v3 app)', .6)
        n = rv.label(rv.fit(crop(front, box), width=panel_w), 'NEW (v5)', .6)
        head = np.full((40, panel_w * 2 + 6, 3), 18, np.uint8)
        cv2.putText(head, title + '  - static, centered, no motion', (8, 28), cv2.FONT_HERSHEY_SIMPLEX, .8,
                    (240, 240, 240), 2, cv2.LINE_AA)
        rows.append(rv.vstack([head, rv.hstack([a, n])], gap=0))
    save('diagnostic_current_vs_new.png', rv.vstack(rows, gap=14))
    export_app_assets(scene, full, front, raking, sem)
    print('wrote deliverables to', OUT)


if __name__ == '__main__':
    main()
