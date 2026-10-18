"""Building specs for the P09 kit: `studio/space/<id>.yaml` → parts.

A spec is YAML (schema 1):
  id, place            the study id and the registry place it draws
  title, description   {en, tr}
  eras                 registry era tags of what is drawn
  orientation          axis: azimuth (degrees from true north, clockwise) of
                       the model's +y, the building's main axis toward its
                       sanctuary; source and footprint ([lat, lon], …) of a
                       cited outline the axis is checked against
  grid                 named plan lines in metres, {x: {A: -6, …}, y: {1: …}}
  step                 the longest face edge (default 2 m)
  parts                [{id, kind, params, at, z, turn, material, names, merge}]
                       kind is a generator in `kit.elements`; `at` lists
                       positions ("B/2" on the grid, [x, y], [x, y, turn°] or
                       {at, z, turn, mirror}); instances form one part unless
                       `names` gives each its own; a generator's pieces
                       (a dome's '-windows') stay separate parts unless merge
  epochs, steps, reveal, choisy   as in the SpacePlayer manifest; step
                       `parts` may use shell-style patterns ("pier-*")
  dimensions           [{id, value, measure, source, quote, tolerance}]:
                       cited numbers the generated geometry must match
  sources              new source records; `shared` cites registry ones
The model frame is metres, z up, the main floor at z = 0, +y along the axis.
"""
import fnmatch
import math
from pathlib import Path

import numpy as np
import yaml

from . import elements
from .shapes import mirror_x, place, union

KEYS = {'schemaVersion', 'id', 'place', 'title', 'description', 'eras', 'honesty',
        'orientation', 'grid', 'step', 'parts', 'epochs', 'steps', 'reveal', 'choisy',
        'dimensions', 'sources', 'shared', 'materials'}
PART_KEYS = {'id', 'kind', 'params', 'at', 'z', 'turn', 'material', 'names', 'merge', 'note',
             'crease'}
# Curved masonry is tessellated coarsely; its facets meet at more than the
# SpacePlayer's 30° crease and would each draw a hairline. These pieces carry
# a 60° crease instead (rims and real corners, at 90°, keep their lines).
SMOOTH_KINDS = {'dome', 'semidome', 'pendentives', 'sail-vault', 'column', 'arch', 'squinch'}
SMOOTH_PIECES = {'-domes', '-cap', '-vaults', '-exedrae', '-arches', '-windows', '-ribs', '-roof',
                 '-gallery'}
COLUMN_KINDS = {'courtyard', 'portico', 'octagon', 'arcade'}   # their '' piece is columns
SMOOTH = 60.0
MATERIALS = {'marble', 'brick', 'lead', 'stone'}


def load(path):
    spec = yaml.safe_load(Path(path).read_text(encoding='utf-8'))
    unknown = set(spec) - KEYS
    if unknown:
        raise ValueError(f'{path}: unknown keys {sorted(unknown)}')
    if spec.get('schemaVersion') != 1:
        raise ValueError(f'{path}: schemaVersion 1 expected')
    for p in spec['parts']:
        extra = set(p) - PART_KEYS
        if extra:
            raise ValueError(f"{spec['id']}/{p['id']}: unknown keys {sorted(extra)}")
        if p['kind'] not in elements.KINDS:
            raise ValueError(f"{spec['id']}/{p['id']}: no generator {p['kind']}")
        if p.get('material', 'stone') not in MATERIALS:
            raise ValueError(f"{spec['id']}/{p['id']}: material {p['material']}")
    return spec


def resolve(spec, ref):
    """A grid reference "B/2" (or "B/2+0.5,-1" with an offset) → (x, y)."""
    grid = spec.get('grid', {})
    if isinstance(ref, str):
        base, _, offset = ref.partition('+')
        gx, gy = base.split('/')
        x, y = float(grid['x'][gx]), float(grid['y'][gy])
        if offset:
            dx, dy = (float(v) for v in offset.split(','))
            x, y = x + dx, y + dy
        return x, y
    return float(ref[0]), float(ref[1])


