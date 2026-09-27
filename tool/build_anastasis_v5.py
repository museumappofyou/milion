"""Fifth-pass Anastasis painted relief.

Usage: python3.11 tool/build_anastasis_v5.py
One physical height field over the master photograph:

* semantic depth clusters from authored masks, resolved in painted overlap
  order (studio/anastasis_25d/v5/authoring/layers.json);
* rock made of authored planar facets that follow the painted rock planes,
  solved jointly so a shared painted edge is a crease and an authored overlap
  is a step (studio/anastasis_25d/v5/authoring/rock_facets.json);
* figures as raised parts with a rounded edge, a shallow body swell and head
  domes, each clearing the parts it overlaps;
* one fixed raking light, soft height-field shadows and occlusion that only
  modulate the original RGB.

Run from the repository root:  python3.11 tool/build_anastasis_v5.py
"""
import json
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage, sparse
from scipy.sparse.linalg import lsqr

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / 'assets/anastasis/conch_reference.jpg'
V5 = ROOT / 'studio/anastasis_25d/v5'
AUTH = V5 / 'authoring'
H_SCALE = 256.0  # 16-bit height PNG: value = z * H_SCALE

# Semantic review colors (RGB), using the brief's palette for required clusters.
COLORS = {
    'background': (46, 46, 50),
    'mountain_back': (150, 118, 20), 'mountain_mid': (214, 176, 40),
    'mountain_front': (255, 232, 92),
    'rear': (124, 72, 170), 'middle': (60, 110, 215), 'front': (40, 170, 80),
    'principal': (245, 140, 30), 'mandorla': (40, 215, 225), 'christ': (225, 40, 40),
    'ground': (178, 150, 110), 'tomb': (150, 95, 70), 'gate': (205, 185, 150),
    'pit': (20, 20, 22), 'hades': (95, 95, 100),
}
BAND_Z = {'back': 11.0, 'mid': 17.0, 'front': 22.0}
ROCK_Z_RANGE = (3.0, 30.0)

# One fixed raking light from the upper left (image y points down).
LIGHT = np.array([-0.45, -0.60, 0.66])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
# Development light: same azimuth, much lower (22 deg) so facet orientation
# dominates the diagnosis.
DEBUG_LIGHT = np.array([-0.56, -0.74, 0.37])
DEBUG_LIGHT = DEBUG_LIGHT / np.linalg.norm(DEBUG_LIGHT)
PRODUCTION = dict(light=LIGHT, ambient=.38, clamp=(.88, 1.08), shadow=.34, ao=.45, ao_floor=.9)
DEBUG = dict(light=DEBUG_LIGHT, ambient=.1, clamp=(.62, 1.38), shadow=.5, ao=.7, ao_floor=.8)


def load_json(name):
    return json.loads((AUTH / name).read_text())


def load_master():
    return cv2.imread(str(MASTER))


def poly_mask(shape, pts):
    m = np.zeros(shape, np.uint8)
    cv2.fillPoly(m, [np.array(pts, np.int32)], 1)
    return m.astype(bool)


def shape_mask(shape, spec):
    if 'circle' in spec:
        x, y, r = spec['circle']
        m = np.zeros(shape, np.uint8)
        cv2.circle(m, (int(x), int(y)), int(r), 1, -1)
        return m.astype(bool)
    if 'ellipse' in spec:
        x, y, rx, ry = spec['ellipse']
        m = np.zeros(shape, np.uint8)
        cv2.ellipse(m, (int(x), int(y)), (int(rx), int(ry)), 0, 0, 360, 1, -1)
        return m.astype(bool)
    return poly_mask(shape, spec['poly'])


def clean(mask, min_area=250, hole_area=2500, radius=2):
    m = mask.astype(np.uint8)
    if radius:
        k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * radius + 1,) * 2)
        m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, k)
        m = cv2.morphologyEx(m, cv2.MORPH_OPEN, k)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
    keep = np.zeros(n, bool)
    keep[1:] = stats[1:, cv2.CC_STAT_AREA] >= min_area
    m = keep[lab]
    inv = (~m).astype(np.uint8)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(inv, connectivity=4)
    small = np.zeros(n, bool)
    small[1:] = stats[1:, cv2.CC_STAT_AREA] < hole_area
    return m | small[lab]


