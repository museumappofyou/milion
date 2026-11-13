"""Chora's plan for the guide (P11), traced from a measured plan.

Source: Van Millingen, *Byzantine Churches in Constantinople* (1912), Fig. 105,
"Plan of the Chora and the Parecclesion" (Project Gutenberg 29077, image
fig_105.png, 500 × 732 px; public domain), with its text pp. 307–311 for the
bays and vaults. The figure has a metre scale (0–20 m) whose ticks repeat every
15.5 px; it checks against the naos dome, 123 px ≈ 7.9 m, against 7.7 m given
for the dome elsewhere (Wikipedia, "The Chora", revision 1381788152).

Frame: metres from the centre of the naos dome, +u along the axis towards the
apse (east), +v to the north. The figure has the apse up and north to the left,
so u = (383 − py) / 15.5 and v = (220 − px) / 15.5 for a pixel (px, py), the
dome's centre being (220, 383). The axis bears 104.5° (OSM relation 7614527).

Rooms are the inner outlines of the spaces, simplified to straight walls and
arcs; the naos is drawn as the short-armed cross Van Millingen describes. This
is a guide's plan for finding artworks, not a survey.
"""
import math

PX_PER_M = 15.5
CENTRE = (220, 383)
AXIS_DEG = 104.5


def at(px, py):
    """A pixel of Fig. 105 in plan metres."""
    return (round((CENTRE[1] - py) / PX_PER_M, 2), round((CENTRE[0] - px) / PX_PER_M, 2))


def arc(cu, cv, r, start, end, n=8):
    """Points on an arc in plan metres; angles in degrees from +u towards +v."""
    out = []
    for i in range(n + 1):
        a = math.radians(start + (end - start) * i / n)
        out.append((round(cu + r * math.cos(a), 2), round(cv + r * math.sin(a), 2)))
    return out


def rect(u0, v0, u1, v1):
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def loc(en, tr):
    return {'en': en, 'tr': tr}


def rooms():
    pu0, pv0 = at(357, 470)  # parekklesion, north-west inner corner
    pu1, pv1 = at(443, 255)  # its south side at the apse's chord
    apse_c = at(400, 255)
    return [
        dict(id='naos', name=loc('Naos', 'Naos'), label=(1.6, 0.0),
             # The short-armed cross under a 7.7 m dome (pp. 307–308), the
             # bema and the apse (inner radius 3.0 m: 46 px).
             # Arms traced at px 135 and 300 (north, south) for py 335–445.
             outline=[(-3.9, -2.6), (-5.0, -2.6), (-5.0, 2.6), (-3.9, 2.6), (-3.9, 3.9),
                      (-4.0, 3.9), (-4.0, 5.48), (3.1, 5.48), (3.1, 3.9), (3.9, 3.9),
                      (3.9, 3.0), (5.4, 3.0), *arc(5.4, 0, 3.0, 90, -90)[1:-1], (5.4, -3.0),
                      (3.9, -3.0), (3.9, -3.9), (3.1, -3.9), (3.1, -5.16), (-4.0, -5.16),
                      (-4.0, -3.9), (-3.9, -3.9)]),
        dict(id='prothesis', name=loc('Prothesis (north chapel)', 'Prothesis (kuzey şapeli)'),
             label=(7.3, 7.1), outline=rect(*at(143, 300), *at(78, 238))),
        dict(id='diakonikon', name=loc('Diakonikon (south chapel)', 'Diakonikon (güney şapeli)'),
             label=(7.6, -6.3), outline=rect(*at(300, 290), *at(335, 225))),
        dict(id='north-annex', name=loc('North annex', 'Kuzey ek yapı'), label=(-0.5, 8.8),
             outline=rect(*at(110, 470), *at(58, 312))),
        dict(id='inner-narthex', name=loc('Inner narthex', 'İç narteks'), label=(-8.6, 1.6),
             # Four bays from px 60 (north end) to 345 (the door to the return
             # bay of the outer narthex), p. 309.
             outline=rect(*at(60, 545), *at(345, 490))),
        # The thick wall between the narthexes around the door from one to
        # the other: the framed icons on its outer face (Ousterhout pp. 23,
        # 75) are catalogued as the Passage.
        dict(id='passage', name=loc('Passage', 'Geçit'),
             label=(-11.1, 0.0), outline=rect(-11.74, -3.2, -10.45, 3.2)),
        dict(id='outer-narthex', name=loc('Outer narthex', 'Dış narteks'), label=(-14.0, 0.6),
             # Five bays along the west front and two returned at the south
             # end in front of the parekklesion (p. 309).
             outline=[at(55, 565), at(55, 635), at(445, 635), at(445, 475), at(360, 475),
                      at(360, 565)]),
        dict(id='parekklesion', name=loc('Parekklesion', 'Parekklesion'), label=(-4.35, -11.6),
             outline=[(pu0, pv0), (pu1, pv0), *arc(apse_c[0], apse_c[1], (pv0 - pv1) / 2, 90, -90)[1:-1],
                      (pu1, pv1), (pu0, pv1)]),
    ]


def vaults():
    def dome(room, px, py, r_px, ribs=0, kind='dome'):
        u, v = at(px, py)
        return dict(room=room, kind=kind, center=[u, v], radius=round(r_px / PX_PER_M, 2), ribs=ribs)
    return [
        dict(room='naos', kind='dome', center=[0.0, 0.0], radius=3.85, ribs=16),  # 16 segments, p. 308
        dome('prothesis', 110, 268, 25, 8),       # drum dome of eight concave sections, p. 308
        dome('diakonikon', 318, 258, 18),         # a plain drum dome, p. 308
        dome('inner-narthex', 115, 516, 28, 16),  # north end bay: sixteen segments, p. 309
        dome('inner-narthex', 292, 514, 35, 24),  # the larger south bay; 24 ancestors (KE guide 13)
        dome('inner-narthex', 175, 516, 22, kind='vault'),
        dome('inner-narthex', 220, 516, 22, kind='vault'),
        # The five west-front bays are 3.4–4.2 m apart; drawn a little inside
        # their arches so neighbours do not overlap. The two return bays are
        # the large domical vaults (Ousterhout pp. 59–61).
        *[dome('outer-narthex', px, 600, 25, kind='vault') for px in (88, 150, 215, 278, 330)],
        dome('outer-narthex', 402, 600, 30, kind='vault'),
        dome('outer-narthex', 402, 512, 30, kind='vault'),
        dome('parekklesion', 400, 395, 35, 12),   # twelve-sided drum dome, p. 310 (4.5 m)
        dome('parekklesion', 400, 300, 32, kind='vault'),
    ]


if __name__ == '__main__':
    import json
    print(json.dumps(dict(rooms=rooms(), vaults=vaults()), ensure_ascii=False, indent=1)[:3000])
