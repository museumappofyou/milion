"""Closed triangle solids and baked ambient occlusion for Milion spaces.

A solid is (V, F): float64 vertices [n, 3] in metres (Z up) and int faces
[m, 3], counter-clockwise seen from outside. `solid()` welds parametric
surfaces into one, drops degenerate triangles and refuses anything that is not
closed, consistently oriented and of positive volume, because the SpacePlayer
draws section cuts (poché) from the inside faces of closed solids.
`bake_ao()` gives each vertex an occlusion value from a voxel model of all
parts; it is deterministic (fixed directions, no randomness).
"""
import numpy as np


def surface(fn, nu, nv, outward):
    """A (nu × nv)-cell grid of fn(u, v) -> (..., 3) over [0, 1]², oriented
    so that its normals agree, on balance, with outward(points) -> vectors."""
    u, v = np.meshgrid(np.linspace(0, 1, nu + 1), np.linspace(0, 1, nv + 1),
                       indexing='ij')
    V = np.asarray(fn(u, v), dtype=np.float64).reshape(-1, 3)
    i = np.arange((nu + 1) * (nv + 1)).reshape(nu + 1, nv + 1)
    a, b, c, d = i[:-1, :-1], i[1:, :-1], i[1:, 1:], i[:-1, 1:]
    F = np.concatenate([np.stack([a, b, c], -1).reshape(-1, 3),
                        np.stack([a, c, d], -1).reshape(-1, 3)])
    n = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    if np.sum(n * outward(V[F].mean(axis=1))) < 0:
        F = F[:, ::-1]
    return V, F


def weld(V, F, tol=1e-5):
    keys = np.round(V / tol).astype(np.int64)
    _, first, inverse = np.unique(keys, axis=0, return_index=True,
                                  return_inverse=True)
    inverse = inverse.reshape(-1)
    order = np.argsort(first)            # keep first-seen vertex order
    rank = np.empty_like(order)
    rank[order] = np.arange(len(order))
    V2 = V[np.sort(first)]
    F2 = rank[inverse[F]]
    a, b, c = F2[:, 0], F2[:, 1], F2[:, 2]
    area = np.linalg.norm(np.cross(V2[b] - V2[a], V2[c] - V2[a]), axis=1)
    keep = (a != b) & (b != c) & (a != c) & (area > 1e-9)
    return V2, F2[keep]


def volume(V, F):
    return float(np.einsum('ij,ij->i', V[F[:, 0]],
                           np.cross(V[F[:, 1]], V[F[:, 2]])).sum() / 6)


def check_closed(V, F, name='solid'):
    """Every directed edge once and its reverse once: closed and oriented."""
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    n = len(V)
    directed = e[:, 0] * n + e[:, 1]
    reverse = e[:, 1] * n + e[:, 0]
    unique, counts = np.unique(directed, return_counts=True)
    if (counts > 1).any():
        raise ValueError(f'{name}: {int((counts > 1).sum())} edges used twice in one direction')
    missing = ~np.isin(reverse, unique)
    if missing.any():
        raise ValueError(f'{name}: {int(missing.sum())} open edges')
    if volume(V, F) <= 0:
        raise ValueError(f'{name}: inside out')


def solid(*surfaces, name='solid'):
    V = np.concatenate([s[0] for s in surfaces])
    offsets = np.cumsum([0] + [len(s[0]) for s in surfaces[:-1]])
    F = np.concatenate([s[1] + o for s, o in zip(surfaces, offsets)])
    V, F = weld(V, F)
    check_closed(V, F, name)
    return V, F


def union(*solids):
    """Disjoint closed solids as one part (e.g. forty window piers)."""
    V = np.concatenate([s[0] for s in solids])
    offsets = np.cumsum([0] + [len(s[0]) for s in solids[:-1]])
    return V, np.concatenate([s[1] + o for s, o in zip(solids, offsets)])


def planar(origin, du, dv, nu, nv, normal):
    o, du, dv = (np.asarray(x, dtype=np.float64) for x in (origin, du, dv))
    return surface(lambda u, v: o + u[..., None] * du + v[..., None] * dv,
                   nu, nv, lambda p: np.broadcast_to(normal, p.shape))


