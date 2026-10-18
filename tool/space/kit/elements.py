"""The P09 kit: Istanbul's building elements as closed solids.

Each generator takes dimensions in metres (and counts), builds the element in
its own frame and returns {suffix: (V, F)}: '' is the element, other keys are
pieces that can be assembled separately (a dome's '-windows'). Frames: an
element stands on z = 0 at the origin; arches, arcades, porticoes, walls and
curtains run along +x; semi-domes, exedrae and squinches open toward −y (their
backs bulge toward +y); domes, columns, minarets and towers are centred.
`kit/spec.py` places them from a YAML spec. `step` is the longest face edge
wanted; `n`-style counts are the fewest segments a circle gets.
"""
import math

import numpy as np

from .shapes import (TAU, arch_curve, band, block, finish, loft, place, polygon_at,
                     prism, rect, regular, revolve, shell, strip, union)

HALF = math.pi / 2


def segments(radius, step, least=8, multiple=4):
    n = max(least, int(math.ceil(TAU * radius / step)))
    return int(math.ceil(n / multiple) * multiple)


def ring_sector(r0, r1, a0, a1, z0, z1, step=2.0, sides=0, phase=0.0, name='sector',
                inner_sides=None):
    """The part of a round (or `sides`-gon) ring wall between angles a0 < a1;
    `inner_sides` gives the inside its own shape (an apse round inside,
    polygonal outside). With r0 = 0 the sector is solid."""
    k = max(1, int(math.ceil((a1 - a0) * r1 / step)))
    angles = list(a0 + (a1 - a0) * np.arange(k + 1) / k)
    if sides:
        w = TAU / sides
        corners = [phase + w * i for i in range(-sides, 2 * sides)]
        angles = sorted(angles + [c for c in corners if a0 < c < a1
                                  and min(abs(c - a) for a in angles) > 1e-7])
    outer = polygon_at(angles, sides, r1, phase)
    if r0 <= 0:
        return prism(np.concatenate([outer, [(0.0, 0.0)]]), z0, z1, step, name)
    inner_sides = sides if inner_sides is None else inner_sides
    inner = polygon_at(angles[::-1], inner_sides, r0, phase)
    return prism(np.concatenate([outer, inner]), z0, z1, step, name)


def ring(r0, r1, z0, z1, step=2.0, sides=0, phase=0.0, n=None, name='ring'):
    """A full round (or `sides`-gon) ring wall: a cornice, a drum, a rim."""
    n = sides or n or segments(r1, step, 16, 8)
    angles = phase + TAU * np.arange(n) / n
    return band(polygon_at(angles, sides, r1, phase), polygon_at(angles, sides, r0, phase),
                z0, z1, step, name)


def wall_with_openings(r0, r1, z0, z1, openings, sill, head, share=.5, phase=0.0,
                       arc=(0.0, TAU), step=2.0, sides=0, name='wall', inner_sides=None):
    """A ring wall (or an arc of one) with `openings` windows between `sill`
    and `head`, each `share` of its module wide, the first centred at `phase`
    (for a full ring) or half a module in (for an arc)."""
    a0, a1 = arc
    full = abs(a1 - a0 - TAU) < 1e-9
    pieces = []
    if not openings:
        return ring(r0, r1, z0, z1, step, sides, name=name) if full else \
            ring_sector(r0, r1, a0, a1, z0, z1, step, sides, name=name, inner_sides=inner_sides)

    def whole(za, zb):
        if zb - za <= 1e-6:
            return None
        return ring(r0, r1, za, zb, step, sides, phase=phase if sides else 0.0) if full else \
            ring_sector(r0, r1, a0, a1, za, zb, step, sides, name=name, inner_sides=inner_sides)

    pieces += [whole(z0, sill), whole(head, z1)]
    module = (a1 - a0) / openings
    half = module * share / 2
    centres = [phase + module * i for i in range(openings)] if full else \
        [a0 + module * (i + .5) for i in range(openings)]
    for i, c in enumerate(centres):
        start = c + half
        end = (centres[i + 1] if i + 1 < len(centres) else (centres[0] + TAU if full else None))
        if end is not None:
            pieces.append(ring_sector(r0, r1, start, end - half, sill, head, step, sides, phase, name,
                                      inner_sides))
    if not full:
        pieces.append(ring_sector(r0, r1, a0, centres[0] - half, sill, head, step, sides, phase, name,
                                  inner_sides))
        pieces.append(ring_sector(r0, r1, centres[-1] + half, a1, sill, head, step, sides, phase, name,
                                  inner_sides))
    return union(*pieces)


def dome(radius, thickness=1.0, windows=0, band=None, share=.55, phase=0.0, ribs=0,
         rib=(.6, .45), gores=0, gore_depth=.1, alternate=True, drum=None, n=None, rows=None,
         step=2.0):
    """A hemispherical dome of inner `radius` springing at z = 0.

    windows: openings in a band `band` high at the base, between piers that
    carry the shell (share = opening's part of each module), the first
    centred at `phase`. ribs: meridian ribs (width, depth) under the shell,
    centred on the piers. gores: a melon dome of that many segments, every
    other one bulging out by gore_depth × radius (the windows sit in the flat
    ones; with alternate false every gore is a concave cell, an umbrella).
    drum: {height, thickness, windows, sill, head, share, buttresses:
    {depth, width}} a cylinder from −height to 0 under the dome, triangular
    buttresses standing between its windows."""
    out = {}
    r0, r1 = radius, radius + thickness
    n = n or segments(r1, step, 24, 8)
    fn = None
    if gores:
        n = gores * max(4, int(math.ceil(n / gores)))
        w = TAU / gores

        def fn(t, f):
            u = ((t - phase + w / 2) % TAU) / w
            k = int(math.floor(u + 1e-9))
            bulge = math.sin(math.pi * (u - k)) if (k % 2 or not alternate) else 0.0
            return 1 + gore_depth * bulge * math.cos(f)
    nf = rows or max(4, int(math.ceil(HALF * r1 / step)))
    fb = math.asin(min(.9, (band or radius * .25) / radius)) if windows else 0.0
    out[''] = shell((0, 0, 0), r0, r1, (0, TAU), (fb, HALF), n,
                    rows or max(3, int(math.ceil(nf * (HALF - fb) / HALF))), 'dome', fn)
    if windows:
        module = TAU / windows
        hw = module * (1 - share) / 2
        rows = max(1, int(math.ceil(r1 * fb / step)))
        k = max(1 if n < 24 or windows > 16 else 2, int(math.ceil(2 * hw * r1 / step)))
        out['-windows'] = union(*[
            shell((0, 0, 0), r0, r1, (c - hw, c + hw), (0, fb), k, rows, 'window pier', fn)
            for c in (phase + module * (i + .5) for i in range(windows))])
    if ribs:
        width, depth = rib
        hw = width / 2 / r0
        out['-ribs'] = union(*[
            shell((0, 0, 0), r0 - depth, r0 + .01, (c - hw, c + hw), (fb, math.radians(80)), 1,
                  max(3, nf - 1), 'rib', fn)
            for c in (phase + TAU / ribs * (i + .5) for i in range(ribs))])
    if drum:
        h = drum['height']
        t = drum.get('thickness', thickness)
        wall = wall_with_openings(
            r0, r0 + t, -h, 0, drum.get('windows', 0), -h + drum.get('sill', h * .2),
            -h + drum.get('head', h * .85), drum.get('share', .5), phase, step=step,
            sides=drum.get('sides', 0), name='drum')
        spurs = []
        if drum.get('buttresses'):
            depth, width = drum['buttresses']['depth'], drum['buttresses']['width']
            n_w = max(1, drum.get('windows', 8))
            base = r0 + t - .02
            for i in range(n_w):
                a = phase + TAU / n_w * (i + .5)
                c, sn = math.cos(a), math.sin(a)
                tri = [(base * c - width / 2 * -sn, base * sn - width / 2 * c),
                       ((base + depth + .02) * c, (base + depth + .02) * sn),
                       (base * c + width / 2 * -sn, base * sn + width / 2 * c)]
                spurs.append(prism(tri, -h, 0, step, 'drum buttress'))
        out['-drum'] = union(wall, *spurs)
    return out


