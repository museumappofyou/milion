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
        """Light on a column's surface point p (relative to its axis) with
        normal n, from the lamp at its own foot, offset toward -z (the
        walkway side) by `uplight_offset`."""
        lamp = np.array([0.0, self.uplight_height, -self.uplight_offset])
        d = lamp - np.asarray(p)
        dist = float(np.linalg.norm(d))
        facing = max(0.0, float(np.dot(_unit(d), n)))
        falloff = 1.0 / (1.0 + (dist / self.reach) ** 2)
        return facing * falloff

    def bay(self, p, n, corners):
        """Light on a vault point from the uplights of the columns at the
        bay's corners (their beams graze up the shafts onto the springers)."""
        total = 0.0
        for cx, cz in corners:
            lamp = np.array([cx, self.uplight_height, cz - self.uplight_offset])
            d = lamp - np.asarray(p)
            dist = float(np.linalg.norm(d))
            facing = max(0.0, float(np.dot(_unit(d), n)))
            total += facing / (1.0 + (dist / self.reach) ** 2)
        return total

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
    (a Byzantine impost or an abacus), sides and top."""
    pts0 = [(-half0, y0, -half0), (half0, y0, -half0), (half0, y0, half0), (-half0, y0, half0)]
    pts1 = [(-half1, y1, -half1), (half1, y1, -half1), (half1, y1, half1), (-half1, y1, half1)]
    for i in range(4):
        a0, b0 = pts0[i], pts0[(i + 1) % 4]
        a1, b1 = pts1[i], pts1[(i + 1) % 4]
        mid = np.add(a0, b0) / 2
        n = _unit((mid[0], (half0 - half1) / max(1e-6, y1 - y0) * 0.5, mid[2]))
        ids = [mesh.vertex(p, n, colour_at(p, n)) for p in (a0, b0, b1, a1)]
        mesh.quad(ids[0], ids[3], ids[2], ids[1])
    top = [mesh.vertex(p, (0, 1, 0), colour_at(p, (0, 1, 0))) for p in pts1]
    mesh.quad(top[0], top[3], top[2], top[1])


def column(kind, spec, light, albedo, capital_albedo):
    """One column from the waterline up to its impost, by capital kind:
    'C' a carved Corinthian capital, 'P' a plain block (most of the
    cistern's capitals are unfinished blanks, often mislabelled Doric),
    'W' the weeping column (Corinthian, its shaft UV-mapped for its
    pattern), 'S' a short shaft with a plain capital on a carved base (the
    Medusa columns: base height spec['baseHeight'])."""
    m = Mesh()
    yw = spec['waterLevel']
    top = spec['columnHeight']          # top of the capital, from the floor
    impost = spec['impostHeight']
    r0, r1 = spec['shaftRadius']
    sides = spec['sides']
    cap_h = {'C': 0.85, 'P': 0.55, 'W': 0.85, 'S': 0.55}[kind]
    foot = yw + (spec['baseHeight'] if kind == 'S' else 0.0)

    def shaft_colour(p, n):
        return light.shade(albedo, light.column(p, n))

    def cap_colour(p, n):
        return light.shade(capital_albedo, light.column(p, n), gain=1.15)

    # Torus-like foot moulding where the shaft leaves the water (or the base).
    ring(m, foot, r0 * 1.22, foot + 0.12, r0 * 1.22, sides, shaft_colour)
    ring(m, foot + 0.12, r0 * 1.22, foot + 0.22, r0, sides, shaft_colour)
    shaft_top = top - cap_h
    rows = 4
    for k in range(rows):
        y0 = foot + 0.22 + (shaft_top - foot - 0.22) * k / rows
        y1 = foot + 0.22 + (shaft_top - foot - 0.22) * (k + 1) / rows
        ra = r0 + (r1 - r0) * k / rows
        rb = r0 + (r1 - r0) * (k + 1) / rows
        ring(m, y0, ra, y1, rb, sides, shaft_colour, uv_v=(k / rows, (k + 1) / rows))
    # Astragal.
    ring(m, shaft_top, r1 * 1.12, shaft_top + 0.06, r1 * 1.12, sides, cap_colour)
    y = shaft_top + 0.06
    if kind in ('C', 'W'):
        # A bell flaring to the abacus with two rows of leaves, drawn as
        # outward-tilted blades.
        ring(m, y, r1, top - 0.14, r1 * 1.45, sides, cap_colour)
        for row, (ya, yb, tilt) in enumerate([(y, y + 0.32, 0.16), (y + 0.22, y + 0.56, 0.22)]):
            for i in range(8):
                a = 2 * math.pi * (i + 0.5 * row) / 8
                ca, sa = math.cos(a), math.sin(a)
                w = 0.13
                base_r = r1 * (1.02 + 0.2 * row)
                tip_r = base_r + tilt
                tx, tz = -sa * w, ca * w
                p0 = (base_r * ca - tx, ya, base_r * sa - tz)
                p1 = (base_r * ca + tx, ya, base_r * sa + tz)
                p2 = (tip_r * ca, yb, tip_r * sa)
                n = (ca, 0.5, sa)
                ids = [m.vertex(p, n, cap_colour(p, _unit(n))) for p in (p0, p1, p2)]
                m.tri(ids[0], ids[2], ids[1])
                m.tri(ids[0], ids[1], ids[2])
        frustum_box(m, top - 0.14, r1 * 1.5, top, r1 * 1.62, cap_colour)
    elif kind == 'I':
        # Echinus and a pair of volutes along x under a thin abacus.
        ring(m, y, r1 * 1.05, y + 0.18, r1 * 1.3, sides, cap_colour)
        for side in (-1, 1):
            for j in range(10):
                a0 = 2 * math.pi * j / 10
                a1 = 2 * math.pi * (j + 1) / 10
                cy, cz = y + 0.22, 0.0
                rad = 0.12
                x0, x1 = side * r1 * 1.0, side * r1 * 1.55
                pts = [(x0, cy + rad * math.sin(a0), cz + rad * math.cos(a0)),
                       (x1, cy + rad * math.sin(a0), cz + rad * math.cos(a0)),
                       (x1, cy + rad * math.sin(a1), cz + rad * math.cos(a1)),
                       (x0, cy + rad * math.sin(a1), cz + rad * math.cos(a1))]
                nm = (0.0, math.sin((a0 + a1) / 2), math.cos((a0 + a1) / 2))
                ids = [m.vertex(p, nm, cap_colour(p, _unit(nm))) for p in pts]
                if side > 0:
                    m.quad(ids[0], ids[3], ids[2], ids[1])
                else:
                    m.quad(ids[0], ids[1], ids[2], ids[3])
            # The volute's eye, a disc on its outer face.
            centre = m.vertex((side * r1 * 1.55, y + 0.22, 0), (side, 0, 0),
                              cap_colour((side * r1 * 1.55, y + 0.22, 0), (side, 0, 0)))
            rim = [m.vertex((side * r1 * 1.55, y + 0.22 + 0.12 * math.sin(2 * math.pi * j / 10),
                             0.12 * math.cos(2 * math.pi * j / 10)), (side, 0, 0),
                            cap_colour((side * r1 * 1.55, y + 0.22, 0), (side, 0, 0)))
                   for j in range(10)]
            for j in range(10):
                if side > 0:
                    m.tri(centre, rim[j], rim[(j + 1) % 10])
                else:
                    m.tri(centre, rim[(j + 1) % 10], rim[j])
        frustum_box(m, top - 0.08, r1 * 1.55, top, r1 * 1.6, cap_colour)
    else:  # 'P', 'S': a plain block, square on a round neck, never carved
        ring(m, y, r1 * 1.02, y + 0.08, r1 * 1.02, sides, cap_colour)
        frustum_box(m, y + 0.08, r1 * 1.12, top, r1 * 1.55, cap_colour)
    # The impost block the arches spring from.
    frustum_box(m, top, r1 * 1.55, top + impost, r1 * 1.85, cap_colour)
    return m


def bay(spec, light, albedo, arch_albedo):
    """One groin-vault bay between four columns, centred on the origin:
    four webs, each a slice of a barrel vault; the arch bands along its
    edges are lighter brick. Seen from below."""
    m = Mesh()
    px, pz = spec['pitch']
    hs = spec['columnHeight'] + spec['impostHeight']
    rise = spec['vaultRise']
    hx, hz = px / 2, pz / 2
    corners = [(-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)]
    s_steps = [0.0, 0.42, 0.72, 0.9, 1.0]
    t_steps = 4
    band = 0.9

    def height(u, v, web):
        # Web E/W (|u| >= |v|) belongs to the barrel along x (its section in v).
        w = v if web in ('E', 'W') else u
        return hs + rise * math.sqrt(max(0.0, 1.0 - w * w))

    def normal(u, v, web):
        w = v if web in ('E', 'W') else u
        k = max(1e-3, math.sqrt(max(1e-6, 1.0 - w * w)))
        d = -rise * w / k  # dy/dw
        if web in ('E', 'W'):
            return (0.0, -1.0, d / hz)
        return (d / hx, -1.0, 0.0)

    for web in ('E', 'N', 'W', 'S'):
        grid = []
        for s in s_steps:
            row = []
            for k in range(t_steps + 1):
                t = -1.0 + 2.0 * k / t_steps
                u, v = {'E': (s, t * s), 'W': (-s, t * s), 'N': (t * s, s), 'S': (t * s, -s)}[web]
                p = (u * hx, height(u, v, web), v * hz)
                n = _unit(normal(u, v, web))
                tone = arch_albedo if s >= band else albedo
                k_light = light.bay(p, n, corners)
                row.append(m.vertex(p, n, light.shade(tone, k_light)))
            grid.append(row)
        for i in range(len(s_steps) - 1):
            for k in range(t_steps):
                a, b = grid[i][k], grid[i][k + 1]
                c, d = grid[i + 1][k + 1], grid[i + 1][k]
                # Facing down (into the room): order so the normal is -y.
                if web in ('E', 'N'):
                    m.quad(a, d, c, b)
                else:
                    m.quad(a, b, c, d)
    return m


def wall_segment(spec, light, albedo, length, pitch_other):
    """A wall face one bay wide (centred on x = 0, facing +z), from the
    waterline to the vault's lunette, with a pilaster at each end."""
    m = Mesh()
    yw = spec['waterLevel']
    hs = spec['columnHeight'] + spec['impostHeight']
    rise = spec['vaultRise']
    h = length / 2
    n = (0.0, 0.0, 1.0)

    def colour(p, nn):
        # Lit by the pilaster lamps at both ends (the corner columns' light).
        k = light.bay(p, nn, [(-h, 0.4), (h, 0.4)]) * 0.8
        return light.shade(albedo, k)

    steps = 8
    bottom = [m.vertex((-h + length * i / steps, yw, 0), n,
                       colour((-h + length * i / steps, yw, 0), n)) for i in range(steps + 1)]
    mid = [m.vertex((-h + length * i / steps, hs, 0), n,
                    colour((-h + length * i / steps, hs, 0), n)) for i in range(steps + 1)]
    arch = []
    for i in range(steps + 1):
        u = -1 + 2 * i / steps
        x = u * h
        y = hs + rise * math.sqrt(max(0.0, 1 - u * u))
        arch.append(m.vertex((x, y, 0), n, colour((x, y, 0), n)))
    for i in range(steps):
        m.quad(bottom[i], bottom[i + 1], mid[i + 1], mid[i])
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


def walkway(points, spec, deck_colour, rail_colour, strip_colour):
    """A deck along a polyline (x, z) at spec['deckHeight'], with handrails
    and a lit strip under each rail."""
    m = Mesh()
    y = spec['deckHeight']
    half = spec['deckWidth'] / 2
    pts = [np.array(p, dtype=np.float64) for p in points]
    for a, b in zip(pts, pts[1:]):
        d = b - a
        length = float(np.linalg.norm(d))
        if length < 1e-6:
            continue
        t = d / length
        side = np.array([-t[1], t[0]])
        # Extend each segment by half a width so corners close.
        a2, b2 = a - t * half, b + t * half
        quad = [a2 - side * half, b2 - side * half, b2 + side * half, a2 + side * half]
        ids = [m.vertex((q[0], y, q[1]), (0, 1, 0), deck_colour) for q in quad]
        m.quad(ids[0], ids[3], ids[2], ids[1])
        # Deck edge faces.
        for sgn in (-1, 1):
            e0, e1 = a2 + side * half * sgn, b2 + side * half * sgn
            n = (side[0] * sgn, 0, side[1] * sgn)
            f = [m.vertex((e0[0], y, e0[1]), n, deck_colour),
                 m.vertex((e1[0], y, e1[1]), n, deck_colour),
                 m.vertex((e1[0], y - 0.18, e1[1]), n, strip_colour),
                 m.vertex((e0[0], y - 0.18, e0[1]), n, strip_colour)]
            if sgn > 0:
                m.quad(f[0], f[3], f[2], f[1])
            else:
                m.quad(f[0], f[1], f[2], f[3])
            # Handrail: a thin bar at 1 m, both faces.
            r0, r1 = a + side * (half - 0.05) * sgn, b + side * (half - 0.05) * sgn
            for (h0, h1, col) in [(y + 0.95, y + 1.0, rail_colour), (y + 0.06, y + 0.1, strip_colour)]:
                g = [m.vertex((r0[0], h0, r0[1]), n, col), m.vertex((r1[0], h0, r1[1]), n, col),
                     m.vertex((r1[0], h1, r1[1]), n, col), m.vertex((r0[0], h1, r0[1]), n, col)]
                m.quad(g[0], g[1], g[2], g[3])
                m.quad(g[0], g[3], g[2], g[1])
            # Posts every 2.5 m.
            count = max(1, int(length / 2.5))
            for k in range(count + 1):
                p = r0 + (r1 - r0) * (k / count)
                for (dx, dz) in [(0.025, 0), (0, 0.025)]:
                    g = [m.vertex((p[0] - dx, y, p[1] - dz), n, rail_colour),
                         m.vertex((p[0] + dx, y, p[1] + dz), n, rail_colour),
                         m.vertex((p[0] + dx, y + 0.97, p[1] + dz), n, rail_colour),
                         m.vertex((p[0] - dx, y + 0.97, p[1] - dz), n, rail_colour)]
                    m.quad(g[0], g[1], g[2], g[3])
                    m.quad(g[0], g[3], g[2], g[1])
    return m


def stair(x, z, direction, spec, steps, rise, run, width, colour):
    """A straight flight from the deck up toward `direction` (+1 along x or
    -1), at the wall z, ending in a lit doorway."""
    m = Mesh()
    y0 = spec['deckHeight']
    for i in range(steps):
        x0 = x + direction * run * i
        x1 = x0 + direction * run
        ya, yb = y0 + rise * i, y0 + rise * (i + 1)
        lo, hi = sorted([x0, x1])
        box(m, lo, hi, ya, yb, z - width / 2, z + width / 2,
            lambda p, n: tuple(c * (0.55 + 0.45 * (1 - i / steps)) for c in colour),
            faces=('py', 'nx' if direction > 0 else 'px', 'pz', 'nz'))
    return m


def carved_base(spec, light, albedo, face_axis, size):
    """A carved block a column stands on (the Medusa heads): its front face,
    toward +z, UV-mapped for a photograph; the other faces plain stone."""
    m = Mesh()
    yw = spec['waterLevel']
    w, h, d = size

    def colour(p, n):
        return light.shade(albedo, light.column((p[0], p[1], p[2]), n) + 0.6)

    box(m, -w / 2, w / 2, yw, yw + h, -d / 2, d / 2, colour, faces=('px', 'nx', 'py', 'nz'))
    face = Mesh()
    n = (0, 0, 1)
    white = (1.0, 1.0, 1.0)
    ids = [face.vertex((x, y, d / 2), n, white, uv)
           for (x, y, uv) in [(-w / 2, yw, (0, 1)), (w / 2, yw, (1, 1)),
                              (w / 2, yw + h, (1, 0)), (-w / 2, yw + h, (0, 0))]]
    face.quad(ids[0], ids[1], ids[2], ids[3])
    return m, face


def fish(length, colour, belly):
    """A low carp: a lozenge body of 6 rings and a forked tail, nose +x."""
    m = Mesh()
    profile = [(0.0, 0.0), (0.12, 0.06), (0.35, 0.09), (0.6, 0.075), (0.82, 0.04), (0.9, 0.02)]
    sides = 6
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