def instances(spec, part):
    """(x, y, z, turn radians, mirror) for each placement of a part."""
    out = []
    for item in part.get('at', [[0, 0]]):
        z, turn, mirror = part.get('z', 0.0), part.get('turn', 0.0), False
        if isinstance(item, dict):
            x, y = resolve(spec, item['at'])
            z, turn, mirror = item.get('z', z), item.get('turn', turn), item.get('mirror', False)
        elif isinstance(item, str):
            x, y = resolve(spec, item)
        else:
            x, y = resolve(spec, item)
            if len(item) > 2:
                turn = item[2]
        out.append((x, y, float(z), math.radians(turn), mirror))
    return out


def build(spec):
    """Every part of the spec: [(name, (V, F), node extras)], in spec order:
    extras carry the material and, for curved pieces, a crease angle."""
    step = spec.get('step', 2.0)
    out, names = [], set()
    for p in spec['parts']:
        params = dict(p.get('params', {}))
        params.setdefault('step', step)
        pieces = elements.KINDS[p['kind']](**params)
        if p.get('merge'):
            pieces = {'': union(*pieces.values())}
        placed = instances(spec, p)
        labels = p.get('names')
        if labels and len(labels) != len(placed):
            raise ValueError(f"{p['id']}: one name per placement")
        groups = [(f"-{labels[i]}" if labels else '', [placed[i]]) for i in range(len(placed))] \
            if labels else [('', placed)]
        for label, where in groups:
            for suffix, solid in pieces.items():
                name = p['id'] + label + suffix
                if name in names:
                    raise ValueError(f'duplicate part {name}')
                names.add(name)
                copies = [place(mirror_x(solid) if m else solid, x, y, z, t)
                          for x, y, z, t, m in where]
                extras = {'material': p.get('material', 'stone')}
                crease = p.get('crease')
                if crease is None and (p['kind'] in SMOOTH_KINDS or suffix in SMOOTH_PIECES
                                       or (suffix == '' and p['kind'] in COLUMN_KINDS)):
                    crease = SMOOTH
                if crease is not None:
                    extras['crease'] = crease
                out.append((name, union(*copies), extras))
    return out


def expand(patterns, names):
    """Step part patterns → part names, in model order, each exactly once."""
    picked = []
    for pattern in patterns:
        hits = [n for n in names if fnmatch.fnmatchcase(n, pattern)]
        if not hits:
            raise ValueError(f'no part matches {pattern}')
        picked += [h for h in hits if h not in picked]
    return picked


def components(V, F):
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]]])
    g = coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(len(V),) * 2)
    n, labels = connected_components(g, directed=False)
    return [np.unique(F[labels[F[:, 0]] == k]) for k in range(n)]


