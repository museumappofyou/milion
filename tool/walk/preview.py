"""Usage: python3.11 tool/walk/preview.py <walk id> <out.png> [x z yaw pitch]

A host-side software render of a walk (P14) for checking the prototypes and
their placement before the phone: the same instancing and water mirror as
lib/walk/walk_scene.dart, unlit vertex colours, exponential-squared fog and a
z-buffer. It is a check, not the app's picture (no textures, no tone map,
no anti-aliasing); captures say so.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'space'))
from glb import read_glb  # noqa: E402  (tool/space/glb.py reads any glb)

ROOT = Path(__file__).resolve().parents[2]


def load_prototypes(path):
    import struct
    data = Path(path).read_bytes()
    length = struct.unpack('<I', data[12:16])[0]
    doc = json.loads(data[20:20 + length])
    blob_start = 20 + length + 8
    blob = data[blob_start:]

    def acc(i):
        a = doc['accessors'][i]
        v = doc['bufferViews'][a['bufferView']]
        comps = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32}[a['componentType']]
        arr = np.frombuffer(blob, dtype=dtype, count=a['count'] * comps, offset=v['byteOffset'])
        return arr.reshape(a['count'], comps)

    out = {}
    for node in doc['nodes']:
        prim = doc['meshes'][node['mesh']]['primitives'][0]
        out[node['name']] = (acc(prim['attributes']['POSITION']).astype(np.float64),
                             acc(prim['attributes']['COLOR_0']).astype(np.float64),
                             acc(prim['indices']).reshape(-1, 3).astype(np.int64))
    return out


def instances(m):
    """(prototype, 4x4, colour factor) for the whole hall, as the app places it."""
    g = m['grid']
    px, pz = g['pitch']
    yw = g['waterLevel']
    specials = {tuple(s['column']): s['prototype'] for s in m['specials']}
    out = []

    def add(name, mat, factor=1.0):
        out.append((name, mat, factor))
        mirror = np.diag([1.0, -1.0, 1.0, 1.0])
        mirror[1, 3] = 2 * yw
        dim = m['lighting']['water']['mirrorDim'][0]
        out.append((name, mirror @ mat, factor * dim))

    def tr(x, y, z, turn=0.0):
        c, s = math.cos(turn), math.sin(turn)
        return np.array([[c, 0, s, x], [0, 1, 0, y], [-s, 0, c, z], [0, 0, 0, 1]])

    k = 0
    for a in range(1, g['along'] + 1):
        for b in range(1, g['across'] + 1):
            kind = m['capitals'][k]
            turn = int(m['turns'][k]) * math.pi / 2
            k += 1
            x, z = a * px, b * pz
            special = specials.get((a, b))
            if special and special.startswith('medusa'):
                add(special, tr(x, 0, z))
                add('column-S', tr(x, 0, z, turn))
            elif special:
                add(special, tr(x, 0, z, turn))
            else:
                add(f'column-{kind}', tr(x, 0, z, turn))
    for a in range(g['along'] + 1):
        for b in range(g['across'] + 1):
            add('bay', tr((a + .5) * px, 0, (b + .5) * pz))
    for a in range(g['along'] + 1):
        add('wall-long', tr((a + .5) * px, 0, 0))
        add('wall-long', tr((a + .5) * px, 0, g['width'], math.pi))
    for b in range(g['across'] + 1):
        add('wall-short', tr(0, 0, (b + .5) * pz, -math.pi / 2))
        add('wall-short', tr(g['length'], 0, (b + .5) * pz, math.pi / 2))
    out.append(('deck', np.eye(4), 1.0))
    return out


def render(walk_id, out_path, eye=None, size=(360, 640)):
    m = json.loads((ROOT / f'assets/walk/{walk_id}/walk.json').read_text())
    protos = load_prototypes(ROOT / m['model'])
    g = m['grid']
    if eye is None:
        x, z = m['route'][1]
        eye = (x, z, 180.0, 4.0)
    ex, ez, yaw, pitch = eye
    ey = g['deckHeight'] + g['eyeHeight']
    w, h = size
    fov = math.radians(70)
    f = (h / 2) / math.tan(fov / 2)
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    cp, sp = math.cos(math.radians(pitch)), math.sin(math.radians(pitch))
    forward = np.array([cy * cp, sp, sy * cp])
    right = np.cross(forward, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    fog = m['lighting']['fog']
    far = fog['far']
    colour = np.zeros((h, w, 3))
    colour[:] = fog['colour']
    depth = np.full((h, w), np.inf)
    pos_eye = np.array([ex, ey, ez])
    water = m['lighting']['water']
    for name, mat, factor in instances(m):
        P, C, F = protos[name]
        centre = mat[:3, 3]
        if name != 'deck' and np.linalg.norm(centre - pos_eye) > far + 6:
            continue
        world = (mat[:3, :3] @ P.T).T + mat[:3, 3]
        rel = world - pos_eye
        zc = rel @ forward
        xs = rel @ right
        ys = rel @ up
        valid = zc > 0.05
        sx = w / 2 + f * xs / np.where(valid, zc, 1)
        sy_ = h / 2 - f * ys / np.where(valid, zc, 1)
        dist = np.linalg.norm(rel, axis=1)
        fogk = np.exp(-(fog['density'] * dist) ** 2)
        col = C * factor * fogk[:, None] + np.array(fog['colour']) * (1 - fogk[:, None])
        for tri in F:
            if not valid[tri].all():
                continue
            xa, ya = sx[tri], sy_[tri]
            area = (xa[1] - xa[0]) * (ya[2] - ya[0]) - (xa[2] - xa[0]) * (ya[1] - ya[0])
            if abs(area) < 1e-9:
                continue
            x0, x1 = max(0, int(xa.min())), min(w - 1, int(xa.max()) + 1)
            y0, y1 = max(0, int(ya.min())), min(h - 1, int(ya.max()) + 1)
            if x0 > x1 or y0 > y1:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + .5, np.arange(y0, y1 + 1) + .5)
            l0 = ((xa[1] - gx) * (ya[2] - gy) - (xa[2] - gx) * (ya[1] - gy)) / area
            l1 = ((xa[2] - gx) * (ya[0] - gy) - (xa[0] - gx) * (ya[2] - gy)) / area
            l2 = 1 - l0 - l1
            inside = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
            if not inside.any():
                continue
            iz = l0 / zc[tri[0]] + l1 / zc[tri[1]] + l2 / zc[tri[2]]
            z = 1 / np.where(inside, iz, 1e-9)
            region = depth[y0:y1 + 1, x0:x1 + 1]
            closer = inside & (z < region)
            if not closer.any():
                continue
            c = (l0[..., None] * col[tri[0]] / zc[tri[0]] + l1[..., None] * col[tri[1]] / zc[tri[1]]
                 + l2[..., None] * col[tri[2]] / zc[tri[2]]) * z[..., None]
            region[closer] = z[closer]
            colour[y0:y1 + 1, x0:x1 + 1][closer] = c[closer]
    # The water: a translucent plane over the mirror below it.
    yw = g['waterLevel']
    gy, gx = np.mgrid[0:h, 0:w] + .5
    dirs = (forward[None, None, :] + ((gx - w / 2) / f)[..., None] * right[None, None, :]
            - ((gy - h / 2) / f)[..., None] * up[None, None, :])
    t = (yw - ey) / np.where(np.abs(dirs[..., 1]) > 1e-6, dirs[..., 1], -1e-6)
    zdist = t * (dirs @ forward)
    hit = (t > 0) & (zdist < depth) & (zdist < far)
    a = water['alpha']
    colour[hit] = colour[hit] * (1 - a) + np.array(water['colour']) * a
    img = np.clip(colour, 0, 1) ** (1 / 2.2)
    Image.fromarray((img * 255).astype(np.uint8)).save(out_path)


if __name__ == '__main__':
    eye = tuple(float(v) for v in sys.argv[3:7]) if len(sys.argv) >= 7 else None
    render(sys.argv[1], sys.argv[2], eye)
