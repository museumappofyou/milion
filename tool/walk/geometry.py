"""Prototype meshes for an immersive walk (P14): a column, a groin-vault bay,
walls, a walkway, water, fish, carved bases. Every function returns a Mesh
whose vertex colours carry the baked light, because the walk draws with
unlit materials (one multiply per pixel on the A52s's OpenGL ES).

Frame: metres, glTF's y up; x along the cistern's length, z across it.
"""
from dataclasses import dataclass, field
import math

import numpy as np


@dataclass
class Mesh:
    positions: list = field(default_factory=list)
    normals: list = field(default_factory=list)
    colours: list = field(default_factory=list)
    uvs: list = field(default_factory=list)
    faces: list = field(default_factory=list)

    def vertex(self, p, n, c, uv=(0.0, 0.0)):
        self.positions.append(tuple(float(v) for v in p))
        self.normals.append(tuple(float(v) for v in _unit(n)))
        self.colours.append(tuple(float(min(1.0, max(0.0, v))) for v in c))
        self.uvs.append(tuple(float(v) for v in uv))
        return len(self.positions) - 1

    def tri(self, a, b, c):
        self.faces.append((a, b, c))

    def quad(self, a, b, c, d):
        """Counter-clockwise a, b, c, d seen from the front."""
        self.faces.append((a, b, c))
        self.faces.append((a, c, d))

    def extend(self, other):
        base = len(self.positions)
        self.positions += other.positions
        self.normals += other.normals
        self.colours += other.colours
        self.uvs += other.uvs
        self.faces += [(a + base, b + base, c + base) for a, b, c in other.faces]
        return self

    @property
    def triangles(self):
        return len(self.faces)

    def orient(self):
        """Wind every triangle counter-clockwise around the mean of its
        vertex normals (glTF's front face), so back-face culling on the
        GPU keeps the side the light was baked for. Returns how many it
        turned."""
        turned = 0
        out = []
        for a, b, c in self.faces:
            pa, pb, pc = (np.array(self.positions[i]) for i in (a, b, c))
            geometric = np.cross(pb - pa, pc - pa)
            shading = np.add(np.add(self.normals[a], self.normals[b]), self.normals[c])
            if float(np.dot(geometric, shading)) < 0:
                out.append((a, c, b))
                turned += 1
            else:
                out.append((a, b, c))
        self.faces = out
        return turned

    def mirrored(self, plane_y, dim):
        """The reflection across y = plane_y, darkened by `dim` (rgb factor);
        winding reversed so the mirrored faces still face out."""
        m = Mesh()
        for p, n, c, uv in zip(self.positions, self.normals, self.colours, self.uvs):
            m.vertex((p[0], 2 * plane_y - p[1], p[2]), (n[0], -n[1], n[2]),
                     (c[0] * dim[0], c[1] * dim[1], c[2] * dim[2]), uv)
        m.faces = [(a, c, b) for a, b, c in self.faces]
        return m

    def transformed(self, matrix):
        m = Mesh()
        r = np.asarray(matrix, dtype=np.float64)
        for p, n, c, uv in zip(self.positions, self.normals, self.colours, self.uvs):
            q = r @ np.array([p[0], p[1], p[2], 1.0])
            k = r[:3, :3] @ np.array(n)
            m.vertex(q[:3], k, c, uv)
        m.faces = list(self.faces)
        return m


def _unit(v):
    v = np.asarray(v, dtype=np.float64)
    length = float(np.linalg.norm(v))
    return v / length if length > 1e-12 else np.array([0.0, 1.0, 0.0])


@dataclass
class Light:
    """Baked lighting: one uplight at each column's foot (today's
    installation), a dim ambient, and colours in linear RGB."""
    ambient: tuple
    uplight: tuple
    uplight_height: float
    uplight_offset: float
    reach: float

    def column(self, p, n):
        """Axisymmetric warm grazing uplight on a column's surface point p
        (relative to its axis) with normal n: four symmetric lamps around the
        foot so random quarter-turn column placement never turns a side black,
        plus strong lower-shaft grazing mimicking the 2022 water-level spots."""
        p = np.asarray(p, dtype=np.float64)
        n = _unit(n)
        r = self.uplight_offset
        lamps = ((r, self.uplight_height, 0.0), (-r, self.uplight_height, 0.0),
                 (0.0, self.uplight_height, r), (0.0, self.uplight_height, -r))
        total = 0.0
        for lx, ly, lz in lamps:
            d = np.array([lx, ly, lz]) - p
            dist = float(np.linalg.norm(d))
            facing = max(0.0, float(np.dot(_unit(d), n)))
            total += facing / (1.0 + (dist / self.reach) ** 2)
        dy = max(0.0, float(p[1] - self.uplight_height))
        graze = 0.36 * (1.0 - 0.45 * abs(float(n[1]))) / (1.0 + (dy / (self.reach * 1.1)) ** 2)
        # Warm bounce near the vault springing so capitals never fade to muddy grey.
        cap_lift = 0.18 * max(0.0, (float(p[1]) - 6.5) / 3.0)
        return total * 0.62 + graze + cap_lift

    def bay(self, p, n, corners):
        """Light on a vault point from the uplights of the columns at the
        bay's corners (their beams graze up the shafts onto the springers)."""
        total = 0.0
        for cx, cz in corners:
            lamp = np.array([cx, self.uplight_height, cz])
            d = lamp - np.asarray(p)
            dist = float(np.linalg.norm(d))
            facing = max(0.0, float(np.dot(_unit(d), n)))
            total += facing / (1.0 + (dist / (self.reach * 1.55)) ** 2)
        return total * 0.96 + 0.12

    def shade(self, albedo, k, gain=1.0):
        return tuple(a * (self.ambient[i] + gain * k * self.uplight[i])
                     for i, a in enumerate(albedo))


def ring(mesh, y0, r0, y1, r1, sides, colour_at, uv_v=(0.0, 1.0), cap=False, phase=0.0):
    """A frustum band from (y0, r0) to (y1, r1); colour_at(p, n) gives the
    vertex colour. Returns nothing; adds to mesh."""
    slope = (r0 - r1) / max(1e-6, (y1 - y0))
    rows = []
    for (y, r, v) in [(y0, r0, uv_v[0]), (y1, r1, uv_v[1])]:
        row = []
        for i in range(sides + 1):
            a = phase + 2 * math.pi * i / sides
            p = (r * math.cos(a), y, r * math.sin(a))
            n = (math.cos(a), slope, math.sin(a))
            row.append(mesh.vertex(p, n, colour_at(p, _unit(n)), (i / sides, v)))
        rows.append(row)
    for i in range(sides):
        a, b = rows[0][i], rows[0][i + 1]
        c, d = rows[1][i + 1], rows[1][i]
        mesh.quad(a, d, c, b)
    if cap:
        centre = mesh.vertex((0, y1, 0), (0, 1, 0), colour_at((0, y1, 0), (0, 1, 0)))
        for i in range(sides):
            mesh.tri(centre, rows[1][i + 1], rows[1][i])