def part_mask(shape, part):
    m = np.zeros(shape, bool)
    for sid in part.get('sam', []):
        m |= cv2.imread(str(AUTH / 'sam' / f'{sid}.png'), 0) > 127
    for spec in part.get('add', []):
        m |= shape_mask(shape, spec)
    for spec in part.get('sub', []):
        m &= ~shape_mask(shape, spec)
    for spec in part.get('add', []):   # explicit additions win over subtractions
        if 'ellipse' in spec:
            m |= shape_mask(shape, spec)
    return clean(m)


class Scene:
    """Label maps for layers (semantic clusters), parts and rock facets."""

    def __init__(self):
        self.img = load_master()
        h, w = self.shape = self.img.shape[:2]
        cfg = load_json('layers.json')
        self.field = poly_mask(self.shape, cfg['field'])
        self.layers = cfg['layers']
        self.parts = []            # (layer, part) in painting order
        part_masks = []
        for layer in self.layers:
            for part in layer['parts']:
                self.parts.append((layer, part))
                part_masks.append(part_mask(self.shape, part) & self.field)
        anything = np.any(np.stack(part_masks), 0)
        sky = cv2.imread(str(AUTH / 'sam' / 'sky.png'), 0) > 127
        self.sky = clean(sky, min_area=5000, hole_area=30000) & self.field & ~anything
        rock = clean(self.field & ~self.sky & ~anything, min_area=600, hole_area=0, radius=1)
        self.part_id = np.full(self.shape, -1, np.int32)   # -1 background/rock
        for i, m in enumerate(part_masks):
            self.part_id[m] = i
        # Thin rock slivers between touching figures are mask gaps, not
        # painted ground: give them to the nearest part.
        core = cv2.morphologyEx(rock.astype(np.uint8), cv2.MORPH_OPEN,
                                cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))) > 0
        sliver = rock & ~core
        dist, (iy, ix) = ndimage.distance_transform_edt(self.part_id < 0, return_indices=True)
        near = self.part_id[iy, ix]
        fill = sliver & (near >= 0) & (dist <= 6)
        self.part_id[fill] = near[fill]
        self.rock = rock & (self.part_id < 0)
        xs = np.arange(w)[None, :]
        self.rock_side = {'left': self.rock & (xs < w // 2), 'right': self.rock & (xs >= w // 2)}
        self.facets = RockFacets(self)

    def cluster_of_pixel(self):
        """Semantic class per pixel for the review image."""
        names = np.empty(self.shape, object)
        names[:] = 'background'
        for i, (layer, part) in enumerate(self.parts):
            kind = layer['kind']
            key = {'figure': layer['id'].split('_')[-1]}.get(kind, kind)
            if kind == 'lower':
                key = 'gate' if 'gate' in layer['id'] else layer['id']
            names[self.part_id == i] = key
        for f in self.facets.facets:
            names[self.facets.facet_id == f['index']] = 'mountain_' + f['band']
        return names


class RockFacets:
    """Authored rock planes. A facet is a painted rock polygon; pixels of the
    rock mask that no polygon covers join the nearest facet, so polygons only
    have to be exact along internal painted edges, not along silhouettes."""

    def __init__(self, scene):
        spec = load_json('rock_facets.json')
        self.scene = scene
        self.facets = []
        self.facet_id = np.zeros(scene.shape, np.int32)   # 0 = none
        self.steps = {}
        for side, sd in spec['sides'].items():
            rock = scene.rock_side[side]
            fid = np.zeros(scene.shape, np.int32)
            for f in sd['facets']:
                f = dict(f, side=side, index=len(self.facets) + 1)
                self.facets.append(f)
                fid[poly_mask(scene.shape, f['poly']) & rock] = f['index']
            if not (fid > 0).any():
                continue
            # Nearest-facet fill for uncovered rock pixels.
            _, (iy, ix) = ndimage.distance_transform_edt(fid == 0, return_indices=True)
            fid = np.where(rock, fid[iy, ix], 0)
            fid = snap_to_strokes(fid, rock, stroke_energy(scene.img, rock), spec.get('snap', 7))
            fid = smooth_labels(fid, rock, 4.0)
            self.facet_id[rock] = fid[rock]
            for a, b, dz in sd.get('steps', []):
                self.steps[(a, b)] = dz

    def solve(self, anchor=1.5e-4):
        """Gradient-domain surface: inside a facet the target gradient is its
        authored tilt, so each facet is a plane; across a shared edge the
        target is the mean tilt (continuous crease) or, for an authored step,
        the step height. A weak anchor to each facet's band depth keeps large
        facets from drifting (length scale ~1/sqrt(anchor) px)."""
        F = self.facet_id
        on = F > 0
        idx = -np.ones(F.shape, np.int64)
        idx[on] = np.arange(on.sum())
        n = int(on.sum())
        if n == 0:
            return np.zeros(F.shape, np.float32), {}
        tilt = np.zeros((len(self.facets) + 1, 2))
        zb = np.zeros(len(self.facets) + 1)
        ids = {}
        for f in self.facets:
            tilt[f['index']] = facet_tilt(f)
            zb[f['index']] = f.get('z', BAND_Z[f['band']])
            ids[f['id']] = f['index']
        jump = {}
        for (up, lo), dz in self.steps.items():
            jump[(ids[up], ids[lo])] = -dz   # H(lower) - H(upper)
            jump[(ids[lo], ids[up])] = dz
        rows, cols, vals, rhs = [], [], [], []
        r = 0
        for dy, dx, k in ((0, 1, 0), (1, 0, 1)):
            A = F[: F.shape[0] - dy, : F.shape[1] - dx]
            B = F[dy:, dx:]
            sel = (A > 0) & (B > 0)
            ia = idx[: F.shape[0] - dy, : F.shape[1] - dx][sel]
            ib = idx[dy:, dx:][sel]
            fa, fb = A[sel], B[sel]
            t = 0.5 * (tilt[fa, k] + tilt[fb, k])
            same = fa == fb
            t[same] = tilt[fa[same], k]
            for (u, v), dz in jump.items():
                m = (fa == u) & (fb == v)
                t[m] += dz
            m = len(ia)
            rows += [np.arange(r, r + m)] * 2
            cols += [ib, ia]
            vals += [np.ones(m), -np.ones(m)]
            rhs.append(t)
            r += m
        w = np.sqrt(anchor)
        rows.append(np.arange(r, r + n))
        cols.append(np.arange(n))
        vals.append(np.full(n, w))
        rhs.append(w * zb[F[on]])
        r += n
        M = sparse.csr_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(r, n))
        rhs = np.concatenate(rhs)
        from scipy.sparse.linalg import spsolve
        x = spsolve((M.T @ M).tocsc(), M.T @ rhs)
        H = np.zeros(F.shape, np.float32)
        H[on] = x
        planes = {}
        for f in self.facets:
            m = F == f['index']
            if m.any():
                gy, gx = np.gradient(np.where(m, H, np.nan))
                planes[f['id']] = dict(meanZ=float(H[m].mean()), minZ=float(H[m].min()), maxZ=float(H[m].max()),
                                       tilt=[round(float(v), 3) for v in facet_tilt(f)],
                                       solvedTilt=[round(float(np.nanmedian(gx)), 3), round(float(np.nanmedian(gy)), 3)])
        return H, planes


def facet_tilt(f):
    if 'tilt' in f:
        return f['tilt']
    fx, fy = f.get('face', (0.0, 0.0))
    n = np.hypot(fx, fy) or 1.0
    s = f.get('slope', 0.0)
    return [-s * fx / n, -s * fy / n]


def stroke_energy(img, mask):
    """Painted facet edges: dark contour strokes, light highlight strokes and
    value steps between planes, each normalized inside the rock."""
    from skimage.filters import sato
    L = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)[..., 0]
    L = cv2.createCLAHE(3, (16, 16)).apply(L).astype(np.float32) / 255
    ys, xs = np.nonzero(mask)
    y0, y1, x0, x1 = max(ys.min() - 8, 0), ys.max() + 9, max(xs.min() - 8, 0), xs.max() + 9
    sub = L[y0:y1, x0:x1]
    dark = sato(sub, sigmas=[1.5, 2.5, 3.5], black_ridges=True)
    light = sato(sub, sigmas=[1.5, 2.5], black_ridges=False)
    g = cv2.GaussianBlur(sub, (0, 0), 2.0)
    step = np.hypot(cv2.Sobel(g, cv2.CV_32F, 1, 0), cv2.Sobel(g, cv2.CV_32F, 0, 1))
    m = mask[y0:y1, x0:x1]
    E = np.zeros(L.shape, np.float32)
    E[y0:y1, x0:x1] = sum(w * c / (np.percentile(c[m], 97) + 1e-6)
                          for w, c in ((1.0, dark), (0.4, light), (0.7, step)))
    return E


