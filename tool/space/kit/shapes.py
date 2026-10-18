"""Closed solids for the P09 kit, built on `tool/space/solid.py`.

Every function returns (V, F): float64 vertices [n, 3] in metres (Z up) and
int faces [m, 3], counter-clockwise seen from outside, closed and of positive
volume (`finish` refuses anything else). Vertices are snapped to the
2^-10 m grid (about 1 mm) that `meshopt.exponential` stores exactly, so a
decoded model equals the generated one bit for bit.

`step` is the longest face edge wanted, in metres: the SpacePlayer's painter's
sort slivers on large faces that meet small ones (PHASES, P09 notes).
"""
import math

import numpy as np

from meshopt import quantise
from solid import check_closed, volume

GRID = -10                   # vertices on the 2^-10 m grid
TAU = 2 * math.pi


def finish(V, F, name):
    """Snap, weld identical vertices, drop collapsed triangles, orient
    outward and refuse anything that is not one closed solid (or several
    disjoint ones)."""
    V = quantise(np.asarray(V, dtype=np.float64).reshape(-1, 3), GRID)
    F = np.asarray(F, dtype=np.int64).reshape(-1, 3)
    keys = np.rint(np.ldexp(V, -GRID)).astype(np.int64)
    _, first, inverse = np.unique(keys, axis=0, return_index=True, return_inverse=True)
    inverse = inverse.reshape(-1)
    order = np.argsort(first)
    rank = np.empty_like(order)
    rank[order] = np.arange(len(order))
    V = V[np.sort(first)]
    F = rank[inverse[F]]
    a, b, c = F[:, 0], F[:, 1], F[:, 2]
    area = np.linalg.norm(np.cross(V[b] - V[a], V[c] - V[a]), axis=1)
    F = F[(a != b) & (b != c) & (a != c) & (area > 1e-9)]
    if volume(V, F) < 0:
        F = F[:, ::-1]
    used = np.unique(F)
    remap = np.full(len(V), -1)
    remap[used] = np.arange(len(used))
    V, F = V[used], remap[F]
    check_closed(V, F, name)
    return V, F


def union(*solids):
    """Disjoint closed solids as one part."""
    solids = [s for s in solids if s is not None]
    V = np.concatenate([s[0] for s in solids])
    offsets = np.cumsum([0] + [len(s[0]) for s in solids[:-1]])
    return V, np.concatenate([s[1] + o for s, o in zip(solids, offsets)])


def place(solid, x=0.0, y=0.0, z=0.0, turn=0.0):
    """Rotate about Z by `turn` radians (anticlockwise from above), then move."""
    V, F = solid
    c, s = math.cos(turn), math.sin(turn)
    W = np.stack([c * V[:, 0] - s * V[:, 1] + x, s * V[:, 0] + c * V[:, 1] + y,
                  V[:, 2] + z], 1)
    return quantise(W, GRID), F


def mirror_x(solid):
    V, F = solid
    return V * [-1, 1, 1], F[:, ::-1]


def subdivide(points, step, closed=True):
    """Insert points so no segment of the polyline is longer than `step`."""
    P = [np.asarray(p, dtype=np.float64) for p in points]
    out = []
    n = len(P) if closed else len(P) - 1
    for i in range(n):
        a, b = P[i], P[(i + 1) % len(P)]
        k = max(1, int(math.ceil(np.linalg.norm(b - a) / step - 1e-9)))
        out += [a + (b - a) * j / k for j in range(k)]
    if not closed:
        out.append(P[-1])
    return np.array(out)


def ear_clip(poly):
    """Triangulate a simple polygon (2D, anticlockwise) by ear clipping."""
    P = np.asarray(poly, dtype=np.float64)
    idx = list(range(len(P)))
    out = []

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    guard = 0
    while len(idx) > 3 and guard < 10 * len(P) ** 2:
        guard += 1
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = P[i0], P[i1], P[i2]
            if cross(a, b, c) <= 1e-12:
                continue
            inside = False
            for j in idx:
                if j in (i0, i1, i2):
                    continue
                p = P[j]
                if cross(a, b, p) >= -1e-12 and cross(b, c, p) >= -1e-12 and cross(c, a, p) >= -1e-12:
                    inside = True
                    break
            if not inside:
                out.append((i0, i1, i2))
                idx.pop(k)
                break
        else:
            raise ValueError('ear_clip: not a simple anticlockwise polygon')
    out.append(tuple(idx))
    return np.array(out, dtype=np.int64)