def box(mesh, x0, x1, y0, y1, z0, z1, colour_at, faces=('px', 'nx', 'py', 'ny', 'pz', 'nz')):
    """An axis-aligned box; colour_at(p, n)."""
    corners = {
        'px': ([(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)], (1, 0, 0)),
        'nx': ([(x0, y0, z1), (x0, y1, z1), (x0, y1, z0), (x0, y0, z0)], (-1, 0, 0)),
        'py': ([(x0, y1, z0), (x0, y1, z1), (x1, y1, z1), (x1, y1, z0)], (0, 1, 0)),
        'ny': ([(x0, y0, z1), (x0, y0, z0), (x1, y0, z0), (x1, y0, z1)], (0, -1, 0)),
        'pz': ([(x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (x0, y0, z1)], (0, 0, 1)),
        'nz': ([(x0, y0, z0), (x0, y1, z0), (x1, y1, z0), (x1, y0, z0)], (0, 0, -1)),
    }
    for f in faces:
        pts, n = corners[f]
        ids = [mesh.vertex(p, n, colour_at(p, n), uv)
               for p, uv in zip(pts, [(0, 1), (0, 0), (1, 0), (1, 1)])]
        mesh.quad(ids[0], ids[3], ids[2], ids[1])


def frustum_box(mesh, y0, half0, y1, half1, colour_at):
    """A square block tapering from half-width half0 at y0 to half1 at y1
    (a Byzantine impost or an abacus), closed on sides, top AND bottom so
    looking up from the deck never sees hollow capital undersides."""
    pts0 = [(-half0, y0, -half0), (half0, y0, -half0), (half0, y0, half0), (-half0, y0, half0)]
    pts1 = [(-half1, y1, -half1), (half1, y1, -half1), (half1, y1, half1), (-half1, y1, half1)]
    for i in range(4):
        a0, b0 = pts0[i], pts0[(i + 1) % 4]
        a1, b1 = pts1[i], pts1[(i + 1) % 4]
        mid = np.add(a0, b0) / 2
        n = _unit((mid[0], (half0 - half1) / max(1e-6, y1 - y0) * 0.5, mid[2]))
        ids = [mesh.vertex(p, n, colour_at(p, n), uv)
               for p, uv in zip((a0, b0, b1, a1), ((0, 1), (1, 1), (1, 0), (0, 0)))]
        mesh.quad(ids[0], ids[3], ids[2], ids[1])
    top = [mesh.vertex(p, (0, 1, 0), colour_at(p, (0, 1, 0)), uv)
           for p, uv in zip(pts1, ((0, 0), (1, 0), (1, 1), (0, 1)))]
    mesh.quad(top[0], top[3], top[2], top[1])
    bot = [mesh.vertex(p, (0, -1, 0), colour_at(p, (0, -1, 0)), uv)
           for p, uv in zip(pts0, ((0, 0), (1, 0), (1, 1), (0, 1)))]
    mesh.quad(bot[0], bot[1], bot[2], bot[3])


def _superellipse_ring(mesh, y0, r0, sq0, y1, r1, sq1, sides, colour_at, uv_v=(0.0, 1.0)):
    """A smooth transition band from circular (sq=0) to rounded-square (sq=1)
    used for the Basilica Cistern's signature bossed cushion unfinished capitals."""
    def pt(a, r, sq):
        ca, sa = math.cos(a), math.sin(a)
        # Blend circle radius r toward a rounded square of half-width r.
        m = max(abs(ca), abs(sa), 1e-6)
        sx, sz = ca / m, sa / m
        x = r * (ca * (1.0 - sq) + sx * sq)
        z = r * (sa * (1.0 - sq) + sz * sq)
        return x, z

    rows = []
    slope = (r0 - r1) / max(1e-6, y1 - y0)
    for (y, r, sq, v) in [(y0, r0, sq0, uv_v[0]), (y1, r1, sq1, uv_v[1])]:
        row = []
        for i in range(sides + 1):
            a = 2 * math.pi * i / sides
            x, z = pt(a, r, sq)
            n = _unit((math.cos(a), slope * 0.65, math.sin(a)))
            row.append(mesh.vertex((x, y, z), n, colour_at((x, y, z), n), (i / sides, v)))
        rows.append(row)
    for i in range(sides):
        a, b = rows[0][i], rows[0][i + 1]
        c, d = rows[1][i + 1], rows[1][i]
        mesh.quad(a, d, c, b)


def column_shaft(style, spec, light, albedo):
    """A spolia column shaft + base rising from the waterline to the capital
    neck (columnHeight - 0.72), by real Basilica Cistern variety:
      'M' smooth Proconnesian marble with heavy stepped square Attic base,
      'R' rough-hewn hammer-dressed quarry shaft on a thick rough plinth,
      'T' two-piece spliced spolia shaft with raised iron strengthening band,
      'D' warm spolia marble shaft on a tall moulded Roman pedestal,
      'W' the Hen's-Eye / Peacock-Eyed carved column on a low square plinth,
      'S' short smooth shaft resting atop a carved Medusa head base."""
    m = Mesh()
    yw = spec['waterLevel']
    top = spec['columnHeight']
    r0, r1 = spec['shaftRadius']
    sides = spec['sides']
    neck_y = top - 0.70

    def shaft_colour(p, n):
        # Subtle damp darkening near the waterline (first 0.45 m above water).
        wet = 0.78 + 0.22 * min(1.0, max(0.0, (p[1] - yw) / 0.45))
        c = light.shade(albedo, light.column(p, n))
        return tuple(v * wet for v in c)

    def plinth_colour(p, n):
        wet = 0.74 + 0.26 * min(1.0, max(0.0, (p[1] - yw) / 0.35))
        c = light.shade(tuple(v * 0.92 for v in albedo), light.column(p, n))
        return tuple(v * wet for v in c)

    if style == 'S':
        foot = yw + spec['baseHeight']
        ring(m, foot, r0 * 1.24, foot + 0.11, r0 * 1.24, sides, shaft_colour, uv_v=(0.0, 0.04))
        ring(m, foot + 0.11, r0 * 1.24, foot + 0.22, r0, sides, shaft_colour, uv_v=(0.04, 0.08))
        y_start = foot + 0.22
    elif style == 'D':
        # Tall moulded Roman pedestal base (as seen in DD 37-39 HDR far right).
        box(m, -0.58, 0.58, yw, yw + 0.22, -0.58, 0.58, plinth_colour,
            faces=('px', 'nx', 'py', 'pz', 'nz'))
        box(m, -0.50, 0.50, yw + 0.22, yw + 0.94, -0.50, 0.50, plinth_colour,
            faces=('px', 'nx', 'pz', 'nz'))
        box(m, -0.56, 0.56, yw + 0.94, yw + 1.10, -0.56, 0.56, plinth_colour,
            faces=('px', 'nx', 'py', 'ny', 'pz', 'nz'))
        ring(m, yw + 1.10, r0 * 1.28, yw + 1.22, r0 * 1.22, sides, shaft_colour, uv_v=(0.0, 0.04))
        ring(m, yw + 1.22, r0 * 1.22, yw + 1.32, r0, sides, shaft_colour, uv_v=(0.04, 0.08))
        y_start = yw + 1.32
    elif style in ('R', 'W'):
        # Thick low square slab plinth + compact foot moulding (DD 37-39 left & DD 46-48).
        box(m, -0.56, 0.56, yw, yw + 0.20, -0.56, 0.56, plinth_colour,
            faces=('px', 'nx', 'py', 'pz', 'nz'))
        ring(m, yw + 0.20, r0 * 1.18, yw + 0.34, r0 * 1.03, sides, shaft_colour, uv_v=(0.0, 0.04))
        y_start = yw + 0.34
    else:
        # Heavy stepped square plinth + Roman Attic double-torus base (DD 10-12 & DD 16-18).
        box(m, -0.60, 0.60, yw, yw + 0.24, -0.60, 0.60, plinth_colour,
            faces=('px', 'nx', 'py', 'pz', 'nz'))
        frustum_box(m, yw + 0.24, 0.58, yw + 0.38, 0.50, plinth_colour)
        ring(m, yw + 0.38, r0 * 1.32, yw + 0.49, r0 * 1.28, sides, shaft_colour, uv_v=(0.0, 0.03))
        ring(m, yw + 0.49, r0 * 1.28, yw + 0.58, r0 * 1.14, sides, shaft_colour, uv_v=(0.03, 0.06))
        ring(m, yw + 0.58, r0 * 1.14, yw + 0.68, r0 * 1.20, sides, shaft_colour, uv_v=(0.06, 0.08))
        ring(m, yw + 0.68, r0 * 1.20, yw + 0.76, r0, sides, shaft_colour, uv_v=(0.08, 0.10))
        y_start = yw + 0.76

    # Slightly stouter profile for rough quarry-dressed shafts.
    r_a = r0 * (1.06 if style == 'R' else 1.0)
    r_b = r1 * (1.05 if style == 'R' else 1.0)
    rows = 6
    for k in range(rows):
        ya = y_start + (neck_y - y_start) * k / rows
        yb = y_start + (neck_y - y_start) * (k + 1) / rows
        ra = r_a + (r_b - r_a) * k / rows
        rb = r_a + (r_b - r_a) * (k + 1) / rows
        ring(m, ya, ra, yb, rb, sides, shaft_colour, uv_v=(1.0 - k / rows, 1.0 - (k + 1) / rows))

    # Iron/bronze strengthening collar band on spliced spolia shafts ('T').
    if style == 'T':
        for band_y in (yw + 1.05, y_start + (neck_y - y_start) * 0.46):
            frac = max(0.0, min(1.0, (band_y - y_start) / max(1e-6, neck_y - y_start)))
            rb = (r_a + (r_b - r_a) * frac) + 0.022
            iron = lambda p, n: (0.12, 0.10, 0.09)  # noqa: E731
            ring(m, band_y - 0.06, rb, band_y + 0.06, rb, sides, iron, uv_v=(0.48, 0.52))
    return m


def column_capital(kind, spec, light, capital_albedo):
    """A column capital + brick-supporting Byzantine impost block:
      'C' carved Corinthian capital (acanthus tiers + corner volutes + abacus),
      'B' bossed rounded-cushion unfinished blank (signature Basilica Cistern form),
      'P' rough-chiseled beveled trapezoidal Byzantine block."""
    m = Mesh()
    top = spec['columnHeight']
    impost = spec['impostHeight']
    r1 = spec['shaftRadius'][1]
    sides = spec['sides']

    def cap_colour(p, n):
        return light.shade(capital_albedo, light.column(p, n), gain=1.22)

    if kind == 'C':
        y_neck = top - 0.86
        ring(m, y_neck, r1 * 1.14, y_neck + 0.06, r1 * 1.14, sides, cap_colour, uv_v=(0.95, 1.0))
        y = y_neck + 0.06
        # Flared acanthus bell mapped with real Corinthian carving photo.
        ring(m, y, r1 * 1.02, top - 0.14, r1 * 1.48, sides, cap_colour, uv_v=(1.0, 0.05))
        # Two staggered tiers of 3D sculpted acanthus leaf wedges.
        for row, (ya, yb, tilt) in enumerate([(y, y + 0.36, 0.16), (y + 0.24, y + 0.62, 0.23)]):
            for i in range(8):
                a = 2 * math.pi * (i + 0.5 * row) / 8
                ca, sa = math.cos(a), math.sin(a)
                w = 0.125
                base_r = r1 * (1.02 + 0.20 * row)
                in_r = base_r - 0.05
                tip_r = base_r + tilt
                tx, tz = -sa * w, ca * w
                p0 = (base_r * ca - tx, ya, base_r * sa - tz)
                p1 = (base_r * ca + tx, ya, base_r * sa + tz)
                p2 = (tip_r * ca, yb, tip_r * sa)
                q0 = (in_r * ca - tx * 0.6, ya + 0.04, in_r * sa - tz * 0.6)
                q1 = (in_r * ca + tx * 0.6, ya + 0.04, in_r * sa + tz * 0.6)
                nf = _unit((ca, -0.35, sa))
                nb = _unit((ca, 0.75, sa))
                f_ids = [m.vertex(p, nf, cap_colour(p, nf), uv)
                         for p, uv in zip((p0, p1, p2), ((0.2, 0.9), (0.8, 0.9), (0.5, 0.2)))]
                m.tri(f_ids[0], f_ids[2], f_ids[1])
                b_ids = [m.vertex(p, nb, cap_colour(p, nb), uv)
                         for p, uv in zip((q0, q1, p2), ((0.2, 0.8), (0.8, 0.8), (0.5, 0.2)))]
                m.tri(b_ids[0], b_ids[1], b_ids[2])
                ns0 = _unit((-sa, 0.2, ca))
                s0 = [m.vertex(p, ns0, cap_colour(p, ns0), (0.5, 0.5)) for p in (p1, q1, p2)]
                m.tri(s0[0], s0[2], s0[1])
                ns1 = _unit((sa, 0.2, -ca))
                s1 = [m.vertex(p, ns1, cap_colour(p, ns1), (0.5, 0.5)) for p in (q0, p0, p2)]
                m.tri(s1[0], s1[2], s1[1])
        # Four projecting corner volute bosses under the abacus.
        for a in (math.pi * 0.25, math.pi * 0.75, math.pi * 1.25, math.pi * 1.75):
            cx, cz = math.cos(a) * r1 * 1.56, math.sin(a) * r1 * 1.56
            box(m, cx - 0.09, cx + 0.09, top - 0.28, top - 0.12, cz - 0.09, cz + 0.09, cap_colour)
        frustum_box(m, top - 0.14, r1 * 1.54, top, r1 * 1.66, cap_colour)
    elif kind == 'B':
        # Signature Basilica Cistern bossed / rounded-cushion unfinished capital
        # (smooth bulging pillow transitioning from round neck to square impost).
        y_neck = top - 0.74
        ring(m, y_neck, r1 * 1.12, y_neck + 0.06, r1 * 1.12, sides, cap_colour, uv_v=(0.9, 1.0))
        y = y_neck + 0.06
        _superellipse_ring(m, y, r1 * 1.04, 0.0, y + 0.20, r1 * 1.42, 0.45, sides, cap_colour, uv_v=(1.0, 0.65))
        _superellipse_ring(m, y + 0.20, r1 * 1.42, 0.45, y + 0.48, r1 * 1.66, 0.85, sides, cap_colour, uv_v=(0.65, 0.25))
        _superellipse_ring(m, y + 0.48, r1 * 1.66, 0.85, top, r1 * 1.62, 0.96, sides, cap_colour, uv_v=(0.25, 0.0))
        frustum_box(m, top - 0.04, r1 * 1.58, top, r1 * 1.62, cap_colour)
    else:  # 'P': rough-chiseled beveled Byzantine trapezoidal block
        y_neck = top - 0.74
        ring(m, y_neck, r1 * 1.10, y_neck + 0.06, r1 * 1.10, sides, cap_colour, uv_v=(0.9, 1.0))
        y = y_neck + 0.06
        _superellipse_ring(m, y, r1 * 1.06, 0.3, y + 0.14, r1 * 1.24, 0.85, sides, cap_colour, uv_v=(1.0, 0.8))
        frustum_box(m, y + 0.14, r1 * 1.24, top, r1 * 1.62, cap_colour)
    # Brick-supporting Byzantine impost block crowning every capital.
    frustum_box(m, top, r1 * 1.60, top + impost, r1 * 1.92, cap_colour)
    return m


def tie_rods(spec, rail_colour):
    """The 2017-2022 seismic steel tension tie-rods spanning between column
    heads in both X and Z directions, with slim rosette anchor plates flush
    against the impost faces."""
    m = Mesh()
    px, pz = spec['pitch']
    y_rod = spec['columnHeight'] + 0.14
    hx, hz = px / 2, pz / 2
    col = lambda p, n: rail_colour  # noqa: E731
    _beam(m, np.array([-hx + 0.52, -hz]), np.array([hx - 0.52, -hz]), 0.011, y_rod - 0.011, y_rod + 0.011, col)
    _beam(m, np.array([-hx, -hz + 0.52]), np.array([-hx, hz - 0.52]), 0.011, y_rod - 0.011, y_rod + 0.011, col)
    rosette = lambda p, n: tuple(min(1.0, c * 1.25) for c in rail_colour)  # noqa: E731
    # Slim flush anchor plates on the four impost faces of the (-hx, -hz) corner.
    for dx, dz, sx, sz in ((0.56, 0.0, 0.018, 0.085), (-0.56, 0.0, 0.018, 0.085),
                           (0.0, 0.56, 0.085, 0.018), (0.0, -0.56, 0.085, 0.018)):
        cx, cz = -hx + dx, -hz + dz
        box(m, cx - sx, cx + sx, y_rod - 0.085, y_rod + 0.085, cz - sz, cz + sz, rosette)
    return m


def uplamp(spec, body_colour, glow_colour):
    """A compact 2022 water's-edge spotlight pod beside a column base: dark
    housing (`body`) and recessed warm-amber lens (`glow`) casting subtle warm
    reflections into the mirror water below."""
    body = Mesh()
    glow = Mesh()
    yw = spec['waterLevel']
    cx, cz = 0.66, 0.66
    bcol = lambda p, n: body_colour  # noqa: E731
    gcol = lambda p, n: glow_colour  # noqa: E731
    box(body, cx - 0.032, cx + 0.032, yw, yw + 0.14, cz - 0.032, cz + 0.032, bcol,
        faces=('px', 'nx', 'pz', 'nz'))
    box(body, cx - 0.075, cx + 0.075, yw + 0.13, yw + 0.21, cz - 0.075, cz + 0.075, bcol,
        faces=('px', 'nx', 'ny', 'pz', 'nz'))
    box(glow, cx - 0.055, cx + 0.055, yw + 0.21, yw + 0.232, cz - 0.055, cz + 0.055, gcol,
        faces=('px', 'nx', 'py', 'pz', 'nz'))
    return body, glow


def column(kind, spec, light, albedo, capital_albedo):
    """Legacy combined column helper kept for unit tests."""
    m = column_shaft('W' if kind == 'W' else ('S' if kind == 'S' else 'M'), spec, light, albedo)
    m.extend(column_capital('C' if kind in ('C', 'W') else 'P', spec, light, capital_albedo))
    return m


def bay(spec, light, albedo, arch_albedo):
    """One smooth Byzantine groin-vault bay between four columns, centred on
    the origin: four continuous barrel-vault webs with concentric brick-course
    UVs, baked depth shading (rich AO in springings & quieter crown), and real
    3D projecting brick transverse & longitudinal arch ribs along the bay edges."""
    m = Mesh()
    px, pz = spec['pitch']
    hs = spec['columnHeight'] + spec['impostHeight']
    rise = spec['vaultRise']
    hx, hz = px / 2, pz / 2
    corners = [(-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)]
    s_steps = [0.0, 0.24, 0.48, 0.70, 0.88, 1.0]
    t_steps = 6

    def height(u, v, web):
        w = v if web in ('E', 'W') else u
        return hs + rise * math.sqrt(max(0.0, 1.0 - w * w))

    def normal(u, v, web):
        w = v if web in ('E', 'W') else u
        k = max(1e-3, math.sqrt(max(1e-6, 1.0 - w * w)))
        d = -rise * w / k
        if web in ('E', 'W'):
            return (0.0, -1.0, d / hz)
        return (d / hx, -1.0, 0.0)

    def vault_colour(p, n, s, t, tone):
        # Sculptural depth shading: darker corner pockets near column springings,
        # warm grazing uplight across the mid-haunches, and a slightly quieter
        # high crown so the 3D cross-vault reads vividly without flat ceiling glare.
        corner_ao = 1.0 - 0.42 * (s ** 2) * (t ** 2)
        crown_shade = 0.74 + 0.26 * min(1.0, s / 0.45)
        k_light = light.bay(p, n, corners) * corner_ao * crown_shade
        return light.shade(tone, k_light)

    for web in ('E', 'N', 'W', 'S'):
        apex_p = (0.0, hs + rise, 0.0)
        apex_n = (0.0, -1.0, 0.0)
        apex = m.vertex(apex_p, apex_n, vault_colour(apex_p, apex_n, 0.0, 0.0, albedo), (0.0, 0.0))
        grid = []
        for s in s_steps[1:]:
            row = []
            for k in range(t_steps + 1):
                t = -1.0 + 2.0 * k / t_steps
                u, v = {'E': (s, t * s), 'W': (-s, t * s), 'N': (t * s, s), 'S': (t * s, -s)}[web]
                p = (u * hx, height(u, v, web), v * hz)
                n = _unit(normal(u, v, web))
                # Concentric brick courses: U runs parallel to bay edge, V runs
                # outward along the barrel arc so bricks form authentic concentric
                # Byzantine squares meeting cleanly along the 4 diagonal groins.
                uv = (t * s * 2.2, s * 3.6)
                row.append(m.vertex(p, n, vault_colour(p, n, s, t, albedo), uv))
            grid.append(row)
        for k in range(t_steps):
            a, b = grid[0][k], grid[0][k + 1]
            if web in ('E', 'N'):
                m.tri(apex, b, a)
            else:
                m.tri(apex, a, b)
        for i in range(len(grid) - 1):
            for k in range(t_steps):
                a, b = grid[i][k], grid[i][k + 1]
                c, d = grid[i + 1][k + 1], grid[i + 1][k]
                if web in ('E', 'N'):
                    m.quad(a, d, c, b)
                else:
                    m.quad(a, b, c, d)

    # Real 3D projecting brick transverse & longitudinal arch ribs along the
    # (-hz) and (-hx) bay edges (hanging 0.11 m beneath the smooth vault seam
    # with crisp soffit + shaded side cheeks, framing every vaulted bay!).
    rib_half_w = 0.14
    rib_depth = 0.11
    rib_segs = 10
    for along_x in (True, False):
        span_h = hx if along_x else hz
        fixed = -hz if along_x else -hx
        pts_top_l, pts_top_r, pts_bot_l, pts_bot_r = [], [], [], []
        for i in range(rib_segs + 1):
            w = -0.92 + 1.84 * i / rib_segs
            y_hi = hs + rise * math.sqrt(max(0.0, 1.0 - w * w)) + 0.01
            y_lo = y_hi - rib_depth
            coord = w * span_h
            u_arc = i / rib_segs * 3.4
            if along_x:
                p_bl = (coord, y_lo, fixed - rib_half_w)
                p_br = (coord, y_lo, fixed + rib_half_w)
                p_tl = (coord, y_hi, fixed - rib_half_w)
                p_tr = (coord, y_hi, fixed + rib_half_w)
                n_s = _unit((w * rise / max(0.2, math.sqrt(max(0.04, 1.0 - w * w))) / span_h, -1.0, 0.0))
                nl, nr = (0.0, 0.0, -1.0), (0.0, 0.0, 1.0)
            else:
                p_bl = (fixed - rib_half_w, y_lo, coord)
                p_br = (fixed + rib_half_w, y_lo, coord)
                p_tl = (fixed - rib_half_w, y_hi, coord)
                p_tr = (fixed + rib_half_w, y_hi, coord)
                n_s = _unit((0.0, -1.0, w * rise / max(0.2, math.sqrt(max(0.04, 1.0 - w * w))) / span_h))
                nl, nr = (-1.0, 0.0, 0.0), (1.0, 0.0, 0.0)
            c_sof = light.shade(arch_albedo, light.bay(p_bl, n_s, corners) * 0.92)
            c_side = light.shade(tuple(v * 0.72 for v in arch_albedo), light.bay(p_tl, nl, corners) * 0.75)
            pts_bot_l.append((p_bl, n_s, c_sof, (0.0, u_arc), nl, c_side))
            pts_bot_r.append((p_br, n_s, c_sof, (0.5, u_arc), nr, c_side))
            pts_top_l.append((p_tl, nl, c_side, (0.0, u_arc)))
            pts_top_r.append((p_tr, nr, c_side, (0.5, u_arc)))
        for i in range(rib_segs):
            # Arch soffit (underside)
            bl0, br0 = pts_bot_l[i], pts_bot_r[i]
            bl1, br1 = pts_bot_l[i + 1], pts_bot_r[i + 1]
            sv = [m.vertex(bl0[0], bl0[1], bl0[2], bl0[3]),
                  m.vertex(br0[0], br0[1], br0[2], br0[3]),
                  m.vertex(br1[0], br1[1], br1[2], br1[3]),
                  m.vertex(bl1[0], bl1[1], bl1[2], bl1[3])]
            m.quad(sv[0], sv[1], sv[2], sv[3])
            # Left cheek
            tl0, tl1 = pts_top_l[i], pts_top_l[i + 1]
            lv = [m.vertex(bl0[0], bl0[4], bl0[5], (0.0, bl0[3][1])),
                  m.vertex(bl1[0], bl1[4], bl1[5], (0.0, bl1[3][1])),
                  m.vertex(tl1[0], tl1[1], tl1[2], (0.2, tl1[3][1])),
                  m.vertex(tl0[0], tl0[1], tl0[2], (0.2, tl0[3][1]))]
            m.quad(lv[0], lv[1], lv[2], lv[3])
            # Right cheek
            tr0, tr1 = pts_top_r[i], pts_top_r[i + 1]
            rv = [m.vertex(br0[0], br0[4], br0[5], (0.0, br0[3][1])),
                  m.vertex(tr0[0], tr0[1], tr0[2], (0.2, tr0[3][1])),
                  m.vertex(tr1[0], tr1[1], tr1[2], (0.2, tr1[3][1])),
                  m.vertex(br1[0], br1[4], br1[5], (0.0, br1[3][1]))]
            m.quad(rv[0], rv[1], rv[2], rv[3])
    return m


def wall_segment(spec, light, albedo, length, pitch_other):
    """A wall face one bay wide (centred on x = 0, facing +z), from the
    waterline to the vault's lunette, with zero degenerate triangles at the
    arch springings."""
    m = Mesh()
    yw = spec['waterLevel']
    hs = spec['columnHeight'] + spec['impostHeight']
    rise = spec['vaultRise']
    h = length / 2
    n = (0.0, 0.0, 1.0)

    def colour(p, nn):
        k = light.bay(p, nn, [(-h, 0.4), (h, 0.4)]) * 0.9
        return light.shade(albedo, k)

    steps = 8
    bottom = [m.vertex((-h + length * i / steps, yw, 0), n,
                       colour((-h + length * i / steps, yw, 0), n),
                       (length * i / steps / 3.0, 0.0)) for i in range(steps + 1)]
    mid = [m.vertex((-h + length * i / steps, hs, 0), n,
                    colour((-h + length * i / steps, hs, 0), n),
                    (length * i / steps / 3.0, (hs - yw) / 3.0)) for i in range(steps + 1)]
    arch = [mid[0]]
    for i in range(1, steps):
        u = -1 + 2 * i / steps
        x = u * h
        y = hs + rise * math.sqrt(max(0.0, 1 - u * u))
        arch.append(m.vertex((x, y, 0), n, colour((x, y, 0), n),
                             ((x + h) / 3.0, (y - yw) / 3.0)))
    arch.append(mid[steps])
    for i in range(steps):
        m.quad(bottom[i], bottom[i + 1], mid[i + 1], mid[i])
        if i == 0:
            m.tri(mid[0], mid[1], arch[1])
        elif i == steps - 1:
            m.tri(mid[i], mid[i + 1], arch[i])
        else:
            m.quad(mid[i], mid[i + 1], arch[i + 1], arch[i])
    return m


def pilaster(spec, light, albedo):
    """A wall pier where a column row meets the wall (facing +z)."""
    m = Mesh()
    yw = spec['waterLevel']
    hs = spec['columnHeight'] + spec['impostHeight']

    def colour(p, n):
        return light.shade(albedo, light.column((p[0], p[1], p[2] - 0.3), n))

    box(m, -0.35, 0.35, yw, hs, 0.0, 0.32, colour, faces=('px', 'nx', 'pz'))
    return m


def plane(x0, x1, z0, z1, y, colour, uv_scale=(1.0, 1.0), up=True):
    m = Mesh()
    n = (0, 1, 0) if up else (0, -1, 0)
    ids = [m.vertex((x, y, z), n, colour, (u * uv_scale[0], v * uv_scale[1]))
           for (x, z, u, v) in [(x0, z0, 0, 0), (x1, z0, 1, 0), (x1, z1, 1, 1), (x0, z1, 0, 1)]]
    if up:
        m.quad(ids[0], ids[3], ids[2], ids[1])
    else:
        m.quad(ids[0], ids[1], ids[2], ids[3])
    return m


def _beam(mesh, p0, p1, half_w, y0, y1, col_fn):
    """A 3D rectangular bar between 2D XZ points p0 and p1 spanning y in [y0, y1]."""
    d = p1 - p0
    length = float(np.linalg.norm(d))
    if length < 1e-6:
        return
    t = d / length
    side = np.array([-t[1], t[0]])
    a0, a1 = p0 - side * half_w, p0 + side * half_w
    b0, b1 = p1 - side * half_w, p1 + side * half_w
    u1 = length / max(0.2, 2.0 * half_w)
    # Top (+y)
    top = [mesh.vertex((q[0], y1, q[1]), (0, 1, 0), col_fn((q[0], y1, q[1]), (0, 1, 0)), uv)
           for q, uv in zip((a0, b0, b1, a1), ((0, 0), (u1, 0), (u1, 1), (0, 1)))]
    mesh.quad(top[0], top[3], top[2], top[1])
    # Bottom (-y)
    bot = [mesh.vertex((q[0], y0, q[1]), (0, -1, 0), col_fn((q[0], y0, q[1]), (0, -1, 0)), uv)
           for q, uv in zip((a0, b0, b1, a1), ((0, 0), (u1, 0), (u1, 1), (0, 1)))]
    mesh.quad(bot[0], bot[1], bot[2], bot[3])
    # Left (-side) & Right (+side)
    for (q0, q1, sgn) in ((a0, b0, -1), (a1, b1, 1)):
        n = (side[0] * sgn, 0.0, side[1] * sgn)
        f = [mesh.vertex((q0[0], y0, q0[1]), n, col_fn((q0[0], y0, q0[1]), n), (0, 1)),
             mesh.vertex((q1[0], y0, q1[1]), n, col_fn((q1[0], y0, q1[1]), n), (u1, 1)),
             mesh.vertex((q1[0], y1, q1[1]), n, col_fn((q1[0], y1, q1[1]), n), (u1, 0)),
             mesh.vertex((q0[0], y1, q0[1]), n, col_fn((q0[0], y1, q0[1]), n), (0, 0))]
        if sgn > 0:
            mesh.quad(f[0], f[1], f[2], f[3])
        else:
            mesh.quad(f[0], f[3], f[2], f[1])


def _miter_offsets(pts, offset):
    """Mitered left (-side) and right (+side) 2D offset polylines for `pts`,
    so right-angle walkway bends meet cleanly without overlapping Z-fighting."""
    n = len(pts)
    left, right = [], []
    for i in range(n):
        if i == 0:
            t = pts[1] - pts[0]
            t /= np.linalg.norm(t)
            s = np.array([-t[1], t[0]])
            left.append(pts[0] - s * offset)
            right.append(pts[0] + s * offset)
        elif i == n - 1:
            t = pts[-1] - pts[-2]
            t /= np.linalg.norm(t)
            s = np.array([-t[1], t[0]])
            left.append(pts[-1] - s * offset)
            right.append(pts[-1] + s * offset)
        else:
            t0 = pts[i] - pts[i - 1]
            t0 /= np.linalg.norm(t0)
            t1 = pts[i + 1] - pts[i]
            t1 /= np.linalg.norm(t1)
            s0 = np.array([-t0[1], t0[0]])
            s1 = np.array([-t1[1], t1[0]])
            bis = s0 + s1
            bl = float(np.linalg.norm(bis))
            if bl < 1e-6:
                m = s0 * offset
            else:
                bis /= bl
                denom = max(0.35, float(np.dot(bis, s0)))
                m = bis * (offset / denom)
            left.append(pts[i] - m)
            right.append(pts[i] + m)
    return left, right


def _sloped_beam(mesh, p0, p1, half_w, half_h, col_fn):
    """A 3D rectangular bar between 3D points p0=(x,y,z) and p1=(x,y,z)."""
    a = np.array(p0, dtype=np.float64)
    b = np.array(p1, dtype=np.float64)
    d = b - a
    length = float(np.linalg.norm(d))
    if length < 1e-6:
        return
    t = d / length
    side = np.cross(t, np.array([0.0, 1.0, 0.0]))
    sl = float(np.linalg.norm(side))
    side = side / sl if sl > 1e-6 else np.array([1.0, 0.0, 0.0])
    up = np.cross(side, t)
    up /= max(1e-6, float(np.linalg.norm(up)))
    # 4 corner offsets around axis: (-side,-up), (+side,-up), (+side,+up), (-side,+up)
    offs = [(-side * half_w - up * half_h),
            (side * half_w - up * half_h),
            (side * half_w + up * half_h),
            (-side * half_w + up * half_h)]
    norms = [-up, side, up, -side]
    for k in range(4):
        n = tuple(float(v) for v in norms[k])
        o0, o1 = offs[k], offs[(k + 1) % 4]
        pts = [a + o0, b + o0, b + o1, a + o1]
        vs = [mesh.vertex(tuple(float(v) for v in q), n, col_fn(q, n), (0, 0)) for q in pts]
        mesh.quad(vs[0], vs[1], vs[2], vs[3])


def walkway(points, spec, deck_colour, rail_colour, strip_colour, stair_opening=True):
    """A mitered boardwalk deck along a polyline (x, z) at spec['deckHeight'],
    returning separate (deck_mesh, rail_mesh, strip_mesh) so plank textures
    stay strictly on the deck, dark metal stays clean on handrails/stilts, and
    the LED guide strips glow independently."""
    m = Mesh()
    rail = Mesh()
    strip = Mesh()
    y = spec['deckHeight']
    half = spec['deckWidth'] / 2
    pts = [np.array(p, dtype=np.float64) for p in points]
    # Extend start and end cleanly by half a width so terminal platforms frame the stops.
    t_start = pts[1] - pts[0]
    t_start /= np.linalg.norm(t_start)
    t_end = pts[-1] - pts[-2]
    t_end /= np.linalg.norm(t_end)
    ext = [pts[0] - t_start * half] + pts[1:-1] + [pts[-1] + t_end * half]
    left, right = _miter_offsets(ext, half)
    r_left, r_right = _miter_offsets(ext, half - 0.06)

    def rail_col(p, n):
        return rail_colour

    def strip_col(p, n):
        return strip_colour

    # Deck top, bottom, and side fascia per mitered segment.
    for i in range(len(ext) - 1):
        a0, a1 = left[i], right[i]
        b0, b1 = left[i + 1], right[i + 1]
        d = ext[i + 1] - ext[i]
        seg_len = float(np.linalg.norm(d))
        t = d / max(1e-6, seg_len)
        side = np.array([-t[1], t[0]])
        # True axial projection for U so plank joints stay strictly perpendicular
        # to the walkway axis even across 45-degree mitered corner trapezoids.
        def uv_top(q, v_side):
            return (float(np.dot(q - ext[i], t)) / 1.6, v_side)

        # Top surface (+y)
        top = [m.vertex((q[0], y, q[1]), (0, 1, 0), deck_colour, uv_top(q, vs))
               for q, vs in ((a0, 0.0), (b0, 0.0), (b1, 1.0), (a1, 1.0))]
        m.quad(top[0], top[3], top[2], top[1])
        # Solid underside (-y) so reflection and low views see a real deck slab.
        bot = [m.vertex((q[0], y - 0.18, q[1]), (0, -1, 0),
                        tuple(c * 0.45 for c in deck_colour), uv_top(q, vs))
               for q, vs in ((a0, 0.0), (b0, 0.0), (b1, 1.0), (a1, 1.0))]
        m.quad(bot[0], bot[1], bot[2], bot[3])
        # Side fascia + sleek 3D handrails + emissive toe-kick strip + 3D posts + water stilts.
        for (e0, e1, h0, h1, sgn) in ((a0, b0, r_left[i], r_left[i + 1], -1),
                                      (a1, b1, r_right[i], r_right[i + 1], 1)):
            n = (side[0] * sgn, 0.0, side[1] * sgn)
            fascia_col = tuple(c * 0.85 for c in deck_colour)
            u0 = float(np.dot(e0 - ext[i], t)) / 1.6
            u1 = float(np.dot(e1 - ext[i], t)) / 1.6
            f = [m.vertex((e0[0], y, e0[1]), n, fascia_col, (u0, 0)),
                 m.vertex((e1[0], y, e1[1]), n, fascia_col, (u1, 0)),
                 m.vertex((e1[0], y - 0.18, e1[1]), n, fascia_col, (u1, 1)),
                 m.vertex((e0[0], y - 0.18, e0[1]), n, fascia_col, (u0, 1))]
            if sgn > 0:
                m.quad(f[0], f[3], f[2], f[1])
            else:
                m.quad(f[0], f[1], f[2], f[3])
            # Keep the stair landing opening at the start of segment 0 unobstructed.
            rh0 = h0 + t * spec['deckWidth'] if (stair_opening and i == 0 and sgn == -1) else h0
            rlen = float(np.linalg.norm(h1 - rh0))
            if rlen > 0.25:
                # Sleek minimalist single top handrail (y+1.03..1.07 clears Medusa's face)
                # and subtle low curb wire at y+0.12 (clean dark metal, no plank texture).
                _beam(rail, rh0, h1, 0.016, y + 1.03, y + 1.065, rail_col)
                _beam(strip, rh0, h1, 0.018, y + 0.03, y + 0.075, strip_col)
                # Slender stanchion posts every ~2.8 m, avoiding blocking any
                # special carved-base viewing sightline directly in front of it.
                avoid_xs = [c[0] * spec['pitch'][0] for c in spec.get('_carved_cols', ())]
                count = max(1, int(round(rlen / 2.8)))
                for k in range(count + 1):
                    p = rh0 + (h1 - rh0) * (k / count)
                    if any(abs(p[0] - ax) < 0.75 and abs(p[1] - 1.5 * spec['pitch'][1]) < 1.5 for ax in avoid_xs):
                        continue
                    box(rail, p[0] - 0.016, p[0] + 0.016, y, y + 1.03, p[1] - 0.016, p[1] + 0.016,
                        rail_col, faces=('px', 'nx', 'pz', 'nz'))
            # Submerged dark support stilts reaching to the cistern floor every ~5 m.
            slen = float(np.linalg.norm(h1 - h0))
            stilt_n = max(1, int(round(slen / 5.0)))
            stilt_col = lambda p, n: tuple(c * 0.55 for c in rail_colour)  # noqa: E731
            for k in range(stilt_n + 1):
                p = h0 + (h1 - h0) * (k / stilt_n)
                box(rail, p[0] - 0.055, p[0] + 0.055, 0.0, y - 0.18, p[1] - 0.055, p[1] + 0.055,
                    stilt_col, faces=('px', 'nx', 'pz', 'nz'))
    # Cap start and end faces of the deck slab cleanly.
    for (p0, p1, tn) in ((left[0], right[0], (-t_start[0], 0.0, -t_start[1])),
                         (right[-1], left[-1], (t_end[0], 0.0, t_end[1]))):
        f = [m.vertex((p0[0], y, p0[1]), tn, deck_colour, (0, 0)),
             m.vertex((p1[0], y, p1[1]), tn, deck_colour, (1, 0)),
             m.vertex((p1[0], y - 0.18, p1[1]), tn, deck_colour, (1, 1)),
             m.vertex((p0[0], y - 0.18, p0[1]), tn, deck_colour, (0, 1))]
        m.quad(f[0], f[3], f[2], f[1])
    return m, rail, strip


def stair(x, z, direction, spec, steps, rise, run, width, colour, rail_colour, strip_colour=None):
    """A straight stone flight from the deck up toward `direction` (+1 or -1
    along x), returning separate (stone_mesh, rail_mesh, door_mesh): closed
    dressed-stone steps and top landing reaching the perimeter wall, sleek open
    metal handrails, and a warm-lit street doorway at the top."""
    m = Mesh()
    rail = Mesh()
    door = Mesh()
    y0 = spec['deckHeight']
    y_top = y0 + steps * rise
    x_top = x + direction * run * steps
    for i in range(steps):
        x0 = x + direction * run * i
        x1 = x0 + direction * run
        ya, yb = y0 + rise * i, y0 + rise * (i + 1)
        lo, hi = sorted([x0, x1])
        step_col = tuple(c * (0.48 + 0.42 * (i / max(1, steps))) for c in colour)
        box(m, lo, hi, ya - 0.28, yb, z - width / 2, z + width / 2,
            lambda p, n, sc=step_col: sc,
            faces=('py', 'ny', 'nx' if direction > 0 else 'px', 'pz', 'nz'))
    # Solid top landing extending past the `stair` camera stop and back to the perimeter wall.
    land_lo, land_hi = sorted([x_top, x_top + direction * 2.8])
    wall_z = spec['width']
    z_lo = z - width / 2
    z_hi = wall_z
    land_col = tuple(c * 0.85 for c in colour)
    box(m, land_lo, land_hi, y_top - 0.35, y_top, z_lo, z_hi,
        lambda p, n: land_col, faces=('px', 'nx', 'py', 'ny', 'pz', 'nz'))
    # Sleek open metal handrail + slender posts along the hall-facing landing & stair edge.
    rail_z = z - width / 2 + 0.06
    rail_col = lambda p, n: rail_colour  # noqa: E731
    _beam(rail, np.array([land_lo, rail_z]), np.array([land_hi, rail_z]),
          0.018, y_top + 0.94, y_top + 0.98, rail_col)
    for k in range(4):
        px_k = land_lo + (land_hi - land_lo) * (k / 3)
        box(rail, px_k - 0.016, px_k + 0.016, y_top, y_top + 0.94,
            rail_z - 0.016, rail_z + 0.016, rail_col, faces=('px', 'nx', 'pz', 'nz'))
    # Sloped open handrail following the flight down to the boardwalk.
    _sloped_beam(rail, (x, y0 + 1.04, rail_z), (x_top, y_top + 0.96, rail_z),
                 0.018, 0.018, rail_col)
    for k in range(1, 4):
        frac = k / 4
        px_k = x + (x_top - x) * frac
        py_k = y0 + (y_top - y0) * frac
        box(rail, px_k - 0.016, px_k + 0.016, py_k, py_k + 0.98,
            rail_z - 0.016, rail_z + 0.016, rail_col, faces=('px', 'nx', 'pz', 'nz'))
    # Lit street-entrance doorway recessed slightly in front of the perimeter wall (z = wall_z).
    dx_mid = (land_lo + land_hi) / 2
    door_col = strip_colour or (1.0, 0.72, 0.40)
    box(door, dx_mid - 0.95, dx_mid + 0.95, y_top, y_top + 2.5, wall_z - 0.18, wall_z - 0.06,
        lambda p, n: door_col, faces=('nz',))
    return m, rail, door


def carved_base(spec, light, albedo, face_axis, size):
    """A carved block a column stands on (the Medusa heads): moulded base
    plinth and cap, textured stone sides, and a warm-uplighted front face
    toward +z UV-mapped for the photograph."""
    m = Mesh()
    yw = spec['waterLevel']
    w, h, d = size

    def colour(p, n):
        return light.shade(albedo, light.column((p[0], p[1], p[2]), n) + 0.55)

    # Lower plinth emerging from water and upper cornice seating the shaft.
    box(m, -w / 2 - 0.06, w / 2 + 0.06, yw, yw + 0.10, -d / 2 - 0.06, d / 2 + 0.06,
        colour, faces=('px', 'nx', 'py', 'pz', 'nz'))
    box(m, -w / 2, w / 2, yw + 0.10, yw + h - 0.07, -d / 2, d / 2,
        colour, faces=('px', 'nx', 'py', 'nz'))
    box(m, -w / 2 - 0.04, w / 2 + 0.04, yw + h - 0.07, yw + h, -d / 2 - 0.04, d / 2 + 0.04,
        colour, faces=('px', 'nx', 'py', 'ny', 'pz', 'nz'))
    face = Mesh()
    n = (0, 0, 1)
    # Warm subtle uplight gradient so the carved Medusa photo blends into the lit stone.
    lo_col = (1.0, 0.95, 0.86)
    hi_col = (0.86, 0.80, 0.72)
    ids = [face.vertex((x, y, d / 2 + 0.005), n, col, uv)
           for (x, y, uv, col) in [(-w / 2, yw + 0.10, (0, 1), lo_col),
                                   (w / 2, yw + 0.10, (1, 1), lo_col),
                                   (w / 2, yw + h - 0.07, (1, 0), hi_col),
                                   (-w / 2, yw + h - 0.07, (0, 0), hi_col)]]
    face.quad(ids[0], ids[1], ids[2], ids[3])
    return m, face


def fish(length, colour, belly):
    """A low carp: a single nose vertex fan into 5 rings and a forked tail,
    nose +x, with zero degenerate triangles."""
    m = Mesh()
    profile = [(0.12, 0.06), (0.35, 0.09), (0.6, 0.075), (0.82, 0.04), (0.9, 0.02)]
    sides = 6
    nose = m.vertex((0.5 * length, 0.0, 0.0), (1.0, 0.0, 0.0), colour)
    rows = []
    for (s, r) in profile:
        x = (0.5 - s) * length
        row = []
        for i in range(sides):
            a = 2 * math.pi * i / sides
            y, z = r * length * 0.55 * math.sin(a), r * length * math.cos(a)
            col = belly if math.sin(a) < -0.3 else colour
            row.append(m.vertex((x, y, z), (0, math.sin(a), math.cos(a)), col))
        rows.append(row)
    for i in range(sides):
        m.tri(nose, rows[0][(i + 1) % sides], rows[0][i])
    for j in range(len(rows) - 1):
        for i in range(sides):
            a, b = rows[j][i], rows[j][(i + 1) % sides]
            c, d = rows[j + 1][(i + 1) % sides], rows[j + 1][i]
            m.quad(a, b, c, d)
    tail_x = (0.5 - 0.9) * length
    t = [m.vertex((tail_x, 0, 0), (0, 0, 1), colour),
         m.vertex((tail_x - 0.22 * length, 0.08 * length, 0), (0, 0, 1), colour),
         m.vertex((tail_x - 0.22 * length, -0.08 * length, 0), (0, 0, 1), colour)]
    m.tri(t[0], t[1], t[2])
    m.tri(t[0], t[2], t[1])
    return m