def snap_to_strokes(fid, rock, E, band):
    """Move each authored facet boundary onto the strongest painted stroke
    within `band` px (marker watershed on stroke energy)."""
    from skimage.segmentation import watershed
    if band <= 0:
        return fid
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    markers = np.zeros_like(fid)
    for i in np.unique(fid[fid > 0]):
        m = (fid == i).astype(np.uint8)
        # Distance to other facets only; silhouettes are not boundaries.
        other = ((fid > 0) & (fid != i)).astype(np.uint8)
        d = cv2.distanceTransform(1 - other, cv2.DIST_L2, 5)
        core = (m > 0) & (d > band)
        if core.sum() < 20:
            core = cv2.erode(m, k) > 0
        markers[core] = i
    return np.where(rock, watershed(cv2.GaussianBlur(E, (0, 0), 1.0), markers, mask=rock), 0)


def smooth_labels(fid, mask, sigma):
    """Majority-smooth label boundaries (removes stroke-noise jaggies)."""
    ids = np.unique(fid[fid > 0])
    best = np.full(fid.shape, -1.0, np.float32)
    out = fid.copy()
    for i in ids:
        v = cv2.GaussianBlur((fid == i).astype(np.float32), (0, 0), sigma)
        take = v > best
        out[take] = i
        best[take] = v[take]
    return np.where(mask, out, 0)