def signed_area(poly):
    P = np.asarray(poly)
    return .5 * float(np.sum(P[:, 0] * np.roll(P[:, 1], -1) - np.roll(P[:, 0], -1) * P[:, 1]))


def _cap(boundary, step):
    """Faces filling a closed 2D boundary (anticlockwise). Star-shaped
    boundaries get rings scaled toward the centroid, so no face is much
    longer than `step`; others are ear-clipped. Returns (points2d, faces)
    with the boundary first, in order."""
    B = np.asarray(boundary, dtype=np.float64)
    c = B.mean(axis=0)
    star = all(((B[i] - c)[0] * (B[(i + 1) % len(B)] - c)[1]
                - (B[i] - c)[1] * (B[(i + 1) % len(B)] - c)[0]) > 1e-9
               for i in range(len(B)))
    if not star:
        return B, ear_clip(B)
    reach = np.linalg.norm(B - c, axis=1).max()
    rings = max(1, int(math.ceil(reach / step)))
    n = len(B)
    pts = [B]
    for r in range(1, rings):
        pts.append(c + (B - c) * (1 - r / rings))
    pts.append(c[None])
    P = np.concatenate(pts)
    F = []
    for r in range(rings - 1):
        o0, o1 = r * n, (r + 1) * n
        for i in range(n):
            j = (i + 1) % n
            F += [(o0 + i, o0 + j, o1 + j), (o0 + i, o1 + j, o1 + i)]
    o, centre = (rings - 1) * n, rings * n
    for i in range(n):
        F.append((o + i, o + (i + 1) % n, centre))
    return P, np.array(F, dtype=np.int64)


def loft(rings, step=2.0, name='loft'):
    """A solid through horizontal rings [(polygon2d, z), ...] of the same
    point count (anticlockwise seen from above, bottom to top), with rings
    added between ones more than `step` apart. A ring of identical points is
    an apex; other end rings are capped."""
    seq = []
    for poly, z in rings:
        P = np.asarray(poly, dtype=np.float64)
        if seq:
            Q, zq = seq[-1]
            if len(P) != len(Q):
                raise ValueError(f'{name}: rings must have the same point count')
            extra = max(1, int(math.ceil(abs(z - zq) / step - 1e-9))) - 1
            for e in range(extra):
                t = (e + 1) / (extra + 1)
                seq.append((Q + (P - Q) * t, zq + (z - zq) * t))
        seq.append((P, z))
    m = len(seq[0][0])
    V = [(x, y, z) for P, z in seq for x, y in P]
    F = []
    for r in range(len(seq) - 1):
        for i in range(m):
            j = (i + 1) % m
            a, b, c, d = r * m + i, r * m + j, (r + 1) * m + j, (r + 1) * m + i
            F += [(a, b, c), (a, c, d)]
    for r, top in ((0, False), (len(seq) - 1, True)):
        P, z = seq[r]
        if np.allclose(P, P[0]):
            continue
        P2, F2 = _cap(P, step)
        index = np.concatenate([r * m + np.arange(m), len(V) + np.arange(len(P2) - m)])
        V += [(x, y, z) for x, y in P2[m:]]
        F += [tuple(t) if top else tuple(t[::-1]) for t in index[F2]]
    return finish(np.asarray(V), np.asarray(F), name)


def prism(poly, z0, z1, step=2.0, name='prism'):
    """A vertical prism on an anticlockwise polygon, its sides subdivided."""
    P = np.asarray(poly, dtype=np.float64)
    if signed_area(P) < 0:
        P = P[::-1]
    B = subdivide(P, step)
    return loft([(B, z0), (B, z1)], step, name)


