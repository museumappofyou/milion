"""P08 study tests: python3.11 -m pytest tool/space/test_space.py (or run directly)."""
from pathlib import Path
import json
import sys
import tempfile
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import how_a_dome_stands as study  # noqa: E402
from glb import read_glb, write_glb  # noqa: E402
from solid import box, check_closed, solid, surface, volume  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


class SpaceStudyTest(unittest.TestCase):
    def test_every_part_is_a_closed_outward_solid(self):
        for name, (V, F), _ in study.parts(1.0):
            check_closed(V, F, name)
            self.assertGreater(volume(V, F), 0, name)

    def test_geometry_follows_the_construction(self):
        from scipy.sparse import coo_matrix
        from scipy.sparse.csgraph import connected_components
        parts = {n: s for n, s, _ in study.parts(1.0)}
        V = parts['pendentive-ne'][0]
        # One sphere of radius S/√2 about the springing centre: it touches the
        # pier corner (H, H, Z0) and every other point lies on or outside it.
        r = np.linalg.norm(V - [0, 0, study.Z0], axis=1)
        self.assertAlmostEqual(r.min(), study.R, places=6)
        self.assertTrue(np.isclose(V, [study.H, study.H, study.Z0]).all(axis=1).any())
        self.assertAlmostEqual(V[:, 0].max(), study.H, places=6)
        dome = parts['dome'][0]
        self.assertAlmostEqual(dome[:, 2].max(), study.ZB + study.DOME_IN + study.DOME_T, places=4)
        Vw, Fw = parts['windows']
        edges = np.concatenate([Fw[:, [0, 1]], Fw[:, [1, 2]]])
        graph = coo_matrix((np.ones(len(edges)), (edges[:, 0], edges[:, 1])), shape=(len(Vw),) * 2)
        self.assertEqual(connected_components(graph, directed=False)[0], study.WINDOWS)

    def test_open_and_inside_out_solids_are_refused(self):
        V, F = box(0, 1, 0, 1, 0, 1)
        with self.assertRaises(ValueError):
            check_closed(V, F[:-1])
        with self.assertRaises(ValueError):
            check_closed(V, F[:, ::-1])
        flat = surface(lambda u, v: np.stack([u, v, 0 * u], -1), 2, 2,
                       lambda p: np.broadcast_to((0, 0, 1), p.shape))
        with self.assertRaises(ValueError):
            solid(flat)

    def test_glb_round_trip_and_determinism(self):
        V, F = box(0, 2, 0, 3, 0, 4)
        part = {'name': 'b', 'positions': V, 'faces': F, 'ao': np.ones(len(V)),
                'extras': {'material': 'marble'}}
        with tempfile.TemporaryDirectory() as d:
            a, b = Path(d, 'a.glb'), Path(d, 'b.glb')
            write_glb(a, [part])
            write_glb(b, [part])
            self.assertEqual(a.read_bytes(), b.read_bytes())
            doc, parts = read_glb(a)
            self.assertEqual(doc['asset']['version'], '2.0')
            self.assertTrue(np.allclose(parts[0]['positions'], V, atol=1e-6))
            self.assertTrue((parts[0]['faces'] == F).all())

    def test_shipped_model_matches_its_manifest(self):
        doc, parts = read_glb(ROOT / 'assets/space/how-a-dome-stands/model.glb')
        manifest = json.loads((ROOT / 'assets/space/how-a-dome-stands/study.json').read_text())
        self.assertEqual(manifest['triangles'], sum(len(p['faces']) for p in parts))
        used = [p for s in manifest['steps'] for p in s['parts']]
        self.assertEqual(sorted(used), sorted(p['name'] for p in parts))
        for p in parts:
            check_closed(p['positions'], p['faces'], p['name'])
            self.assertTrue(((p['ao'] >= 0) & (p['ao'] <= 1)).all())


if __name__ == '__main__':
    unittest.main()