def semidome(radius, thickness=1.0, windows=0, band=None, share=.55, n=None, rows=None,
             step=2.0):
    """Half a dome of inner `radius` springing at z = 0, open toward −y, its
    back toward +y; `windows` in a base band, as for `dome`."""
    r0, r1 = radius, radius + thickness
    n = n or segments(r1, step, 16, 8) // 2
    nf = rows or max(4, int(math.ceil(HALF * r1 / step)))
    fb = math.asin(min(.9, (band or radius * .25) / radius)) if windows else 0.0
    out = {'': shell((0, 0, 0), r0, r1, (0, math.pi), (fb, HALF), n,
                     rows or max(3, int(math.ceil(nf * (HALF - fb) / HALF))), 'semi-dome')}
    if windows:
        module = math.pi / windows
        hw = module * (1 - share) / 2
        rows = max(1, int(math.ceil(r1 * fb / step)))
        piers = []
        for i in range(windows + 1):
            c = module * i
            a, b = max(0.0, c - hw), min(math.pi, c + hw)
            piers.append(shell((0, 0, 0), r0, r1, (a, b), (0, fb),
                               max(1, int(math.ceil((b - a) * r1 / step))), rows, 'window pier'))
        out['-windows'] = union(*piers)
    return out


def exedra(radius, height, thickness=1.0, windows=0, sill=None, head=None, share=.5,
           columns=0, column=None, beam=1.2, cap=True, cap_thickness=None, outer_sides=0,
           solid=False, cap_segments=None, step=2.0):
    """A half-round niche: its wall (or a column arcade under a beam) from
    z = 0 to `height`, open toward −y, and its half-dome cap (`-cap`). An
    apse: `outer_sides` makes the outside polygonal (6: three faces on the
    half), `solid` fills it (a foundation under an apse)."""
    out = {}
    if columns:
        c = column or {}
        d = c.get('diameter', thickness * .8)
        pieces = [ring_sector(radius, radius + thickness, 0, math.pi, height - beam, height, step,
                              name='exedra beam')]
        for i in range(columns):
            t = math.pi * (i + 1) / (columns + 1)
            col = column_solid(height - beam, d, c.get('capital', 'impost'), step, c.get('n', 8))
            pieces.append(place(col, (radius + thickness / 2) * math.cos(t),
                                (radius + thickness / 2) * math.sin(t)))
        out[''] = union(*pieces)
    elif solid:
        r1 = (radius + thickness) / (math.cos(math.pi / outer_sides) if outer_sides else 1)
        out[''] = ring_sector(0, r1, 0, math.pi, 0, height, step, outer_sides, name='apse')
    else:
        r1 = (radius + thickness) / (math.cos(math.pi / outer_sides) if outer_sides else 1)
        out[''] = wall_with_openings(radius, r1, 0, height, windows,
                                     sill if sill is not None else height * .4,
                                     head if head is not None else height * .8,
                                     share, arc=(0, math.pi), step=step, name='exedra',
                                     sides=outer_sides, inner_sides=0)
    if cap:
        out['-cap'] = {k: place(v, z=height) for k, v in
                       semidome(radius, cap_thickness or thickness, n=cap_segments,
                                rows=3 if cap_segments else None, step=step).items()}['']
    return out