def regular(n, r, phase=0.0, cx=0.0, cy=0.0):
    t = phase + TAU * np.arange(n) / n
    return np.stack([cx + r * np.cos(t), cy + r * np.sin(t)], 1)


def rect(cx, cy, w, d, turn=0.0):
    c, s = math.cos(turn), math.sin(turn)
    pts = np.array([(-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2)])
    return np.stack([cx + c * pts[:, 0] - s * pts[:, 1], cy + s * pts[:, 0] + c * pts[:, 1]], 1)


def block(x0, x1, y0, y1, z0, z1, step=2.0, name='block'):
    """An axis-aligned box with every face gridded to `step`."""
    def n(length):
        return max(1, int(math.ceil(length / step - 1e-9)))
    xs = np.linspace(x0, x1, n(x1 - x0) + 1)
    ys = np.linspace(y0, y1, n(y1 - y0) + 1)
    zs = np.linspace(z0, z1, n(z1 - z0) + 1)
    V, F = [], []

    def grid(points, flip):
        base = len(V)
        rows, cols = points.shape[:2]
        V.extend(points.reshape(-1, 3))
        for i in range(rows - 1):
            for j in range(cols - 1):
                a, b = base + i * cols + j, base + (i + 1) * cols + j
                c, d = b + 1, a + 1
                F.extend([(a, b, c), (a, c, d)] if not flip else [(a, c, b), (a, d, c)])

    X, Y = np.meshgrid(xs, ys, indexing='ij')
    for z, flip in ((z0, True), (z1, False)):
        grid(np.stack([X, Y, np.full_like(X, z)], -1), flip)
    X, Z = np.meshgrid(xs, zs, indexing='ij')
    for y, flip in ((y0, False), (y1, True)):
        grid(np.stack([X, np.full_like(X, y), Z], -1), flip)
    Y, Z = np.meshgrid(ys, zs, indexing='ij')
    for x, flip in ((x0, True), (x1, False)):
        grid(np.stack([np.full_like(Y, x), Y, Z], -1), flip)
    return finish(np.asarray(V), np.asarray(F), name)


def revolve(profile, n, step=2.0, arc=None, name='revolve'):
    """Solid of revolution about Z of a closed (r, z) profile (r ≥ 0; points
    on the axis close it). `n` segments per full turn; `arc` = (a0, a1)
    revolves part of a turn and caps both ends."""
    P = subdivide(profile, step)
    if signed_area(P) < 0:
        P = P[::-1]
    full = arc is None
    a0, a1 = (0.0, TAU) if full else arc
    k = n if full else max(1, int(math.ceil(n * (a1 - a0) / TAU)))
    angles = a0 + (a1 - a0) * np.arange(k + (0 if full else 1)) / k
    cols = len(angles)
    V = np.array([(r * math.cos(t), r * math.sin(t), z) for r, z in P for t in angles])
    F = []
    rows = len(P)
    for i in range(rows):
        i2 = (i + 1) % rows
        for j in range(cols if full else cols - 1):
            j2 = (j + 1) % cols
            a, b, c, d = i * cols + j, i2 * cols + j, i2 * cols + j2, i * cols + j2
            F += [(a, b, c), (a, c, d)]
    V = list(map(tuple, V))
    if full:
        return finish(np.asarray(V), np.asarray(F), name)
    tri = ear_clip(P)
    for j in (0, cols - 1):
        F += [(t[0] * cols + j, t[1] * cols + j, t[2] * cols + j) for t in tri]
    return _orient_pieces(np.asarray(V), F, name)


