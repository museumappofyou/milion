"""Stage (e) adaptive mesh with triangle-flip and tear validation.

Input: `height` (HxW, 0..1) and the vertex budget (<= 60,000). Output: a
Delaunay mesh in plate uv space (float32 Nx3: u, v, height; uint32 Mx3
counter-clockwise triangles) and a validation record.

Refinement is a quadtree: a cell splits while its height range exceeds a
tolerance, so relief edges get small triangles and flat gold ground large
ones; the tolerance halves until the next halving would exceed the budget.
Delaunay over the cell corners is conforming, so there are no T-junctions.
A displaced triangle folds when P(|dz/du| + |dz/dv|) >= 1 (P = parallax), so
sharp relief edges are relaxed: vertices of folding triangles ease towards
their triangle's mean height until none folds; the record says how far.
Validation fails the build on: more vertices than the budget, degenerate or
clockwise (flipped) triangles, flips after the largest parallax the player
applies (tilt +/-1 x depth 0.025, as shaders/plate.frag), non-manifold edges,
an open boundary that is not one loop, Euler characteristic != 1, or uv area
!= 1 (a tear or overlap).
"""
import numpy as np
from scipy.spatial import Delaunay

PARALLAX = .025


def _corners(height, tol, min_cell):
    h, w = height.shape
    pts = set()
    stack = [(0, 0, w - 1, h - 1)]
    while stack:
        x0, y0, x1, y1 = stack.pop()
        cell = height[y0:y1 + 1, x0:x1 + 1]
        if (x1 - x0 > min_cell and y1 - y0 > min_cell and float(cell.max() - cell.min()) > tol):
            mx, my = (x0 + x1) // 2, (y0 + y1) // 2
            stack += [(x0, y0, mx, my), (mx, y0, x1, my), (x0, my, mx, y1), (mx, my, x1, y1)]
        else:
            pts.update({(x0, y0), (x1, y0), (x0, y1), (x1, y1)})
    return np.array(sorted(pts), np.float64)


def build(height, max_vertices=60000, min_cell=4):
    if max_vertices > 60000:
        raise SystemExit('mesh budget is at most 60k vertices')
    h, w = height.shape
    tol, pts = .5, None
    while tol > 1e-3:
        candidate = _corners(height, tol, min_cell)
        if len(candidate) > max_vertices:
            break
        pts, tol = candidate, tol / 2
    if pts is None:
        raise SystemExit('cannot mesh within the vertex budget')
    tri = Delaunay(pts).simplices.astype(np.int64)
    uv = pts / [w - 1, h - 1]
    z = height[pts[:, 1].astype(int), pts[:, 0].astype(int)]
    a = _areas(uv, tri)
    tri[a < 0] = tri[a < 0][:, [0, 2, 1]]  # one consistent winding (positive area)
    keep = np.abs(a) > 1e-12
    tri = tri[keep]
    z, relaxed = _relax(uv, tri, z.astype(np.float64))
    vertices = np.c_[uv, z].astype(np.float32)
    record = validate(vertices, tri, max_vertices)
    record['relaxation'] = relaxed
    return vertices, tri.astype(np.uint32), record


TILTS = [(1, 1), (1, -1), (-1, 1), (-1, -1)]


def _folding(uv, tri, z):
    bad = np.zeros(len(tri), bool)
    for tx, ty in TILTS:
        moved = uv + np.c_[tx * (z - .5), ty * (z - .5)] * PARALLAX
        bad |= _areas(moved, tri) <= 0
    return bad


def _relax(uv, tri, z, iterations=400):
    original = z.copy()
    for i in range(iterations):
        bad = _folding(uv, tri, z)
        if not bad.any():
            break
        t = tri[bad]
        mean = z[t].mean(axis=1)
        total = np.zeros_like(z)
        count = np.zeros_like(z)
        np.add.at(total, t.reshape(-1), np.repeat(mean, 3))
        np.add.at(count, t.reshape(-1), 1)
        moved = count > 0
        z[moved] = .5 * z[moved] + .5 * total[moved] / count[moved]
    changed = np.abs(z - original) > 1e-6
    return z, dict(iterations=i + 1 if iterations else 0, verticesEased=int(changed.sum()),
                   maxHeightChange=round(float(np.abs(z - original).max()), 4))


def _areas(uv, tri):
    p0, p1, p2 = uv[tri[:, 0]], uv[tri[:, 1]], uv[tri[:, 2]]
    return .5 * ((p1[:, 0] - p0[:, 0]) * (p2[:, 1] - p0[:, 1]) - (p2[:, 0] - p0[:, 0]) * (p1[:, 1] - p0[:, 1]))


def validate(vertices, tri, max_vertices):
    tri = np.asarray(tri, np.int64)
    uv, z = vertices[:, :2].astype(np.float64), vertices[:, 2].astype(np.float64)
    areas = _areas(uv, tri)
    flips_rest = int((areas <= 0).sum())
    flips_tilt = 0
    for tx, ty in TILTS:
        moved = uv + np.c_[tx * (z - .5), ty * (z - .5)] * PARALLAX
        flips_tilt = max(flips_tilt, int((_areas(moved, tri) <= 0).sum()))
    edges = np.sort(np.r_[tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]], axis=1)
    unique, counts = np.unique(edges, axis=0, return_counts=True)
    boundary = unique[counts == 1]
    nonmanifold = int((counts > 2).sum())
    # The boundary must be a single closed loop: every boundary vertex has degree 2
    # and walking from one vertex returns to it after visiting them all.
    loops, degree_ok = 0, True
    if len(boundary):
        adj = {}
        for a_, b_ in boundary:
            adj.setdefault(int(a_), []).append(int(b_))
            adj.setdefault(int(b_), []).append(int(a_))
        degree_ok = all(len(v) == 2 for v in adj.values())
        seen = set()
        for start in adj:
            if start in seen:
                continue
            loops += 1
            prev, cur = None, start
            while cur not in seen:
                seen.add(cur)
                nxt = [n for n in adj[cur] if n != prev]
                prev, cur = cur, (nxt[0] if nxt else cur)
    used = np.unique(tri)
    euler = len(used) - len(unique) + len(tri)
    area = float(areas.sum())
    record = dict(vertices=int(len(vertices)), triangles=int(len(tri)), budget=max_vertices,
                  flippedAtRest=flips_rest, flippedAtMaxTilt=flips_tilt,
                  nonManifoldEdges=nonmanifold, boundaryLoops=loops, euler=int(euler),
                  uvArea=round(area, 6), unusedVertices=int(len(vertices) - len(used)))
    problems = []
    if len(vertices) > max_vertices:
        problems.append('over the vertex budget')
    if flips_rest or flips_tilt:
        problems.append('flipped triangles')
    if nonmanifold or loops != 1 or not degree_ok or euler != 1:
        problems.append('tear or non-manifold topology')
    if abs(area - 1) > 1e-4:
        problems.append('uv coverage is not the unit square')
    record['valid'] = not problems
    record['problems'] = problems
    return record