def relief_profile(mask, relief, heads, plane):
    """Rounded edge + shallow swell + head domes (+ optional tilt), zero at
    the part outline."""
    m8 = mask.astype(np.uint8)
    d = cv2.distanceTransform(m8, cv2.DIST_L2, 5)
    h = np.zeros(mask.shape, np.float32)
    if relief.get('bevel'):
        t = np.clip(d / relief['bevel_r'], 0, 1)
        h += relief['bevel'] * (1 - (1 - t) ** 2)
    if relief.get('body'):
        h += relief['body'] * (1 - np.exp(-d / relief['body_r']))
    yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
    for x, y, r in heads:
        q = 1 - ((xx - x) ** 2 + (yy - y) ** 2) / float(r * r)
        h += relief.get('head', 3.0) * np.sqrt(np.clip(q, 0, 1)) * np.clip(d / 6, 0, 1)
    if plane is not None and mask.any():
        ys, xs = np.nonzero(mask)
        h += plane[0] * (xx - xs.mean()) + plane[1] * (yy - ys.mean())
    return np.where(mask, h, 0)


def build_height(scene, only=None):
    """Assemble the height field. `only` restricts relief to a set of layer ids
    (everything else stays on the flat base fresco) for isolated prototypes."""
    H = np.zeros(scene.shape, np.float32)
    rock_h, planes = scene.facets.solve()
    rock_h = np.clip(rock_h, *ROCK_Z_RANGE)
    # Rounded silhouette where rock meets the open sky.
    d = cv2.distanceTransform((~scene.sky).astype(np.uint8), cv2.DIST_L2, 5)
    rock_h -= 3.0 * (1 - np.clip(d / 5.0, 0, 1)) ** 2
    rock_on = scene.facets.facet_id > 0
    if only is not None:
        keep = np.zeros(scene.shape, bool)
        for side in ('left', 'right'):
            if f'{side}_rock' in only:
                keep |= scene.rock_side[side]
        rock_on &= keep
    H[rock_on] = rock_h[rock_on]
    placed = rock_on.copy()
    layer_of = np.full(scene.shape, '', object)
    layer_of[rock_on] = 'rock'
    part_z = {}
    ring_k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    for i, (layer, part) in enumerate(scene.parts):
        if only is not None and layer['id'] not in only:
            continue
        m = scene.part_id == i
        if not m.any():
            continue
        relief = dict(layer.get('relief', {}), **part.get('relief', {}))
        h = relief_profile(m, relief, part.get('heads', []), part.get('plane'))
        base = float(layer['z'])
        ring = (cv2.dilate(m.astype(np.uint8), ring_k) > 0) & ~m & placed
        if 'clear' in layer:
            ring &= np.isin(layer_of, layer['clear'])
        if ring.any():
            base = max(base, float(np.percentile(H[ring], 97)) + 2.0)
        H[m] = base + h[m]
        placed |= m
        layer_of[m] = layer['id']
        part_z[part['id']] = round(base, 2)
    return extend_outside(scene, H), planes, part_z