def strip(inner, outer, y0, y1, name='strip'):
    """Extrude the band between two matching (x, z) polylines along y from
    y0 to y1 (an arch ring, a tympanum): inner and outer have the same point
    count and run the same way; the ends are joined straight."""
    I, O = np.asarray(inner, float), np.asarray(outer, float)
    n = len(I)
    V = []
    for y in (y0, y1):
        V += [(p[0], y, p[1]) for p in I] + [(p[0], y, p[1]) for p in O]
    F = []

    def idx(face, ring, i):
        return face * 2 * n + ring * n + i

    for i in range(n - 1):
        for ring in (0, 1):
            a, b = idx(0, ring, i), idx(0, ring, i + 1)
            c, d = idx(1, ring, i + 1), idx(1, ring, i)
            F += [(a, b, c), (a, c, d)]
        for face in (0, 1):
            a, b = idx(face, 0, i), idx(face, 0, i + 1)
            c, d = idx(face, 1, i + 1), idx(face, 1, i)
            F += [(a, b, c), (a, c, d)]
    for i in (0, n - 1):
        a, b, c, d = idx(0, 0, i), idx(0, 1, i), idx(1, 1, i), idx(1, 0, i)
        F += [(a, b, c), (a, c, d)]
    # Orientation is fixed by `finish`; a band only needs consistent winding,
    # which alternates between the two rings and faces, so orient per piece.
    return _orient_pieces(np.asarray(V), F, name)


def _orient_pieces(V, F, name):
    """Make every face of a closed mesh agree with its neighbours (breadth
    first over shared edges), then let `finish` turn it outward."""
    F = [list(f) for f in F]
    edges = {}
    for t, f in enumerate(F):
        for k in range(3):
            a, b = f[k], f[(k + 1) % 3]
            edges.setdefault((min(a, b), max(a, b)), []).append(t)
    seen = [False] * len(F)
    for start in range(len(F)):
        if seen[start]:
            continue
        seen[start] = True
        queue, piece = [start], [start]
        while queue:
            t = queue.pop()
            f = F[t]
            for k in range(3):
                a, b = f[k], f[(k + 1) % 3]
                for u in edges[(min(a, b), max(a, b))]:
                    if u == t or seen[u]:
                        continue
                    g = F[u]
                    same = any(g[q] == a and g[(q + 1) % 3] == b for q in range(3))
                    if same:
                        F[u] = g[::-1]
                    seen[u] = True
                    queue.append(u)
                    piece.append(u)
        if volume(V, np.asarray([F[t] for t in piece])) < 0:
            for t in piece:
                F[t] = F[t][::-1]
    return finish(V, np.asarray(F), name)


def arc_points(cx, cz, r, a0, a1, n):
    t = np.linspace(a0, a1, n + 1)
    return np.stack([cx + r * np.cos(t), cz + r * np.sin(t)], 1)