def pendentives(half, top, nu=None, step=2.0):
    """The four pendentives of a square bay [−h, h]² springing at z = 0:
    one sphere of radius h√2 inside the square and outside the inscribed
    circle, filled up to `top` (≥ h, the arches' crown)."""
    R = half * math.sqrt(2)
    coarse = nu is not None
    nu = nu or max(4, int(math.ceil(HALF * half / step))) // 2 * 2
    nv, nz = (2, 1) if coarse else (3, max(2, int(math.ceil((top - half) / step)) + 1))

    def z_of(x, y):
        return np.sqrt(np.maximum(R * R - x * x - y * y, 0))

    def plan(u, v):
        t = u * HALF
        rmax = half / np.maximum(np.cos(t), np.sin(t))
        r = half + v * (rmax - half)
        return r * np.cos(t), r * np.sin(t)

    from solid import surface, solid

    def build():
        def bottom(u, v):
            x, y = plan(u, v)
            return np.stack([x, y, z_of(x, y)], -1)

        def top_face(u, v):
            x, y = plan(u, v)
            return np.stack([x, y, top + 0 * x], -1)

        def inner(u, w):
            t = u * HALF
            x, y = half * np.cos(t), half * np.sin(t)
            z0 = z_of(x, y)
            return np.stack([x, y, z0 + w * (top - z0)], -1)

        def side_x(u, w):
            y = half * np.tan(u * math.pi / 4)
            x = half + 0 * y
            z0 = z_of(x, y)
            return np.stack([x, y, z0 + w * (top - z0)], -1)

        def side_y(u, w):
            x = half / np.tan(math.pi / 4 + u * math.pi / 4)
            y = half + 0 * x
            z0 = z_of(x, y)
            return np.stack([x, y, z0 + w * (top - z0)], -1)

        const = lambda n: (lambda p: np.broadcast_to(n, p.shape))  # noqa: E731
        return solid(
            surface(bottom, nu, nv, lambda p: -p),
            surface(top_face, nu, nv, const((0, 0, 1))),
            surface(inner, nu, nz, lambda p: -p * np.array([1, 1, 0])),
            surface(side_x, nu // 2, nz, const((1, 0, 0))),
            surface(side_y, nu // 2, nz, const((0, 1, 0))),
            name='pendentive')

    one = finish(*build(), 'pendentive')
    return {'': union(*[place(one, turn=HALF * q) for q in range(4)])}


def squinch(span, thickness=.8, step=2.0):
    """A squinch: an arch across a corner with a half-dome niche behind it,
    open toward −y like `semidome` (place it on the corner, turned 45°)."""
    out = {'': semidome(span / 2, thickness, step=step)['']}
    out['-arch'] = arch_ring(span, thickness, thickness, step=step)['']
    return out


def arch_ring(span, thickness, depth, kind='round', rise=None, pointed=1 / 3, n=None, step=2.0):
    """An arch ring over x ∈ [−s/2, s/2], springing at z = 0, depth along y
    centred on y = 0. A pointed arch's centres sit `pointed` × half-span from
    the middle (0.146 gives a 19 m arch a 10.8 m rise)."""
    n = n or max(8, int(math.ceil(math.pi * span / 2 / step)) // 2 * 2)
    inner = arch_curve(span, kind, rise, n, pointed=pointed)
    outer = arch_curve(span, kind, rise, n, offset=thickness, pointed=pointed)
    return {'': strip(inner, outer, -depth / 2, depth / 2, 'arch')}


def arched_panel(span, top, depth, margin=0.0, kind='round', rise=None, n=None, step=2.0):
    """A wall panel with an arched opening: the arch and its spandrels from
    the springing (z = 0) up to `top`, `margin` of wall on either side."""
    n = n or max(8, int(math.ceil(math.pi * span / 2 / step)) // 2 * 2)
    inner = arch_curve(span, kind, rise, n)
    x0, x1 = -span / 2 - margin, span / 2 + margin
    outer = []
    for p in inner:                         # each intrados point's ray from
        a = math.atan2(p[1], p[0])           # the springing centre meets the
        c, s = math.cos(a), math.sin(a)      # panel's outline
        ts = [t for t in ((x0 / c) if c < -1e-9 else None, (x1 / c) if c > 1e-9 else None,
                          (top / s) if s > 1e-9 else None) if t is not None and t > 0]
        t = min(ts)
        outer.append((t * c, t * s))
    outer[0], outer[-1] = (x0, 0.0), (x1, 0.0)
    return {'': strip(inner, np.asarray(outer), -depth / 2, depth / 2, 'arched panel')}


def column_solid(height, diameter, capital='corinthian', step=2.0, n=12, lite=False):
    """One column: plinth, moulded base, tapering shaft and capital, as
    disjoint touching solids. Capitals: corinthian (acanthus bell under a
    concave abacus), impost (an inverted pyramid, circle to square), basket
    (a bulging woven bowl), muqarnas (stepped stalactite tiers), lozenge
    (Ottoman faceted diamonds), melon (a lobed bowl). `lite` drops the
    moulded base and thins the corinthian, muqarnas and lozenge capitals: for
    long colonnades."""
    D = diameter
    r = D / 2
    plinth_h, base_h = .2 * D, .25 * D
    cap_h = {'corinthian': 1.1, 'impost': .85, 'basket': .9, 'muqarnas': 1.2,
             'lozenge': 1.0, 'melon': .9}[capital] * D
    shaft_top = height - cap_h
    if shaft_top <= plinth_h + base_h:
        raise ValueError('column too short for its capital')
    angles = TAU * np.arange(n) / n
    pieces = [block(-.65 * D, .65 * D, -.65 * D, .65 * D, 0, plinth_h, step, 'plinth')]
    if not lite:
        pieces.append(revolve([(0, plinth_h), (.62 * D, plinth_h), (.6 * D, plinth_h + base_h * .45),
                               (.52 * D, plinth_h + base_h * .6), (.55 * D, plinth_h + base_h),
                               (0, plinth_h + base_h)], n, step, name='base'))
    z0 = plinth_h + (0 if lite else base_h)
    pieces.append(revolve([(0, z0), (r, z0), (r * .97, z0 + (shaft_top - z0) * .4),
                           (r * .86, shaft_top), (0, shaft_top)], n, step, name='shaft'))
    neck = r * .86
    side = 1.25 * D if capital != 'lozenge' else 1.1 * D

    def circle(rad, phase=0.0):
        return polygon_at(angles + phase, 0, rad)

    def square(half):
        return polygon_at(angles, 4, half * math.sqrt(2), math.pi / 4)

    z, h = shaft_top, cap_h
    if lite and capital in ('corinthian', 'muqarnas'):
        rings = [(circle(neck), z), (square(side / 2) * .62 + circle(neck) * .38, z + .55 * h),
                 (square(side / 2), z + h)]
    elif capital == 'corinthian':
        def lobed(rad, k):
            return np.stack([rad * (1 + .14 * np.cos(k * angles)) * np.cos(angles),
                             rad * (1 + .14 * np.cos(k * angles)) * np.sin(angles)], 1)
        rings = [(circle(neck), z), (lobed(neck * 1.15, 8), z + .3 * h),
                 (lobed(neck * 1.3, 8), z + .55 * h), (circle(neck * 1.25), z + .8 * h),
                 (square(side / 2) * .92, z + .8 * h), (square(side / 2), z + h)]
    elif capital == 'impost':
        rings = [(circle(neck), z), (square(side / 2) * .55 + circle(neck) * .45, z + .5 * h),
                 (square(side / 2), z + h)]
    elif capital == 'basket':
        weave = 1 + .05 * np.cos(2 * n // 4 * angles)
        rings = [(circle(neck), z), (circle(neck * 1.35) * weave[:, None], z + .45 * h),
                 (square(side / 2) * .9, z + .85 * h), (square(side / 2), z + h)]
    elif capital == 'melon':
        lobes = 1 + .12 * np.abs(np.cos(n // 2 * angles / 2))
        rings = [(circle(neck), z), (circle(neck * 1.3) * lobes[:, None], z + .5 * h),
                 (square(side / 2) * .85, z + .85 * h), (square(side / 2), z + h)]
    elif capital == 'muqarnas':
        tiers, rings = 3, [(circle(neck), z)]
        for k in range(tiers):
            t0, t1 = z + h * k / tiers, z + h * (k + 1) / tiers
            mix = (k + 1) / tiers
            star = 1 + .08 * np.cos(n // 2 * angles) * (1 - mix)
            shape = (circle(neck) * (1 - mix) + square(side / 2) * mix) * star[:, None]
            if k:
                rings.append((shape * .93, t0))
            rings.append((shape, t1))
    else:  # lozenge
        zig = 1 + .1 * np.where(np.arange(n) % 2, 1.0, -1.0)
        rings = [(circle(neck), z), (circle(neck * 1.15) * zig[:, None], z + .35 * h),
                 (square(side / 2) * .9 * zig[::-1, None], z + .7 * h), (square(side / 2), z + h)]
        if lite:
            rings = [rings[0], (circle(neck * 1.2) * zig[:, None], z + .5 * h), rings[3]]
    pieces.append(loft(rings, step, 'capital'))
    return union(*pieces)


def column(height, diameter, capital='corinthian', n=12, lite=False, step=2.0):
    return {'': column_solid(height, diameter, capital, step, n, lite)}


def pier(width, depth, height, kind='rect', step=2.0):
    """A pier: rect, cruciform (a cross of arms a third of the width) or
    octagonal, centred on the origin."""
    if kind == 'rect':
        return {'': block(-width / 2, width / 2, -depth / 2, depth / 2, 0, height, step, 'pier')}
    if kind == 'octagonal':
        return {'': prism(regular(8, width / 2 / math.cos(math.pi / 8), math.pi / 8), 0, height,
                          step, 'pier')}
    a, b = width / 6, depth / 6
    w, d = width / 2, depth / 2
    cross = [(-a, -d), (a, -d), (a, -b), (w, -b), (w, b), (a, b), (a, d), (-a, d), (-a, b),
             (-w, b), (-w, -b), (-a, -b)]
    return {'': prism(cross, 0, height, step, 'pier')}


def buttress(width, depth, height, kind='rect', steps=2, step=2.0):
    """A buttress against a wall at y = 0, projecting toward −y: rect,
    stepped (narrowing in `steps` set-offs) or half-round (a half cylinder of
    diameter `width`)."""
    if kind == 'half-round':
        V, F = revolve([(0, 0), (width / 2, 0), (width / 2, height), (0, height)],
                       segments(width / 2, step, 16, 4), step, arc=(math.pi, TAU), name='buttress')
        return {'': (V, F)}
    if kind == 'rect':
        return {'': block(-width / 2, width / 2, -depth, 0, 0, height, step, 'buttress')}
    profile = [(0, 0)]                   # (y, z) outline, stepping back up
    for k in range(steps):
        y = -depth * (1 - k / steps)
        z = height * k / steps
        profile += [(y, z), (y, height * (k + 1) / steps)]
    profile += [(0, height)]
    profile = [(0, 0), (-depth, 0)] + profile[2:]
    P = np.asarray(profile)
    V, F = prism(np.stack([P[:, 0], P[:, 1]], 1), -width / 2, width / 2, step, 'buttress')
    return {'': finish(np.stack([V[:, 2], V[:, 0], V[:, 1]], 1), F, 'buttress')}


def minaret(base, base_height, shaft_diameter, shaft_top, serefe, serefe_depth=1.0,
            corbel=1.6, parapet=1.0, petek=4.0, cap=6.0, finial=1.5, sides=16,
            shoe=2.5, tiers=3, step=2.0):
    """An Ottoman minaret on a square base (kürsü) `base` wide: a faceted
    transition (pabuç), a `sides`-gon shaft to `shaft_top`, a şerefe at each
    height in `serefe` (balcony floor levels) on muqarnas corbels, the
    narrower upper shaft (petek), a conical cap (külah) and a finial."""
    r = shaft_diameter / 2 / math.cos(math.pi / sides)
    phase = math.pi / sides
    corners = regular(sides, r, phase)
    square = polygon_at(np.arctan2(corners[:, 1], corners[:, 0]), 4, base / math.sqrt(2) * 1.0,
                        math.pi / 4)
    body = [block(-base / 2, base / 2, -base / 2, base / 2, 0, base_height, step, 'kürsü'),
            loft([(square * .98, base_height), (corners, base_height + shoe)], step, 'pabuç'),
            prism(corners, base_height + shoe, shaft_top, step, 'shaft')]
    balconies = []
    for z in serefe:
        outer = r + serefe_depth
        rings = [(regular(sides, r * .98, phase), z - corbel)]
        for k in range(tiers):
            t = (k + 1) / tiers
            star = 1 + .06 * np.cos(np.arange(sides) * math.pi) * (1 - t)
            rings.append((regular(sides, (r + (outer - r) * t), phase) * star[:, None],
                          z - corbel * (1 - t) - .001 * (k < tiers - 1)))
        rings.append((regular(sides, outer, phase), z + .25))   # the balcony floor
        balconies.append(loft(rings, step, 'corbel'))
        balconies.append(ring(outer - .15, outer, z + .25, z + .25 + parapet, step, sides, phase))
    top = max(serefe) + .25
    pr = r * .78
    head = [prism(regular(sides, pr, phase), top, top + petek, step, 'petek'),
            loft([(regular(sides, pr * 1.2, phase), top + petek),
                  (np.zeros((sides, 2)), top + petek + cap)], step, 'külah'),
            revolve([(0, top + petek + cap - .2), (.12, top + petek + cap - .2),
                     (.12, top + petek + cap + finial), (0, top + petek + cap + finial)], 8, step,
                    name='alem')]
    return {'': union(*body), '-serefe': union(*balconies), '-cap': union(*head)}


def bay_dome(half, spring, thickness=.6, step=2.0, drum=0.0, n=12, rows=3):
    """A small dome on pendentives over a square bay [−h, h]² whose arches
    spring at `spring`: four pendentives up to the crowns, an optional drum,
    a hemisphere of radius h, `n` segments round (kept coarse: porticoes
    repeat it)."""
    p = place(pendentives(half, half + thickness * .5, nu=2, step=step)[''], z=spring)
    z = spring + half + thickness * .5
    pieces = [p]
    if drum:
        pieces.append(ring(half, half + thickness, z, z + drum, step))
        z += drum
    pieces.append(place(dome(half, thickness, n=n, rows=rows, step=step)[''], z=z))
    return union(*pieces)


def portico(bays, bay, depth, spring, column=None, thickness=.8, wall=1.2, height=None,
            domes=True, vault=None, back=True, transverse=True, step=2.0):
    """A domed portico along +x: `bays` bays `bay` wide and `depth` deep,
    columns along y = 0, a back wall at y = depth (unless `back` is false:
    the portico leans on a building), arches springing at `spring` (front
    and transverse) and a small dome on pendentives over each bay (Ottoman
    son cemaat yeri, courtyard galleries), or with vault='barrel' a barrel
    vault along the portico over each bay."""
    c = column or {}
    d = c.get('diameter', .7)
    xs = [bay * i for i in range(bays + 1)]
    top = height or spring + depth / 2 + thickness
    cols = [place(column_solid(spring, d, c.get('capital', 'muqarnas'), step, c.get('n', 8), c.get('lite', True)), x, 0)
            for x in xs]
    arches = [place(arched_panel(bay - d, (bay - d) / 2 + thickness, thickness,
                                 d / 2, c.get('arch', 'pointed'), n=6, step=step)[''],
                    x + bay / 2, 0, spring) for x in xs[:-1]]
    if transverse:
        arches += [place(arch_ring(depth - d / 2 - wall / 2, thickness, thickness,
                                   c.get('arch', 'pointed'), n=6, step=step)[''],
                         x, depth / 2 - wall / 4, spring, HALF) for x in xs]
    out = {'': union(*cols), '-arches': union(*arches)}
    if back:
        out['-wall'] = block(xs[0] - d / 2, xs[-1] + d / 2, depth - wall / 2, depth + wall / 2, 0,
                             top, step, 'back wall')
    if vault == 'barrel':
        out['-vaults'] = union(*[place(arch_ring(depth - d / 2, thickness * .6, bay - d, n=6,
                                                 step=step)[''], x + bay / 2, depth / 2, spring, -HALF)
                                 for x in xs[:-1]])
    elif domes:
        h = min(bay, depth) / 2
        out['-domes'] = union(*[place(bay_dome(h * .9, 0, thickness * .6, step),
                                      x + bay / 2, depth / 2, spring) for x in xs[:-1]])
    return out


def sadirvan(radius, height=1.0, sides=8, columns=True, roof='cone', roof_height=3.0,
             column_height=3.5, step=2.0):
    """An ablution fountain: a `sides`-gon basin; with columns, a ring of
    columns under a conical or domed roof (`-roof`)."""
    corners = regular(sides, radius / math.cos(math.pi / sides), math.pi / sides)
    out = {'': union(prism(corners, 0, height, step, 'basin'),
                     prism(corners * .55, height, height + .6, step, 'fountain'))}
    if columns:
        cr = radius * 1.05
        pieces = [place(column_solid(column_height, .35, 'lozenge', step, 6, True), *p)
                  for p in regular(sides, cr, math.pi / sides)]
        eave = regular(sides, cr * 1.35 / math.cos(math.pi / sides), math.pi / sides)
        pieces.append(prism(eave, column_height, column_height + .35, step, 'eave'))
        if roof == 'cone':
            pieces.append(loft([(eave * .95, column_height + .35),
                                (np.zeros((sides, 2)), column_height + .35 + roof_height)], step, 'roof'))
        else:
            pieces.append(place(dome(cr * 1.1, .3, step=step)[''], z=column_height + .35))
        out['-roof'] = union(*pieces)
    return out


def courtyard(size, bays, spring, column=None, thickness=.8, wall=1.5, height=None,
              open_side=None, sadirvan_spec=None, dome_segments=12, dome_rows=3, step=2.0):
    """A square court `size` wide (outside the walls), ringed by domed
    porticoes: the court is a `bays` × `bays` grid whose outer ring of cells
    are domed bays; columns stand at the inner corners, transverse arches
    reach the outer wall, a şadırvan stands in the middle. `open_side`
    ('n', 'e', 's' or 'w') has no outer wall (it meets the mosque)."""
    c = column or {}
    d = c.get('diameter', .7)
    cell = size / bays
    h = size / 2
    top = height or spring + cell / 2 + thickness
    out = {}
    walls = []
    for side, (x0, x1, y0, y1) in {'s': (-h, h, -h, -h + wall), 'n': (-h, h, h - wall, h),
                                   'w': (-h, -h + wall, -h + wall, h - wall),
                                   'e': (h - wall, h, -h + wall, h - wall)}.items():
        if side != open_side:
            walls.append(block(x0, x1, y0, y1, 0, top, step, 'court wall'))
    out['-walls'] = union(*walls)
    inner = h - cell
    grid = [-inner + 2 * inner * k / (bays - 2) for k in range(bays - 1)]
    points = sorted({(x, y) for x in grid for y in grid if abs(x) == inner or abs(y) == inner})
    out[''] = union(*[place(column_solid(spring, d, c.get('capital', 'muqarnas'), step, c.get('n', 8), c.get('lite', True)),
                            x, y) for x, y in points])
    kind = c.get('arch', 'pointed')
    span = 2 * inner / (bays - 2)
    arches = []
    for k in range(bays - 2):                       # along the inner square
        a = -inner + span * (k + .5)
        for x, y, turn in ((a, -inner, 0), (a, inner, 0), (-inner, a, HALF), (inner, a, HALF)):
            arches.append(place(arched_panel(span - d, (span - d) / 2 + thickness, thickness, d / 2,
                                             kind, n=6, step=step)[''], x, y, spring, turn))
    reach = cell - wall
    for x, y in points:                             # out to the walls
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            if (dx and abs(x) == inner and np.sign(x) == dx) or (dy and abs(y) == inner and np.sign(y) == dy):
                arches.append(place(arch_ring(reach - d / 2, thickness, thickness, kind, n=6, step=step)[''],
                                    x + dx * (reach / 2 + d / 4), y + dy * (reach / 2 + d / 4), spring,
                                    HALF if dy else 0))
    out['-arches'] = union(*arches)
    centres = [-h + cell * (k + .5) for k in range(bays)]
    domes = [place(bay_dome(cell / 2 * .82, 0, thickness * .6, step, n=dome_segments, rows=dome_rows),
                   x, y, spring)
             for x in centres for y in centres
             if abs(x) > inner - 1e-6 or abs(y) > inner - 1e-6]
    out['-domes'] = union(*domes)
    if sadirvan_spec is not None:
        for k, v in sadirvan(step=step, **sadirvan_spec).items():
            out['-sadirvan' + k] = v
    return out


def cistern(nx, ny, bay, spring, column=None, wall=2.0, thickness=.6, step=2.0):
    """A columned cistern: nx × ny bays `bay` square, columns at the inner
    grid points, a sail vault over every bay springing at `spring`, walls
    around. Origin at the south-west inner corner."""
    c = column or {}
    d = c.get('diameter', .7)
    cols = [place(column_solid(spring, d, c.get('capital', 'impost'), step, c.get('n', 8), c.get('lite', True)), bay * i, bay * j)
            for i in range(1, nx) for j in range(1, ny)]
    half = bay / 2
    vault = sail_vault(half, thickness, step)
    vaults = [place(vault, bay * (i + .5), bay * (j + .5), spring) for i in range(nx) for j in range(ny)]
    X, Y = nx * bay, ny * bay
    top = spring + half * math.sqrt(2) + thickness
    walls = [block(-wall, X + wall, -wall, 0, 0, top, step, 'wall'),
             block(-wall, X + wall, Y, Y + wall, 0, top, step, 'wall'),
             block(-wall, 0, 0, Y, 0, top, step, 'wall'),
             block(X, X + wall, 0, Y, 0, top, step, 'wall')]
    return {'': union(*cols), '-vaults': union(*vaults), '-walls': union(*walls)}


def sail_vault(half, thickness, step=2.0):
    """A sail (domical) vault over [−h, h]² springing at z = 0: the sphere of
    radius h√2 cut by the square, filled to a flat top `thickness` above its
    crown."""
    R = half * math.sqrt(2)
    k = max(3, int(math.ceil(2 * half / step)))
    us = np.linspace(-half, half, k + 1)
    X, Y = np.meshgrid(us, us, indexing='ij')
    Z = np.sqrt(np.maximum(R * R - X * X - Y * Y, 0))
    top = R + thickness
    V = [(x, y, z) for x, y, z in zip(X.ravel(), Y.ravel(), Z.ravel())]
    V += [(x, y, top) for x, y in zip(X.ravel(), Y.ravel())]
    m = (k + 1) * (k + 1)
    F = []
    for i in range(k):
        for j in range(k):
            a, b, c, d = i * (k + 1) + j, (i + 1) * (k + 1) + j, (i + 1) * (k + 1) + j + 1, i * (k + 1) + j + 1
            F += [(a, c, b), (a, d, c), (m + a, m + b, m + c), (m + a, m + c, m + d)]
    edge = ([i * (k + 1) for i in range(k + 1)] + [k * (k + 1) + j for j in range(1, k + 1)]
            + [i * (k + 1) + k for i in range(k - 1, -1, -1)] + [j for j in range(k - 1, 0, -1)])
    for a, b in zip(edge, edge[1:] + edge[:1]):
        F += [(a, b, m + b), (a, m + b, m + a)]
    from .shapes import _orient_pieces
    return _orient_pieces(np.asarray(V), F, 'sail vault')


def curtain(length, height, thickness, merlons=None, step=2.0):
    """A wall curtain along +x from 0 to `length`, centred on y = 0, with
    merlons {width, gap, height} along its outer (−y) edge."""
    out = {'': block(0, length, -thickness / 2, thickness / 2, 0, height, step, 'curtain')}
    if merlons:
        w, g, h = merlons.get('width', 1.0), merlons.get('gap', .8), merlons.get('height', 1.4)
        k = int((length + g) // (w + g))
        x0 = (length - (k * w + (k - 1) * g)) / 2
        out['-merlons'] = union(*[
            block(x0 + i * (w + g), x0 + i * (w + g) + w, -thickness / 2, -thickness / 2 + .6, height,
                  height + h, step, 'merlon') for i in range(k)])
    return out


def tower(size, height, kind='square', sides=8, merlons=True, roof=0.0, step=2.0):
    """A tower `size` across: square, polygonal (`sides`) or round, with
    merlons or a conical roof `roof` high (`-roof`)."""
    if kind == 'square':
        body = block(-size / 2, size / 2, -size / 2, size / 2, 0, height, step, 'tower')
        rim = rect(0, 0, size, size)
    else:
        n = sides if kind == 'polygonal' else segments(size / 2, step, 12, 4)
        rim = regular(n, size / 2 / math.cos(math.pi / n), math.pi / n)
        body = prism(rim, 0, height, step, 'tower')
    out = {'': body}
    if roof:
        R = np.asarray(rim) * 1.08
        out['-roof'] = loft([(R, height), (np.zeros_like(R), height + roof)], step, 'roof')
    if merlons:
        corners = np.asarray(rim)
        pts = []
        for a, b in zip(corners, np.roll(corners, -1, axis=0)):
            k = max(1, int(np.linalg.norm(b - a) // 1.8))
            pts += [a + (b - a) * (i + .5) / k for i in range(k)]
        out['-merlons'] = union(*[place(block(-.45, .45, -.3, .3, 0, 1.4, step, 'merlon'),
                                        p[0] * .93, p[1] * .93, height, math.atan2(p[1], p[0]) + HALF)
                                  for p in pts])
    return out


def gate(span, spring, depth, tower_size, tower_height, wall_height=None, kind='round',
         step=2.0):
    """A gate: an arched passage `span` wide through a wall `depth` thick,
    between two towers (`-towers`)."""
    top = (wall_height or spring + span) - spring
    panel = place(arched_panel(span, top, depth, tower_size * .1, kind, step=step)[''], z=spring)
    jambs = [block(sx * span / 2, sx * (span / 2 + tower_size * .1), -depth / 2, depth / 2, 0, spring,
                   step, 'jamb') for sx in (-1,)] + \
            [block(span / 2, span / 2 + tower_size * .1, -depth / 2, depth / 2, 0, spring, step, 'jamb')]
    jambs[0] = block(-span / 2 - tower_size * .1, -span / 2, -depth / 2, depth / 2, 0, spring, step, 'jamb')
    off = span / 2 + tower_size * .1 + tower_size / 2
    towers = [place(v, sx * off) for sx in (-1, 1) for k, v in
              tower(tower_size, tower_height, 'square', step=step).items()]
    return {'': union(panel, *jambs), '-towers': union(*towers)}


def stairs(steps, rise, going, width, step=2.0):
    """A straight flight climbing toward +y from y = 0, centred on x = 0."""
    profile = [(0.0, 0.0), (steps * going, 0.0)]
    for i in range(steps, 0, -1):
        profile += [(i * going, i * rise), ((i - 1) * going, i * rise)]
    P = np.asarray(profile)
    V, F = prism(P, -width / 2, width / 2, step, 'stairs')
    return {'': finish(np.stack([V[:, 2], V[:, 0], V[:, 1]], 1), F, 'stairs')}


def terrain(width, depth, heights, bottom, step=2.0):
    """A ground slab [−w/2, w/2] × [−d/2, d/2]: its top bilinear between the
    corner heights (sw, se, ne, nw), its underside flat at `bottom`."""
    sw, se, ne, nw = heights
    kx = max(1, int(math.ceil(width / step)))
    ky = max(1, int(math.ceil(depth / step)))
    xs, ys = np.linspace(-width / 2, width / 2, kx + 1), np.linspace(-depth / 2, depth / 2, ky + 1)
    V, F = [], []
    for x in xs:
        for y in ys:
            u, v = (x + width / 2) / width, (y + depth / 2) / depth
            V.append((x, y, sw * (1 - u) * (1 - v) + se * u * (1 - v) + ne * u * v + nw * (1 - u) * v))
    m = len(V)
    V += [(x, y, bottom) for x in xs for y in ys]
    for i in range(kx):
        for j in range(ky):
            a, b, c, d = i * (ky + 1) + j, (i + 1) * (ky + 1) + j, (i + 1) * (ky + 1) + j + 1, i * (ky + 1) + j + 1
            F += [(a, b, c), (a, c, d), (m + a, m + c, m + b), (m + a, m + d, m + c)]
    edge = ([i * (ky + 1) for i in range(kx + 1)] + [kx * (ky + 1) + j for j in range(1, ky + 1)]
            + [i * (ky + 1) + ky for i in range(kx - 1, -1, -1)] + [j for j in range(ky - 1, 0, -1)])
    for a, b in zip(edge, edge[1:] + edge[:1]):
        F += [(a, m + a, m + b), (a, m + b, b)]
    from .shapes import _orient_pieces
    return {'': _orient_pieces(np.asarray(V), F, 'terrain')}


def wall(length, height, thickness, openings=(), step=2.0):
    """A straight wall along +x from 0 to `length`, centred on y = 0, with
    openings [{x (centre), width, sill, head, arch: none|round|pointed}]:
    piers between them, sills under, lintels or arched heads over."""
    t = thickness / 2
    if not openings:
        return {'': block(0, length, -t, t, 0, height, step, 'wall')}
    pieces, x = [], 0.0
    for o in sorted(openings, key=lambda o: o['x']):
        a, b = o['x'] - o['width'] / 2, o['x'] + o['width'] / 2
        if a - x > 1e-6:
            pieces.append(block(x, a, -t, t, 0, height, step, 'wall'))
        if o.get('sill', 0) > 1e-6:
            pieces.append(block(a, b, -t, t, 0, o['sill'], step, 'sill'))
        kind = o.get('arch', 'none')
        if kind == 'none':
            if height - o['head'] > 1e-6:
                pieces.append(block(a, b, -t, t, o['head'], height, step, 'lintel'))
        else:
            spring = o['head'] - o['width'] / 2 if kind == 'round' else o['head'] - o['width'] * .65
            pieces.append(place(arched_panel(o['width'], height - spring, thickness, 0, kind,
                                             step=step)[''], o['x'], 0, spring))
        x = b
    if length - x > 1e-6:
        pieces.append(block(x, length, -t, t, 0, height, step, 'wall'))
    return {'': union(*pieces)}


def slab(width, depth, thickness, step=2.0):
    """A floor, platform or roof slab centred on the origin, top at z = 0... no: from z = 0 up."""
    return {'': block(-width / 2, width / 2, -depth / 2, depth / 2, 0, thickness, step, 'slab')}


def transition(outer_sides, outer_radius, inner_radius, height, step=2.0, phase=0.0, n=None):
    """A band from a `outer_sides`-gon (circumradius `outer_radius`) to a
    circle inside it: the octagon of Küçük Ayasofya turning into its dome's
    round base, a square bay's cornice."""
    n = n or max(outer_sides * 4, segments(inner_radius, step, 16, outer_sides))
    angles = phase + TAU * np.arange(n) / n
    return {'': band(polygon_at(angles, outer_sides, outer_radius, phase),
                     polygon_at(angles, 0, inner_radius), 0, height, step, 'transition')}


def octagon(ax, ay, skew=0.0, pier=2.4, column=None, gallery_column=None, ground=4.4,
            entablature=5.5, gallery=6.1, gallery_height=3.4, spring=10.2, base=13.0,
            open_side='e', columns_per_side=2, exedra_depth=None, step=2.0):
    """A centrally planned Byzantine core (Sts Sergius and Bacchus): eight
    piers on an octagon whose inner faces lie ax and ay from the centre
    (across x and y), turned `skew` degrees; on the four sides facing the
    axes, colonnades of `columns_per_side` in two storeys (ground columns to
    `ground` under an entablature to `entablature`, gallery columns from
    `gallery`); on the diagonals, semicircular exedrae with the same columns
    on their curve and half-domes at `spring`; the side `open_side` ('n', 's',
    'e', 'w' = −x, +x, +y, −y) left open; eight arches with their spandrels
    from `spring` up to the dome's base `base`. Pieces: '-piers', '' (ground
    columns), '-entablature', '-gallery' (gallery columns and arches),
    '-exedrae' (their half-domes), '-arches'."""
    c = column or {}
    g = gallery_column or {}
    d, gd = c.get('diameter', .55), g.get('diameter', .45)
    t = math.radians(skew)
    k = 1 / math.cos(math.pi / 8)
    # Corner directions 22.5° + 45°·i; the octagon is stretched to ax, ay.
    corners = []
    for i in range(8):
        a = math.pi / 8 + i * math.pi / 4
        corners.append(np.array([ax * k * math.cos(a), ay * k * math.sin(a)]))

    def turn(p):
        return np.array([p[0] * math.cos(t) - p[1] * math.sin(t),
                         p[0] * math.sin(t) + p[1] * math.cos(t)])

    sides = {0: 's', 2: 'e', 4: 'n', 6: 'w'}      # side i joins corners i-1, i (faces 45°·i)
    out = {k_: [] for k_ in ('', '-piers', '-entablature', '-gallery', '-exedrae', '-arches')}
    for i in range(8):
        cc = corners[i]
        radial = math.atan2(cc[1], cc[0])
        centre = turn(cc + np.array([math.cos(radial), math.sin(radial)]) * pier * .5)
        out['-piers'].append(place(pier_solid(pier, spring, step), centre[0], centre[1], 0,
                                   radial + t))
    for i in range(8):
        a, b = corners[(i - 1) % 8], corners[i]
        mid = (a + b) / 2
        length = float(np.linalg.norm(b - a))
        facing = math.atan2(b[1] - a[1], b[0] - a[0])          # along the side
        normal = facing - HALF                                  # outward
        span = length - pier
        m = turn(mid)
        out['-arches'].append(place(arched_panel(span, base - spring, pier, pier / 2, 'round',
                                                 step=step)[''], m[0], m[1], spring, facing + t))
        if i % 2 == 0:                                          # a straight side
            if sides[i] == open_side:
                continue
            for j in range(columns_per_side):
                f = (j + 1) / (columns_per_side + 1)
                q = a + (b - a) * f + np.array([math.cos(normal), math.sin(normal)]) * d / 2
                q = turn(q)
                out[''].append(place(column_solid(ground, d, c.get('capital', 'melon'), step,
                                                  c.get('n', 8), True), q[0], q[1]))
                out['-gallery'].append(place(column_solid(gallery_height, gd,
                                                          g.get('capital', 'impost'), step,
                                                          g.get('n', 8), True), q[0], q[1], gallery))
            beam = block(-length / 2, length / 2, -.45, .45, 0, entablature - ground, step,
                         'entablature')
            # The entablature's inner face is the side line: the octagon's width.
            mm = turn(mid + np.array([math.cos(normal), math.sin(normal)]) * .45)
            out['-entablature'].append(place(beam, mm[0], mm[1], ground, facing + t))
            bays = columns_per_side + 1
            top = spring - gallery - gallery_height
            for j in range(bays):
                f = (j + .5) / bays
                q = turn(a + (b - a) * f + np.array([math.cos(normal), math.sin(normal)]) * d / 2)
                out['-gallery'].append(place(arched_panel(length / bays - gd, top, .7, gd / 2,
                                                          'round', n=6, step=step)[''],
                                             q[0], q[1], gallery + gallery_height, facing + t))
        else:                                                   # a diagonal: an exedra
            r = exedra_depth or span / 2
            ex = {}
            for z0, h, dia, cap in ((0.0, ground, d, c.get('capital', 'melon')),
                                    (gallery, gallery_height, gd, g.get('capital', 'impost'))):
                for j in range(columns_per_side):
                    u = math.pi * (j + 1) / (columns_per_side + 1)
                    q = turn(mid + r * np.array([math.cos(normal + u - HALF),
                                                 math.sin(normal + u - HALF)]))
                    key = '' if z0 == 0 else '-gallery'
                    out[key].append(place(column_solid(h, dia, cap, step, 8, True), q[0], q[1], z0))
            beam = ring_sector(r - .45, r + .45, 0, math.pi, 0, entablature - ground, step,
                               name='exedra beam')
            out['-entablature'].append(place(beam, m[0], m[1], ground, normal - HALF + t))
            upper = ring_sector(r - .35, r + .35, 0, math.pi, 0, spring - gallery - gallery_height,
                                step, name='exedra arcade')
            out['-gallery'].append(place(upper, m[0], m[1], gallery + gallery_height,
                                         normal - HALF + t))
            ex[''] = semidome(r, .5, step=step)['']
            out['-exedrae'].append(place(ex[''], m[0], m[1], spring, normal - HALF + t))
    return {k_: union(*v) for k_, v in out.items() if v}


def pier_solid(size, height, step):
    return block(-size / 2, size / 2, -size / 2, size / 2, 0, height, step, 'pier')


KINDS = {
    'dome': dome, 'semidome': semidome, 'exedra': exedra, 'pendentives': pendentives,
    'squinch': squinch, 'arch': arch_ring, 'arched-panel': arched_panel, 'column': column,
    'pier': pier, 'buttress': buttress, 'minaret': minaret, 'portico': portico,
    'courtyard': courtyard, 'sadirvan': sadirvan, 'cistern': cistern, 'curtain': curtain,
    'tower': tower, 'gate': gate, 'stairs': stairs, 'terrain': terrain, 'wall': wall,
    'slab': slab, 'transition': transition, 'octagon': octagon, 'ring': lambda **k: {'': ring(**k)},
    'ring-wall': lambda **k: {'': wall_with_openings(**k)},
    'arcade': None,  # defined below
    'sail-vault': lambda half, thickness, step=2.0: {'': sail_vault(half, thickness, step)},
}


def arcade(length, bays, spring, support=None, thickness=.8, depth=1.0, kind='round',
           top=None, piers_at_ends=True, step=2.0):
    """An arcade along +x from 0 to `length`: `bays` arches springing at
    `spring` on columns (or piers) {kind: column|pier, diameter|width,
    capital}; with `top`, arched panels fill the spandrels up to it."""
    s = support or {}
    width = s.get('diameter', s.get('width', .8))
    xs = [length * i / bays for i in range(bays + 1)]
    supports = []
    for i, x in enumerate(xs):
        if s.get('kind', 'column') == 'pier' or (piers_at_ends and i in (0, bays)):
            supports.append(place(pier(width, depth, spring, step=step)[''], x))
        else:
            supports.append(place(column_solid(spring, width, s.get('capital', 'impost'), step,
                                               s.get('n', 8)), x))
    span = length / bays - width
    if top is None:
        arches = [place(arch_ring(span, thickness, depth, kind, step=step)[''], x + length / bays / 2,
                        0, spring) for x in xs[:-1]]
    else:
        arches = [place(arched_panel(span, top - spring, depth, width / 2, kind, step=step)[''],
                        x + length / bays / 2, 0, spring) for x in xs[:-1]]
    return {'': union(*supports), '-arches': union(*arches)}


KINDS['arcade'] = arcade
