"""P09 kit tests: python3.11 -m pytest tool/space/test_kit.py (or run directly)."""
from pathlib import Path
import base64
import json
import math
import sys
import tempfile
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_kit  # noqa: E402
import meshopt  # noqa: E402
from glb import read_glb, write_compressed  # noqa: E402
from kit import elements as E  # noqa: E402
from kit import spec as kit  # noqa: E402
from kit.shapes import GRID  # noqa: E402
from solid import check_closed, volume  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SPECS = sorted((ROOT / 'studio/space').glob('*.yaml'))


def solids(V, F):
    return [(V, F[np.isin(F[:, 0], c)]) for c in kit.components(V, F)]


class ElementTest(unittest.TestCase):
    CASES = {
        'dome': lambda: E.dome(radius=9.5, windows=24, ribs=24),
        'melon': lambda: E.dome(radius=8, thickness=.45, gores=16, gore_depth=.08, windows=8),
        'umbrella': lambda: E.dome(radius=1.65, thickness=.3, gores=8, alternate=False,
                                   drum={'height': 3.15, 'windows': 8,
                                         'buttresses': {'depth': .5, 'width': .9}}),
        'semidome': lambda: E.semidome(radius=9.5, windows=5),
        'exedra': lambda: E.exedra(radius=3.4, height=13.9, windows=3, sill=8.6, head=12.4),
        'exedra-arcade': lambda: E.exedra(radius=5, height=8, columns=4),
        'apse': lambda: E.exedra(radius=3.9, height=7.5, thickness=1.3, outer_sides=6, windows=3),
        'pendentives': lambda: E.pendentives(half=9.5, top=10.2),
        'squinch': lambda: E.squinch(span=4),
        'arch': lambda: E.arch_ring(span=19, thickness=1.5, depth=5, kind='pointed', pointed=.146),
        'arcade': lambda: E.arcade(length=20, bays=4, spring=5, top=9),
        'pier': lambda: E.pier(width=4, depth=4, height=10, kind='cruciform'),
        'buttress': lambda: E.buttress(width=1.6, depth=.8, height=9, kind='half-round'),
        'stepped': lambda: E.buttress(width=1.5, depth=2, height=8, kind='stepped'),
        'minaret': lambda: E.minaret(base=4.6, base_height=12, shaft_diameter=3.4,
                                     shaft_top=43.75, serefe=[35, 43.5], sides=12),
        'portico': lambda: E.portico(bays=5, bay=4.62, depth=5.2, spring=4.2),
        'courtyard': lambda: E.courtyard(size=42, bays=5, spring=5.6, open_side='n',
                                         sadirvan_spec={'radius': 3}),
        'cistern': lambda: E.cistern(nx=3, ny=4, bay=4.9, spring=8),
        'curtain': lambda: E.curtain(length=40, height=12, thickness=4, merlons={}),
        'tower': lambda: E.tower(size=10, height=20, kind='polygonal', roof=4),
        'gate': lambda: E.gate(span=5, spring=6, depth=5, tower_size=8, tower_height=18),
        'stairs': lambda: E.stairs(steps=10, rise=.17, going=.3, width=3),
        'terrain': lambda: E.terrain(width=30, depth=20, heights=[0, 1, 3, 2], bottom=-4),
        'wall': lambda: E.wall(length=20, height=10, thickness=1.2, openings=[
            {'x': 5, 'width': 2, 'sill': 1, 'head': 4, 'arch': 'round'},
            {'x': 12, 'width': 2, 'sill': 1, 'head': 5, 'arch': 'pointed'}]),
        'octagon': lambda: E.octagon(ax=7.7, ay=8.15, skew=3),
        'transition': lambda: E.transition(outer_sides=8, outer_radius=9, inner_radius=8,
                                           height=1.5),
    }

    def test_every_piece_is_closed_outward_and_on_the_grid(self):
        for name, make in self.CASES.items():
            for suffix, (V, F) in make().items():
                label = name + suffix
                check_closed(V, F, label)
                # Each solid of a multi-solid piece faces out on its own.
                for sv, sf in solids(V, F):
                    self.assertGreater(volume(sv, sf), 0, label)
                self.assertTrue(np.array_equal(meshopt.quantise(V, GRID), V), label)

    def test_serefe_count(self):
        for n in (1, 2, 3):
            serefe = [30 + 6 * i for i in range(n)]
            pieces = E.minaret(base=4, base_height=8, shaft_diameter=3, shaft_top=serefe[-1] + .25,
                               serefe=serefe, parapet=1.0)
            parts = [(k, v, 'stone') for k, v in pieces.items()]
            # A şerefe is a corbel with its floor and a parapet ring 1 m high.
            self.assertEqual(kit.measure({'kind': 'count', 'parts': ['-serefe'], 'height': 1.0},
                                         parts), n)
            self.assertEqual(len(kit.components(*pieces['-serefe'])), 2 * n)

    def test_window_counts(self):
        for n in (8, 24, 40):
            V, F = E.dome(radius=9.5, windows=n)['-windows']
            self.assertEqual(len(kit.components(V, F)), n)
        V, F = E.semidome(radius=9.5, windows=5)['-windows']
        self.assertEqual(len(kit.components(V, F)), 6)      # half piers at both ends
        pieces = E.dome(radius=1.65, drum={'height': 3.15, 'windows': 8, 'sill': .6, 'head': 2.4})
        parts = [('drum', pieces['-drum'], 'brick')]
        self.assertEqual(kit.measure({'kind': 'count', 'parts': ['drum'], 'zmin': -2.55,
                                      'zmax': -.75}, parts), 8)

    def test_pointed_arch_rise(self):
        V, _ = E.arch_ring(span=19, thickness=1.5, depth=5, kind='pointed', pointed=.146)['']
        inner_crown = min(V[np.abs(V[:, 0]) < 1e-3][:, 2])
        self.assertAlmostEqual(inner_crown, 10.8, delta=.05)


