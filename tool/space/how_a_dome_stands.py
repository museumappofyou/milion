"""P08 study "How a dome stands": hand-written geometry (P09 builds generators).

Usage:
  python3.11 tool/space/how_a_dome_stands.py           # app asset + manifest
  python3.11 tool/space/how_a_dome_stands.py --bench   # P08 spike model, ~50k triangles

Inputs: the dimensions below (metres; a diagram, not a survey of a building)
and the captions and sources in `tool/space/dome_study_text.py`.
Outputs:
  assets/space/how-a-dome-stands/model.glb   closed solids, one node per part,
                                             baked AO (`_AO`), material extras
  assets/space/how-a-dome-stands/study.json  the SpacePlayer manifest
  assets/content/sources/space.json          the study's registry sources
  studio/spikes/p08/bench-50k.glb            (--bench) the same bay, denser
The plan is a square bay of side S on four corner piers. Four semicircular
arches span its sides; the pendentives are the parts of one sphere (radius
S/√2, centred at the springing level) that lie inside the square and below the
arch crowns, so they turn the square into the circle the ring and dome stand
on. The cascade adds semi-domes of the arch radius on the arches' outer faces
on column arcades; Hagia Sophia's arrangement (537) uses two of them and
walls the other two arches, the Şehzade Mosque's (1548) four.
"""
from pathlib import Path
import argparse
import json
import math
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from glb import write_glb  # noqa: E402
from solid import bake_ao, box, solid, surface, union  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/space/how-a-dome-stands'

S = 31.0                  # bay side; Hagia Sophia's dome spans about 31 m
H = S / 2
Z0 = 22.0                 # springing of the four arches
P = 6.0                   # corner pier, square
TA, D = 1.8, 4.0          # arch ring thickness and depth
R = H * math.sqrt(2)      # the pendentive sphere
ZT = Z0 + H + TA          # top of arches and pendentives: the ring sits here
RING = (H - .4, H + 1.2, .8)
ZB = ZT + RING[2]         # dome springing
DOME_IN, DOME_T = H - .2, 1.0
BAND = 4.2                # window band height
WINDOWS = 40
WINDOW_PIER = .45         # share of each bay that is pier, not window
SEMI_T, WALL_T = 1.0, 1.0
COLUMNS, COLUMN, BEAM = 5, 1.4, 1.6   # exedra arcade under each semi-dome
TYMPANUM = (Z0 - 8, 1.2)  # bottom and thickness of the walled arches (537)


def rot(points, quarter):
    """Rotate about Z by quarter × 90° (anticlockwise seen from above)."""
    a = quarter * math.pi / 2
    c, s = round(math.cos(a)), round(math.sin(a))
    x, y = points[..., 0], points[..., 1]
    return np.stack([c * x - s * y, s * x + c * y, points[..., 2]], -1)


def turned(part, quarter):
    return rot(part[0], quarter), part[1]


def pier(k):
    return box(H, H + P, H, H + P, 0, Z0, step=2 / k, name='pier')


def arch(k):
    """North arch: a semicircular ring in the plane y = H, D deep."""
    n = max(8, int(32 * k))

    def ring(rho):
        def fn(u, v):
            t = np.pi * u
            return np.stack([rho * np.cos(t), H + D * v + 0 * t, Z0 + rho * np.sin(t)], -1)
        return fn

    def radial(sign):
        def hint(p):
            d = np.stack([p[..., 0], 0 * p[..., 0], p[..., 2] - Z0], -1)
            return sign * d
        return hint

    def face(y):
        def fn(u, v):
            t, rho = np.pi * u, H + TA * v
            return np.stack([rho * np.cos(t), y + 0 * t, Z0 + rho * np.sin(t)], -1)
        return fn

    def end(sign):
        def fn(u, v):
            rho = H + TA * u
            return np.stack([sign * rho, H + D * v, Z0 + 0 * rho], -1)
        return fn

    down = lambda p: np.broadcast_to((0, 0, -1), p.shape)  # noqa: E731
    return solid(
        surface(ring(H), n, 2, radial(-1)),
        surface(ring(H + TA), n, 2, radial(1)),
        surface(face(H), n, 2, lambda p: np.broadcast_to((0, -1, 0), p.shape)),
        surface(face(H + D), n, 2, lambda p: np.broadcast_to((0, 1, 0), p.shape)),
        surface(end(1), 2, 2, down),
        surface(end(-1), 2, 2, down),
        name='arch')


def sphere_z(x, y):
    return Z0 + np.sqrt(np.maximum(R * R - x * x - y * y, 0))


