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
            self.assertIn(f'cap-{kind}', protos)
        for style in set(walk['shafts']):
            self.assertIn(f'shaft-{style}', protos)
        for s in walk['specials']:
            self.assertIn(s['prototype'], protos)
        for name in ['bay', 'tie-rods', 'uplamp-body', 'uplamp-glow',
                     'deck', 'deck-rail', 'stair', 'deck-strip',
                     'water', 'water-caustics', 'fish']:
            self.assertIn(name, protos)
        self.assertEqual(len(walk['capitals']), walk['grid']['along'] * walk['grid']['across'])
        self.assertEqual(len(walk['shafts']), walk['grid']['along'] * walk['grid']['across'])

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

    def test_zero_degenerate_triangles_and_closed_landing(self):
        import struct
        import numpy as np
        raw = (ROOT / 'assets/walk/basilica-cistern/model.glb').read_bytes()
        jlen = struct.unpack_from('<I', raw, 12)[0]
        doc = json.loads(raw[20:20 + jlen])
        blen = struct.unpack_from('<I', raw, 20 + jlen)[0]
        blob = raw[28 + jlen:28 + jlen + blen]
        walk = json.loads((ROOT / 'assets/walk/basilica-cistern/walk.json').read_text())

        def read_acc(idx):
            acc = doc['accessors'][idx]
            bv = doc['bufferViews'][acc['bufferView']]
            dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32}[acc['componentType']]
            cols = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[acc['type']]
            off = bv.get('byteOffset', 0) + acc.get('byteOffset', 0)
            arr = np.frombuffer(blob, dtype=dtype, count=acc['count'] * cols, offset=off)
            return arr.reshape(-1, cols) if cols > 1 else arr

        rail_pos = None
        stair_pos = None
        for node in doc['nodes']:
            prim = doc['meshes'][node['mesh']]['primitives'][0]
            pos = read_acc(prim['attributes']['POSITION'])
            idx = read_acc(prim['indices']).reshape(-1, 3)
            areas = 0.5 * np.linalg.norm(
                np.cross(pos[idx[:, 1]] - pos[idx[:, 0]], pos[idx[:, 2]] - pos[idx[:, 0]]),
                axis=1)
            self.assertEqual(int((areas < 1e-8).sum()), 0, node['name'])
            if node['name'] == 'deck-rail':
                rail_pos = pos
            elif node['name'] == 'stair':
                stair_pos = pos
        self.assertIsNotNone(rail_pos)
        self.assertIsNotNone(stair_pos)
        # Submerged stilts reach y = 0 and stair landing connects flush to perimeter wall.
        self.assertAlmostEqual(float(rail_pos[:, 1].min()), 0.0, delta=0.05)
        self.assertAlmostEqual(float(stair_pos[:, 2].max()), walk['grid']['width'], delta=0.05)


if __name__ == '__main__':
    unittest.main()