class MeshoptTest(unittest.TestCase):
    def test_decodes_meshoptimizer_reference_vectors(self):
        cases = json.loads((ROOT / 'test/fixtures/space/meshopt_reference.json').read_text())
        for c in cases['cases']:
            enc = base64.b64decode(c['encoded'])
            want = base64.b64decode(c['expected'])
            if c['mode'] == 'ATTRIBUTES':
                raw = meshopt.decode_vertex_buffer(enc, c['count'], c['stride'])
                if c['filter'] == 'EXPONENTIAL':
                    raw = meshopt.unexponential(np.frombuffer(raw, np.uint32)).astype(
                        np.float32).tobytes()
                self.assertEqual(raw, want, c['name'])
            else:
                dtype = np.uint16 if c['stride'] == 2 else np.uint32
                got = meshopt.decode_index_buffer(enc, c['count'])
                self.assertTrue(np.array_equal(got, np.frombuffer(want, dtype)), c['name'])

    def test_round_trip(self):
        rng = np.random.default_rng(3)
        for n, stride in ((1, 4), (255, 12), (257, 12), (1000, 16)):
            raw = rng.integers(0, 256, n * stride, dtype=np.uint8).tobytes()
            enc = meshopt.encode_vertex_buffer(raw, n, stride)
            self.assertEqual(meshopt.decode_vertex_buffer(enc, n, stride), raw)
        i = np.arange(9 * 9).reshape(9, 9)
        F = np.concatenate([np.stack([i[:-1, :-1], i[1:, :-1], i[1:, 1:]], -1).reshape(-1, 3),
                            np.stack([i[:-1, :-1], i[1:, 1:], i[:-1, 1:]], -1).reshape(-1, 3)])
        F, _ = meshopt.optimise(F)
        got = meshopt.decode_index_buffer(meshopt.encode_index_buffer(F), F.size).reshape(-1, 3)
        rot = lambda T: [tuple(np.roll(t, -int(np.argmin(t)))) for t in T]  # noqa: E731
        self.assertEqual(rot(got), rot(F))

    def test_exponential_is_exact_on_its_grid(self):
        v = meshopt.quantise(np.linspace(-40, 40, 1001), -10)
        self.assertTrue(np.array_equal(meshopt.unexponential(meshopt.exponential(v, -10)), v))
        with self.assertRaises(ValueError):
            meshopt.exponential(np.array([1e-4]), -10)


class SpecTest(unittest.TestCase):
    def test_footprint_axis(self):
        # A 40 × 10 m rectangle turned to 120°, in degrees of latitude and longitude.
        lat0 = 41.0
        a = math.radians(120)
        pts = []
        for u, v in ((-20, -5), (20, -5), (20, 5), (-20, 5)):
            east = u * math.sin(a) + v * math.cos(a)
            north = u * math.cos(a) - v * math.sin(a)
            pts.append((lat0 + north / 111053.0, 29.0 + east / 84130.0))
        axis, long_side, short_side = kit.footprint_axis(pts)
        self.assertAlmostEqual(axis, 120, delta=.2)
        self.assertAlmostEqual(long_side, 40, delta=.1)
        self.assertAlmostEqual(short_side, 10, delta=.1)

    def test_every_spec_meets_its_dimensions_budget_and_axis(self):
        self.assertEqual(len(SPECS), 3)
        known = build_kit.registry_sources(build_kit.SOURCES)
        for path in SPECS:
            spec = kit.load(path)
            built, steps, dims, axis, triangles = build_kit.build_one(spec, known)
            self.assertLessEqual(triangles, build_kit.BUDGET, spec['id'])
            self.assertGreaterEqual(len(dims), 10, spec['id'])
            self.assertTrue(all(ok for *_, ok in dims), spec['id'])
            self.assertLessEqual(axis['offDegrees'], build_kit.AXIS_TOLERANCE, spec['id'])
            # The assets on disk are what the spec builds, byte for byte.
            with tempfile.TemporaryDirectory() as d:
                write_compressed(Path(d, 'a.glb'), built, {'milion': {
                    'units': 'm', 'up': 'z', 'axis': 'y',
                    'axisAzimuth': spec['orientation']['axis'],
                    'note': 'P09 kit; a diagram on cited dimensions, not a survey'}})
                shipped = ROOT / f"assets/space/{spec['id']}/model.glb"
                self.assertEqual(Path(d, 'a.glb').read_bytes(), shipped.read_bytes(), spec['id'])
            manifest = json.loads((ROOT / f"assets/space/{spec['id']}/study.json").read_text())
            self.assertEqual(manifest['triangles'], triangles)
            self.assertEqual(manifest['orientation']['axis'], spec['orientation']['axis'])

    def test_shipped_models_decode_to_closed_solids(self):
        for path in SPECS:
            spec_id = kit.load(path)['id']
            doc, parts = read_glb(ROOT / f'assets/space/{spec_id}/model.glb')
            self.assertEqual(doc['extensionsRequired'], ['EXT_meshopt_compression'])
            for p in parts:
                check_closed(p['positions'], p['faces'], p['name'])
                self.assertTrue(((p['ao'] >= 0) & (p['ao'] <= 1)).all())
                # A solid turned inside out inside a multi-solid part keeps
                # the part closed; each solid must face out on its own.
                for sv, sf in solids(p['positions'], p['faces']):
                    self.assertGreater(volume(sv, sf), 0, f"{spec_id} {p['name']}")


if __name__ == '__main__':
    unittest.main()