def pendentive(k):
    """North-east pendentive: the sphere inside the square, under the crowns,
    filled up to the ring level ZT."""
    nu, nv, nz = max(4, int(16 * k)) // 2 * 2, max(3, int(6 * k)), 3

    def plan(u, v):
        t = u * np.pi / 2
        rmax = H / np.maximum(np.cos(t), np.sin(t))
        r = H + v * (rmax - H)
        return r * np.cos(t), r * np.sin(t)

    def bottom(u, v):
        x, y = plan(u, v)
        return np.stack([x, y, sphere_z(x, y)], -1)

    def top(u, v):
        x, y = plan(u, v)
        return np.stack([x, y, ZT + 0 * x], -1)

    def inner(u, w):
        t = u * np.pi / 2
        x, y = H * np.cos(t), H * np.sin(t)
        z0 = sphere_z(x, y)
        return np.stack([x, y, z0 + w * (ZT - z0)], -1)

    def side_x(u, w):      # x = H, θ from 0 to π/4
        y = H * np.tan(u * np.pi / 4)
        x = H + 0 * y
        z0 = sphere_z(x, y)
        return np.stack([x, y, z0 + w * (ZT - z0)], -1)

    def side_y(u, w):      # y = H, θ from π/4 to π/2
        x = H / np.tan(np.pi / 4 + u * np.pi / 4)
        y = H + 0 * x
        z0 = sphere_z(x, y)
        return np.stack([x, y, z0 + w * (ZT - z0)], -1)

    centre = np.array([0, 0, Z0])
    return solid(
        surface(bottom, nu, nv, lambda p: centre - p),
        surface(top, nu, nv, lambda p: np.broadcast_to((0, 0, 1), p.shape)),
        surface(inner, nu, nz, lambda p: -p * np.array([1, 1, 0])),
        surface(side_x, nu // 2, nz, lambda p: np.broadcast_to((1, 0, 0), p.shape)),
        surface(side_y, nu // 2, nz, lambda p: np.broadcast_to((0, 1, 0), p.shape)),
        name='pendentive')


def annulus(r0, r1, z0, z1, n, theta=(0, 2 * np.pi), name='annulus'):
    """A ring (or a sector of one) between radii r0 < r1 and heights z0 < z1."""
    a, b = theta
    full = abs(b - a - 2 * np.pi) < 1e-9
    nz = max(1, int(math.ceil((z1 - z0) / 3)))

    def cyl(r):
        return lambda u, v: np.stack([r * np.cos(a + (b - a) * u),
                                      r * np.sin(a + (b - a) * u),
                                      z0 + (z1 - z0) * v], -1)

    def flat(z):
        return lambda u, v: np.stack([(r0 + (r1 - r0) * v) * np.cos(a + (b - a) * u),
                                      (r0 + (r1 - r0) * v) * np.sin(a + (b - a) * u),
                                      z + 0 * u], -1)

    radial = lambda p: p * np.array([1, 1, 0])  # noqa: E731
    faces = [surface(cyl(r0), n, nz, lambda p: -radial(p)),
             surface(cyl(r1), n, nz, radial),
             surface(flat(z0), n, 1, lambda p: np.broadcast_to((0, 0, -1), p.shape)),
             surface(flat(z1), n, 1, lambda p: np.broadcast_to((0, 0, 1), p.shape))]
    if not full:
        for t in (a, b):
            c, s = math.cos(t), math.sin(t)
            out = np.array([s, -c, 0]) if t == a else np.array([-s, c, 0])
            faces.append(surface(
                lambda u, v, c=c, s=s: np.stack([(r0 + (r1 - r0) * u) * c,
                                                 (r0 + (r1 - r0) * u) * s,
                                                 z0 + (z1 - z0) * v], -1),
                1, nz, lambda p, out=out: np.broadcast_to(out, p.shape)))
    return solid(*faces, name=name)


def shell(centre, r0, r1, theta, phi, nt, nf, name):
    """Part of a spherical shell between radii r0 < r1 over θ (azimuth) and
    φ (elevation) ranges; closes its rims with conical/meridian faces."""
    c = np.asarray(centre, dtype=np.float64)
    (t0, t1), (f0, f1) = theta, phi
    full = abs(t1 - t0 - 2 * np.pi) < 1e-9

    def at(rho, t, f):
        return c + rho[..., None] * np.stack([np.cos(f) * np.cos(t),
                                              np.cos(f) * np.sin(t), np.sin(f)], -1)

    def sphere(rho):
        return lambda u, v: at(rho + 0 * u, t0 + (t1 - t0) * u, f0 + (f1 - f0) * v)

    def rim(f):
        return lambda u, v: at(r0 + (r1 - r0) * v, t0 + (t1 - t0) * u, f + 0 * u)

    def meridian(t):
        return lambda u, v: at(r0 + (r1 - r0) * v, t + 0 * u, f0 + (f1 - f0) * u)

    def down(f):           # outward normal of a rim at elevation f is -∂/∂φ
        return lambda p: np.stack([np.sin(f) * (p[..., 0] - c[0]),
                                   np.sin(f) * (p[..., 1] - c[1]),
                                   -np.cos(f) * np.hypot(p[..., 0] - c[0], p[..., 1] - c[1])], -1)

    radial = lambda p: p - c  # noqa: E731
    faces = [surface(sphere(r1), nt, nf, radial),
             surface(sphere(r0), nt, nf, lambda p: -radial(p))]
    if f0 > -np.pi / 2 + 1e-9:
        faces.append(surface(rim(f0), nt, 1, down(f0)))
    if f1 < np.pi / 2 - 1e-9:
        faces.append(surface(rim(f1), nt, 1, lambda p: -down(f1)(p)))
    if not full:
        for t, sign in ((t0, -1), (t1, 1)):
            n = np.array([-math.sin(t), math.cos(t), 0]) * sign
            faces.append(surface(meridian(t), nf, 1,
                                 lambda p, n=n: np.broadcast_to(n, p.shape)))
    return solid(*faces, name=name)


def window_piers(k):
    f1 = math.asin(BAND / DOME_IN)
    module = 2 * np.pi / WINDOWS
    half = module * WINDOW_PIER / 2
    return union(*[
        shell((0, 0, ZB), DOME_IN, DOME_IN + DOME_T, (i * module - half, i * module + half),
              (0, f1), 2, 3, 'window pier')
        for i in range(WINDOWS)])


def dome(k):
    f1 = math.asin(BAND / DOME_IN)
    return shell((0, 0, ZB), DOME_IN, DOME_IN + DOME_T, (0, 2 * np.pi), (f1, np.pi / 2),
                 max(16, int(80 * k)), max(4, int(16 * k)), 'dome')


def semidome(k):
    """East semi-dome: a quarter sphere on the east arch's outer face."""
    nt, nf = max(8, int(24 * k)), max(4, int(10 * k))
    c = np.array([H + D, 0, Z0])
    r0, r1 = H, H + SEMI_T

    def at(rho, t, f):
        return c + rho[..., None] * np.stack([np.cos(f) * np.cos(t),
                                              np.cos(f) * np.sin(t), np.sin(f)], -1)

    def sphere(rho):
        return lambda u, v: at(rho + 0 * u, -np.pi / 2 + np.pi * u, np.pi / 2 * v)

    def base(u, v):
        return at(r0 + (r1 - r0) * v, -np.pi / 2 + np.pi * u, 0 * u)

    def face(u, v):        # the open face in the plane x = H + D
        psi = np.pi * u
        rho = r0 + (r1 - r0) * v
        return c + np.stack([0 * u, -rho * np.cos(psi), rho * np.sin(psi)], -1)

    radial = lambda p: p - c  # noqa: E731
    return solid(
        surface(sphere(r1), nt, nf, radial),
        surface(sphere(r0), nt, nf, lambda p: -radial(p)),
        surface(base, nt, 1, lambda p: np.broadcast_to((0, 0, -1), p.shape)),
        surface(face, 2 * nf, 1, lambda p: np.broadcast_to((-1, 0, 0), p.shape)),
        name='semi-dome')


def exedra(k):
    """What carries the east semi-dome: a half-ring beam on an arcade of
    COLUMNS columns (Hagia Sophia's exedrae stand on columns, not walls)."""
    c = np.array([H + D, 0, 0])
    beam = annulus(H, H + WALL_T, Z0 - BEAM, Z0, max(8, int(24 * k)),
                   (-np.pi / 2, np.pi / 2), name='exedra beam')
    pieces = [(beam[0] + c, beam[1])]
    half = COLUMN / 2
    for i in range(COLUMNS):
        t = -np.pi / 2 + np.pi * (i + 1) / (COLUMNS + 1)
        V, F = box(H + WALL_T / 2 - half, H + WALL_T / 2 + half, -half, half, 0, Z0 - BEAM,
                   step=3 / k, name='column')
        x, y = V[:, 0] * np.cos(t) - V[:, 1] * np.sin(t), V[:, 0] * np.sin(t) + V[:, 1] * np.cos(t)
        pieces.append((np.stack([x, y, V[:, 2]], 1) + c, F))
    return union(*pieces)


def tympanum(k):
    """North arch walled up from the gallery level to the arch (Hagia Sophia)."""
    n = max(8, int(24 * k))
    zb, t = TYMPANUM
    y0, y1 = H + D / 2 - t / 2, H + D / 2 + t / 2

    def edge(u):
        a = np.pi * u
        return -H * np.cos(a), Z0 + H * np.sin(a)

    def face(y):
        def fn(u, v):
            x, zt = edge(u)
            return np.stack([x, y + 0 * u, zb + v * (zt - zb)], -1)
        return fn

    def crown(u, v):
        x, zt = edge(u)
        return np.stack([x, y0 + (y1 - y0) * v, zt], -1)

    def floor(u, v):
        x, _ = edge(u)
        return np.stack([x, y0 + (y1 - y0) * v, zb + 0 * u], -1)

    def side(sign):
        return lambda u, v: np.stack([sign * H + 0 * u, y0 + (y1 - y0) * v,
                                      zb + (Z0 - zb) * u], -1)

    const = lambda n: (lambda p: np.broadcast_to(n, p.shape))  # noqa: E731
    return solid(
        surface(face(y0), n, 4, const((0, -1, 0))),
        surface(face(y1), n, 4, const((0, 1, 0))),
        surface(crown, n, 1, lambda p: np.stack([p[..., 0], 0 * p[..., 0], p[..., 2] - Z0], -1)),
        surface(floor, n, 1, const((0, 0, -1))),
        surface(side(-1), 4, 1, const((-1, 0, 0))),
        surface(side(1), 4, 1, const((1, 0, 0))),
        name='tympanum')


# Quarter turns: north-east is 0; the generators are drawn for N (arch,
# tympanum), E (semi-dome, exedra) or NE (pier, pendentive).
CORNERS = {'ne': 0, 'nw': 1, 'sw': 2, 'se': 3}
SIDES_FROM_NORTH = {'n': 0, 'w': 1, 's': 2, 'e': 3}
SIDES_FROM_EAST = {'e': 0, 'n': 1, 'w': 2, 's': 3}


def parts(k=1.0):
    """(id, solid, material) in assembly order."""
    out = []
    p, a, pe = pier(k), arch(k), pendentive(k)
    out += [(f'pier-{c}', turned(p, q), 'marble') for c, q in CORNERS.items()]
    out += [(f'arch-{s}', turned(a, q), 'brick') for s, q in SIDES_FROM_NORTH.items()]
    out += [(f'pendentive-{c}', turned(pe, q), 'brick') for c, q in CORNERS.items()]
    out.append(('ring', annulus(*RING[:2], ZT, ZB, max(24, int(96 * k)), name='ring'), 'marble'))
    out.append(('windows', window_piers(k), 'brick'))
    out.append(('dome', dome(k), 'brick'))
    t = tympanum(k)
    out += [(f'tympanum-{s}', turned(t, SIDES_FROM_NORTH[s]), 'brick') for s in 'ns']
    sd, ex = semidome(k), exedra(k)
    for s, q in SIDES_FROM_EAST.items():
        out.append((f'semidome-{s}', turned(sd, q), 'brick'))
        out.append((f'exedra-{s}', turned(ex, q), 'brick'))
    return out


# Parts that never stand together: Hagia Sophia's walled arches and the
# Şehzade's north and south semi-domes.
APART = {'tympanum-n': {'semidome-n', 'exedra-n'}, 'tympanum-s': {'semidome-s', 'exedra-s'}}


def occluders(name, everything):
    banned = APART.get(name, set()) | {k for k, v in APART.items() if name in v}
    return [s for n, s, _ in everything if n not in banned]


def build(k=1.0):
    everything = parts(k)
    out = []
    for name, (V, F), material in everything:
        (ao,) = bake_ao([(V, F)], occluders(name, everything))
        out.append({'name': name, 'positions': V, 'faces': F, 'ao': ao,
                    'extras': {'material': material}})
    return out


# Tessellation for the app (20,144 triangles). Measured on the A52s, a lighter
# .75 (13,616) ran slower, 32-38 fps against 54-57, because the CPU governor
# settles at a lower clock under less work (studio/captures/P08/device-bench.json).
APP_DENSITY = 1.0

EXTRAS = {'milion': {'units': 'm', 'up': 'z', 'north': 'y',
                     'note': 'diagram after Choisy (1883); not a survey'}}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bench', action='store_true')
    args = parser.parse_args()
    if args.bench:
        built = build(1.79)
        path = ROOT / 'studio/spikes/p08/bench-50k.glb'
    else:
        built = build(APP_DENSITY)
        path = OUT / 'model.glb'
        import dome_study_text
        dome_study_text.write(ROOT, built)
    size = write_glb(path, built, EXTRAS)
    triangles = sum(len(p['faces']) for p in built)
    vertices = sum(len(p['positions']) for p in built)
    print(f'{path.relative_to(ROOT)}: {len(built)} parts, {triangles} triangles, '
          f'{vertices} vertices, {size} bytes')


if __name__ == '__main__':
    main()