def arch_curve(span, kind='round', rise=None, n=16, offset=0.0, pointed=1 / 3):
    """Intrados (offset 0) or a parallel curve of an arch over x ∈ [−s/2,
    s/2], springing at z = 0, from the left springing to the right one.
    kind: round (semicircle), pointed (two-centred, centres `pointed` × span
    apart from the middle... as a share of the half-span) or segmental (rise)."""
    h = span / 2
    if kind == 'round':
        return arc_points(0, 0, h + offset, math.pi, 0, n)
    if kind == 'segmental':
        rise = rise or span / 4
        R = (h * h + rise * rise) / (2 * rise)
        a = math.asin(h / R)
        return arc_points(0, rise - R, R + offset, math.pi / 2 + a, math.pi / 2 - a, n)
    if kind == 'pointed':
        e = pointed * h                 # each centre sits e from the middle
        R = h + e + offset
        top = math.acos(e / R)          # the apex, seen from either centre
        half = max(2, n // 2)
        left = arc_points(e, 0, R, math.pi, math.pi - top, half)
        right = arc_points(-e, 0, R, top, 0, half)
        return np.concatenate([left, right[1:]])
    raise ValueError(f'arch kind {kind}')


def arch(span, thickness, depth, kind='round', n=16, rise=None, name='arch'):
    """An arch ring over x ∈ [−s/2, s/2], springing at z = 0, from y = 0 to
    y = depth."""
    inner = arch_curve(span, kind, rise, n)
    outer = arch_curve(span, kind, rise, n, offset=thickness)
    return strip(inner, outer, 0, depth, name)


def shell(centre, r0, r1, theta, phi, nt, nf, name='shell', radius=None):
    """Part of a spherical shell between radii r0 < r1 over azimuth θ and
    elevation φ ranges, rims closed. `radius(θ, φ)` scales both radii (a
    melon dome's gores); it must be 1 at the crown."""
    c = np.asarray(centre, dtype=np.float64)
    (t0, t1), (f0, f1) = theta, phi
    full = abs(t1 - t0 - TAU) < 1e-9
    ts = t0 + (t1 - t0) * np.arange(nt + (0 if full else 1)) / nt
    fs = f0 + (f1 - f0) * np.arange(nf + 1) / nf
    cols = len(ts)

    def at(rho, t, f):
        s = 1.0 if radius is None else radius(t, f)
        return c + rho * s * np.array([math.cos(f) * math.cos(t), math.cos(f) * math.sin(t), math.sin(f)])

    V, F = [], []
    for rho in (r1, r0):
        for f in fs:
            for t in ts:
                V.append(at(rho, t, f))
    rows = len(fs)

    def vid(layer, i, j):
        return layer * rows * cols + i * cols + (j % cols)

    span = cols if full else cols - 1
    for layer in (0, 1):
        for i in range(rows - 1):
            for j in range(span):
                a, b, cc, d = vid(layer, i, j), vid(layer, i, j + 1), vid(layer, i + 1, j + 1), vid(layer, i + 1, j)
                F += [(a, b, cc), (a, cc, d)] if layer == 0 else [(a, cc, b), (a, d, cc)]
    for i, top in ((0, False), (rows - 1, True)):
        if abs(fs[i]) >= math.pi / 2 - 1e-9:
            continue
        for j in range(span):
            a, b, cc, d = vid(0, i, j), vid(0, i, j + 1), vid(1, i, j + 1), vid(1, i, j)
            F += [(a, cc, b), (a, d, cc)] if not top else [(a, b, cc), (a, cc, d)]
    if not full:
        for j, end in ((0, False), (cols - 1, True)):
            for i in range(rows - 1):
                a, b, cc, d = vid(0, i, j), vid(0, i + 1, j), vid(1, i + 1, j), vid(1, i, j)
                F += [(a, b, cc), (a, cc, d)] if not end else [(a, cc, b), (a, d, cc)]
    return _orient_pieces(np.asarray(V), F, name)


def band(outer, inner, z0, z1, step=2.0, name='band'):
    """A closed ring between two horizontal loops of the same point count
    (outer around inner, both anticlockwise): a cornice ring, an octagon
    turning into a circle. Faces higher than `step` are split."""
    O, I = np.asarray(outer, float), np.asarray(inner, float)
    n = len(O)
    rows = max(1, int(math.ceil((z1 - z0) / step - 1e-9)))
    zs = np.linspace(z0, z1, rows + 1)
    V = [(p[0], p[1], z) for z in zs for p in O] + [(p[0], p[1], z) for z in zs for p in I]
    F = []
    inner0 = (rows + 1) * n
    for r in range(rows):
        for i in range(n):
            j = (i + 1) % n
            a, b, c, d = r * n + i, r * n + j, (r + 1) * n + j, (r + 1) * n + i
            F += [(a, b, c), (a, c, d)]
            a, b, c, d = (inner0 + r * n + i, inner0 + r * n + j,
                          inner0 + (r + 1) * n + j, inner0 + (r + 1) * n + i)
            F += [(a, c, b), (a, d, c)]
    for z_row, top in ((0, False), (rows, True)):
        for i in range(n):
            j = (i + 1) % n
            a, b = z_row * n + i, z_row * n + j
            c, d = inner0 + z_row * n + j, inner0 + z_row * n + i
            F += [(a, c, b), (a, d, c)] if top else [(a, b, c), (a, c, d)]
    return _orient_pieces(np.asarray(V), F, name)


def polygon_at(angles, sides=0, radius=1.0, phase=0.0):
    """Points at the given angles on a circle (sides = 0) or on a regular
    polygon of `sides` with circumradius `radius` and a corner at `phase`."""
    a = np.asarray(angles, dtype=np.float64)
    if not sides:
        r = np.full_like(a, radius)
    else:
        w = TAU / sides
        local = (a - phase) % w - w / 2          # angle from the face centre
        r = radius * math.cos(w / 2) / np.cos(local)
    return np.stack([r * np.cos(a), r * np.sin(a)], 1)