def measure(m, parts):
    """One measurement of the generated geometry (metres or a count).
    kinds: extent (along x, y or z), top, bottom, gap (from the far face of
    `from` to the near face of `to` along an axis; `split` divides one part
    into its halves at that coordinate), diameter (twice the
    nearest — inner — or farthest — outer — horizontal distance from `centre`
    among vertices within `band` metres of the parts' lowest level), crown
    (the lowest point on the axis: a dome's inside), count (solids whose
    vertical extent lies within [zmin, zmax], and is `height` tall if given)."""
    names = [n for n, _, _ in parts]
    by = {n: s for n, s, _ in parts}

    def verts(patterns):
        return np.concatenate([by[n][0] for n in expand(patterns, names)])

    axis = {'x': 0, 'y': 1, 'z': 2}
    kind = m['kind']
    if kind == 'extent':
        V = verts(m['parts'])
        a = axis[m['axis']]
        return float(V[:, a].max() - V[:, a].min())
    if kind == 'top':
        return float(verts(m['parts'])[:, 2].max()) - m.get('from', 0.0)
    if kind == 'bottom':
        return m.get('from', 0.0) - float(verts(m['parts'])[:, 2].min())
    if kind == 'gap':
        a = axis[m['axis']]
        A, B = verts(m['from']), verts(m['to'])
        if 'split' in m:     # one part on both sides: its near and far halves
            A, B = A[A[:, a] < m['split']], B[B[:, a] > m['split']]
        lo = m.get('within')
        if lo is not None:   # only vertices inside a slab of the other axes
            other = [k for k in range(3) if k != a]
            def keep(V):
                ok = np.ones(len(V), bool)
                for k, (u, v) in zip(other, lo):
                    ok &= (V[:, k] >= u) & (V[:, k] <= v)
                return V[ok]
            A, B = keep(A), keep(B)
        return float(B[:, a].min() - A[:, a].max())
    if kind == 'diameter':
        V = verts(m['parts'])
        cx, cy = m.get('centre', [0, 0])
        low = V[:, 2].min() if 'level' not in m else m['level']
        near = V[np.abs(V[:, 2] - low) <= m.get('band', .05)]
        r = np.hypot(near[:, 0] - cx, near[:, 1] - cy)
        return float(2 * (r.min() if m.get('side', 'inner') == 'inner' else r.max()))
    if kind == 'crown':      # the inside of a dome at its axis: the lowest pole
        V = verts(m['parts'])
        cx, cy = m.get('centre', [0, 0])
        pole = V[np.hypot(V[:, 0] - cx, V[:, 1] - cy) < m.get('radius', .05)]
        return float(pole[:, 2].min()) - m.get('from', 0.0)
    if kind == 'count':
        n = 0
        for name in expand(m['parts'], names):
            V, F = by[name]
            for comp in components(V, F):
                z = V[comp, 2]
                if z.min() < m.get('zmin', -1e9) - 2e-3 or z.max() > m.get('zmax', 1e9) + 2e-3:
                    continue
                if 'height' in m and abs((z.max() - z.min()) - m['height']) > 2e-2 * m['height']:
                    continue
                n += 1
        return float(n)
    raise ValueError(f'measure kind {kind}')


def check_dimensions(spec, parts):
    """[(id, measured, cited, tolerance, ok)] for every cited dimension."""
    out = []
    for d in spec.get('dimensions', []):
        got = measure(d['measure'], parts)
        tol = d.get('tolerance', .05)
        ok = abs(got - d['value']) <= tol * abs(d['value']) + 1e-9
        out.append((d['id'], got, d['value'], tol, ok))
    return out


def footprint_axis(footprint):
    """Azimuth (degrees from north, clockwise, in [0, 180)) of the long axis
    of a [lat, lon] outline, and its length and width along that axis. The
    axis is the rectilinear fit of the outline's edges (their directions
    folded into a quarter turn, each weighted by its squared length, so the
    long walls govern and apse facets do not), then whichever of the two
    perpendicular directions the outline is longer along."""
    P = np.asarray(footprint, dtype=np.float64)
    lat0 = math.radians(P[:, 0].mean())
    # Metres per degree on WGS84 at that latitude (the series in EPSG guidance).
    my = 111132.92 - 559.82 * math.cos(2 * lat0) + 1.175 * math.cos(4 * lat0)
    mx = 111412.84 * math.cos(lat0) - 93.5 * math.cos(3 * lat0)
    pts = np.stack([(P[:, 1] - P[:, 1].mean()) * mx, (P[:, 0] - P[:, 0].mean()) * my], 1)
    d = np.roll(pts, -1, axis=0) - pts
    length = np.hypot(d[:, 0], d[:, 1])
    bearing = np.arctan2(d[:, 0], d[:, 1])          # from north, clockwise
    w = length ** 2
    theta = math.atan2(np.sum(w * np.sin(4 * bearing)), np.sum(w * np.cos(4 * bearing))) / 4
    spans = []
    for t in (theta, theta + math.pi / 2):
        u = np.array([math.sin(t), math.cos(t)])     # east, north components
        a = pts @ u
        spans.append(a.max() - a.min())
    long_t = theta if spans[0] >= spans[1] else theta + math.pi / 2
    return math.degrees(long_t) % 180, max(spans), min(spans)