def box(x0, x1, y0, y1, z0, z1, step=2.0, name='box'):
    def n(length):
        return max(1, int(np.ceil(length / step)))
    sx, sy, sz = x1 - x0, y1 - y0, z1 - z0
    return solid(
        planar((x0, y0, z0), (sx, 0, 0), (0, sy, 0), n(sx), n(sy), (0, 0, -1)),
        planar((x0, y0, z1), (sx, 0, 0), (0, sy, 0), n(sx), n(sy), (0, 0, 1)),
        planar((x0, y0, z0), (sx, 0, 0), (0, 0, sz), n(sx), n(sz), (0, -1, 0)),
        planar((x0, y1, z0), (sx, 0, 0), (0, 0, sz), n(sx), n(sz), (0, 1, 0)),
        planar((x0, y0, z0), (0, sy, 0), (0, 0, sz), n(sy), n(sz), (-1, 0, 0)),
        planar((x1, y0, z0), (0, sy, 0), (0, 0, sz), n(sy), n(sz), (1, 0, 0)),
        name=name)


def vertex_normals(V, F):
    n = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    out = np.zeros_like(V)
    for k in range(3):
        np.add.at(out, F[:, k], n)
    length = np.linalg.norm(out, axis=1, keepdims=True)
    return out / np.where(length > 0, length, 1)


def _hemisphere(count):
    """Cosine-weighted Fibonacci directions around +Z."""
    k = np.arange(count) + .5
    r = np.sqrt(k / count)
    phi = k * np.pi * (3 - np.sqrt(5))
    return np.stack([r * np.cos(phi), r * np.sin(phi), np.sqrt(1 - r * r)], 1)


def bake_ao(parts, occluders, voxel=.5, directions=32, reach=9.0):
    """AO per vertex of each part in `parts`, occluded by the solids in
    `occluders` (lists of (V, F)). Returns one float32 array per part, 1 = open.
    """
    V = np.concatenate([o[0] for o in occluders])
    lo = V.min(axis=0) - reach - voxel
    hi = V.max(axis=0) + reach + voxel
    shape = np.ceil((hi - lo) / voxel).astype(int) + 1
    grid = np.zeros(shape, dtype=bool)
    for ov, of in occluders:       # surface voxels from dense barycentric samples
        tri = ov[of]
        edge = np.max(np.linalg.norm(tri - np.roll(tri, 1, axis=1), axis=2), axis=1)
        steps = np.maximum(1, np.ceil(edge / (voxel * .5))).astype(int)
        for s in np.unique(steps):
            t = tri[steps == s]
            i, j = np.meshgrid(np.arange(s + 1), np.arange(s + 1), indexing='ij')
            keep = (i + j) <= s
            a, b = (i[keep] / s)[None, :, None], (j[keep] / s)[None, :, None]
            p = t[:, None, 0] * (1 - a - b) + t[:, None, 1] * a + t[:, None, 2] * b
            idx = np.floor((p.reshape(-1, 3) - lo) / voxel).astype(int)
            grid[idx[:, 0], idx[:, 1], idx[:, 2]] = True
    base = _hemisphere(directions)
    marches = np.arange(1, int(reach / (voxel * .75)) + 1) * voxel * .75
    out = []
    for pv, pf in parts:
        normals = vertex_normals(pv, pf)
        ao = np.empty(len(pv), dtype=np.float32)
        for start in range(0, len(pv), 1024):
            n = normals[start:start + 1024]
            p = pv[start:start + 1024] + n * voxel * 1.5
            helper = np.where(np.abs(n[:, 2:3]) < .9, [[0, 0, 1]], [[1, 0, 0]])
            t1 = np.cross(helper, n)
            t1 /= np.linalg.norm(t1, axis=1, keepdims=True)
            t2 = np.cross(n, t1)
            d = (base[None, :, 0:1] * t1[:, None] + base[None, :, 1:2] * t2[:, None]
                 + base[None, :, 2:3] * n[:, None])          # [v, dirs, 3]
            hit = np.full(d.shape[:2], np.inf)
            for m in marches:
                q = np.floor((p[:, None] + d * m - lo) / voxel).astype(int)
                occupied = grid[q[..., 0], q[..., 1], q[..., 2]]
                hit = np.where(occupied & np.isinf(hit), m, hit)
            weight = np.where(np.isinf(hit), 0, 1 - hit / (reach * 1.15))
            ao[start:start + 1024] = 1 - weight.mean(axis=1)
        out.append(np.round(ao, 4).astype(np.float32))
    return out