def extend_outside(scene, H):
    """The frame and neighbouring paintings continue the height of the
    adjacent sky or rock (never of a raised figure), so the fresco border is
    not an artificial cliff; far from the border they relax smoothly."""
    src = scene.field & (scene.part_id < 0)
    dist, (iy, ix) = ndimage.distance_transform_edt(~src, return_indices=True)
    ext = H[iy, ix]
    smooth = cv2.GaussianBlur(ext, (0, 0), 8)
    w = np.clip(dist / 14.0, 0, 1)
    out = H.copy()
    outside = ~scene.field
    out[outside] = ((1 - w) * ext + w * smooth)[outside]
    return out


def normals(H, max_slope=1.0):
    gy, gx = np.gradient(H.astype(np.float64))
    mag = np.hypot(gx, gy)
    k = np.minimum(1.0, max_slope / np.maximum(mag, 1e-6))
    gx, gy = gx * k, gy * k
    N = np.dstack([-gx, -gy, np.ones_like(gx)])
    return (N / np.linalg.norm(N, axis=2, keepdims=True)).astype(np.float32)


def soft_shadow(H, light=LIGHT, samples=9, spread_deg=4.0, max_len=90):
    """Height-field shadows toward a small area light (penumbra)."""
    h, w = H.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    rng = np.random.default_rng(7)
    acc = np.zeros(H.shape, np.float32)
    az0 = np.arctan2(light[1], light[0])
    el0 = np.arcsin(light[2])
    for s in range(samples):
        az = az0 + np.radians(rng.uniform(-spread_deg, spread_deg))
        el = el0 + np.radians(rng.uniform(-spread_deg, spread_deg))
        ux, uy, rise = float(np.cos(az)), float(np.sin(az)), float(np.tan(el))
        lit = np.ones(H.shape, bool)
        for t in np.arange(1.0, max_len, 1.0):
            Hs = cv2.remap(H, (xx + ux * t).astype(np.float32), (yy + uy * t).astype(np.float32), cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
            lit &= Hs <= H + t * rise + 0.25
        acc += lit
    return acc / samples


def occlusion(H):
    """Crevice occlusion at three scales. The input is pre-smoothed and the
    result blurred so pixel-staircase corners do not print as dots."""
    Hs = cv2.GaussianBlur(H, (0, 0), 1.2)
    ao = np.zeros(H.shape, np.float32)
    for r, w in ((4, .35), (10, .4), (24, .25)):
        cav = np.clip((cv2.GaussianBlur(Hs, (0, 0), r) - Hs) / (1.6 * r), 0, 1)
        ao += w * cav
    return cv2.GaussianBlur(np.clip(1 - ao, 0, 1), (0, 0), 1.0)


def to_linear(img8):
    x = img8.astype(np.float32) / 255
    return np.where(x <= .04045, x / 12.92, ((x + .055) / 1.055) ** 2.4)


def to_srgb(lin):
    x = np.clip(lin, 0, 1)
    x = np.where(x <= .0031308, x * 12.92, 1.055 * x ** (1 / 2.4) - .055)
    return (x * 255 + .5).astype(np.uint8)


def relief_light(N, light=LIGHT, ambient=.38, clamp=(.88, 1.08), **_):
    """reliefLight = clamp((ambient + (1-ambient) N.L) / flat, lo, hi): 1.0 on
    a surface facing the viewer, so an unrelieved area keeps its exact RGB."""
    ndl = np.clip(np.tensordot(N, light, axes=([2], [0])), 0, 1)
    flat = ambient + (1 - ambient) * light[2]
    return np.clip((ambient + (1 - ambient) * ndl) / flat, *clamp)


def shade(img, H, N, shadow, ao, params):
    """finalRGB = originalRGB * reliefLight * contactShadow * occlusion, on
    display RGB as the brief specifies (and as Flutter's modulate blend does)."""
    rl = relief_light(N, **params)
    sm = 1 - params['shadow'] * (1 - shadow)
    am = np.maximum(params['ao_floor'], 1 - params['ao'] * (1 - ao))
    mul = (rl * sm * am)[..., None]
    return np.clip(img.astype(np.float32) * mul + .5, 0, 255).astype(np.uint8), rl, sm, am


def render_all(scene, only=None):
    H, planes, part_z = build_height(scene, only)
    return dict(shading_maps(H), H=H, planes=planes, part_z=part_z)


def shading_maps(H):
    # Mask edges are pixel staircases; shade a 0.8 px smoothed surface so
    # silhouettes and shadows do not alias into dotted lines.
    Hs = cv2.GaussianBlur(H, (0, 0), 0.8)
    return dict(N=normals(Hs),
                shadow=cv2.GaussianBlur(soft_shadow(Hs, LIGHT), (0, 0), 0.7),
                shadow_debug=cv2.GaussianBlur(soft_shadow(Hs, DEBUG_LIGHT, max_len=140), (0, 0), 0.7),
                ao=occlusion(Hs))


def shade_mode(img, r, mode='production'):
    params = PRODUCTION if mode == 'production' else DEBUG
    sh = r['shadow'] if mode == 'production' else r['shadow_debug']
    return shade(img, r['H'], r['N'], sh, r['ao'], params)[0]


def semantic_image(scene):
    names = scene.cluster_of_pixel()
    out = np.zeros(scene.shape + (3,), np.uint8)
    for key, rgb in COLORS.items():
        out[names == key] = rgb[::-1]
    return out


def height_viz(H, vmax=80.0):
    v = np.clip(H / vmax, 0, 1)
    return cv2.applyColorMap((v * 255).astype(np.uint8), cv2.COLORMAP_INFERNO)


def normal_viz(N):
    return ((N[..., ::-1] * .5 + .5) * 255).astype(np.uint8)


def main():
    V5.mkdir(parents=True, exist_ok=True)
    scene = Scene()
    cv2.imwrite(str(V5 / 'semantic_layers.png'), semantic_image(scene))
    r = render_all(scene)
    img = scene.img
    front = shade_mode(img, r, 'production')
    debug = shade_mode(img, r, 'debug')
    cache = V5 / 'build'
    cache.mkdir(exist_ok=True)
    cv2.imwrite(str(cache / 'relief_front.png'), front)
    cv2.imwrite(str(cache / 'relief_debug_raking.png'), debug)
    cv2.imwrite(str(cache / 'height16.png'), np.clip(r['H'] * H_SCALE, 0, 65535).astype(np.uint16))
    cv2.imwrite(str(cache / 'height_viz.png'), height_viz(r['H']))
    cv2.imwrite(str(cache / 'normals.png'), normal_viz(r['N']))
    cv2.imwrite(str(cache / 'shadow.png'), (r['shadow'] * 255).astype(np.uint8))
    cv2.imwrite(str(cache / 'ao.png'), (r['ao'] * 255).astype(np.uint8))
    (cache / 'solve.json').write_text(json.dumps({'planes': r['planes'], 'partZ': r['part_z']}, indent=1))
    print('parts', r['part_z'])
    print('height range', float(r['H'].min()), float(r['H'].max()))


if __name__ == '__main__':
    main()
