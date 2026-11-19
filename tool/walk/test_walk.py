"""Usage: python3.11 tool/walk/test_walk.py

P14's walk builder: triangles wind counter-clockwise around their normals
(the phone culls back faces; a clockwise vault vanished there), every
prototype the scene asks for is in the model, and the shipped manifest is
what the spec builds.
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import geometry as g  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


def wound_ok(m):
    import numpy as np
    for a, b, c in m.faces:
        pa, pb, pc = (np.array(m.positions[i]) for i in (a, b, c))
        shading = np.add(np.add(m.normals[a], m.normals[b]), m.normals[c])
        if float(np.dot(np.cross(pb - pa, pc - pa), shading)) < 0:
            return False
    return True


class Orient(unittest.TestCase):
    def test_a_clockwise_triangle_is_turned(self):
        m = g.Mesh()
        up = (0, 1, 0)
        a, b, c = (m.vertex(p, up, (1, 1, 1)) for p in [(0, 0, 0), (1, 0, 0), (0, 0, 1)])
        m.tri(a, b, c)  # clockwise seen from +y
        self.assertFalse(wound_ok(m))
        self.assertEqual(m.orient(), 1)
        self.assertTrue(wound_ok(m))
        self.assertEqual(m.orient(), 0)


class Shipped(unittest.TestCase):
    def test_the_manifest_names_only_prototypes_it_has(self):
        walk = json.loads((ROOT / 'assets/walk/basilica-cistern/walk.json').read_text())
        protos = set(walk['prototypes'])
        for kind in set(walk['capitals']):
            self.assertIn(f'column-{kind}', protos)
        for s in walk['specials']:
            self.assertIn(s['prototype'], protos)
        for name in ['bay', 'deck', 'water', 'fish']:
            self.assertIn(name, protos)
        self.assertEqual(len(walk['capitals']), walk['grid']['along'] * walk['grid']['across'])

    def test_every_stop_stands_near_the_deck(self):
        walk = json.loads((ROOT / 'assets/walk/basilica-cistern/walk.json').read_text())
        route = walk['route']

        def dist(p, a, b):
            (px, pz), (ax, az), (bx, bz) = p, a, b
            dx, dz = bx - ax, bz - az
            t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz)))
            return ((px - ax - t * dx) ** 2 + (pz - az - t * dz) ** 2) ** .5

        for s in walk['stops']:
            if s['id'] == 'stair':
                continue
            eye = (s['eye'][0], s['eye'][2])
            d = min(dist(eye, route[i], route[i + 1]) for i in range(len(route) - 1))
            self.assertLess(d, walk['grid']['deckHeight'] + 1.5, s['id'])


if __name__ == '__main__':
    unittest.main()
