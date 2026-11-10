"""Usage: python3.11 -m unittest tool/atlas/test_atlas.py

Checks the Atlas tools (P10) on what they produce and on small inputs:
the binary encoding round-trips, the historic spec keeps its own rules,
the built assets match their evidence, and the shore then is a shrink of
the land now on the Marmara side only.
"""
import hashlib
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_atlas  # noqa: E402
import build_historic  # noqa: E402
import historic_spec  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


def read_uvar(data, i):
    result = shift = 0
    while True:
        b = data[i]
        i += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, i
        shift += 7


class Encoding(unittest.TestCase):
    def test_varints_round_trip(self):
        for n in [0, 1, 127, 128, 300, 2 ** 31, 2 ** 40]:
            out = bytearray()
            build_atlas.uvar(n, out)
            self.assertEqual(read_uvar(out, 0), (n, len(out)))
        for n in [0, -1, 1, -64, 64, -100000, 100000]:
            out = bytearray()
            build_atlas.zvar(n, out)
            u, _ = read_uvar(out, 0)
            self.assertEqual((u >> 1) ^ -(u & 1), n)

    def test_simplification_keeps_ends_and_drops_noise(self):
        line = [(0, 0), (50, 0.4), (100, -0.3), (150, 0.2), (200, 0)]
        self.assertEqual(build_atlas.rdp(line, 1), [(0, 0), (200, 0)])
        self.assertEqual(build_atlas.rdp(line, 0.1), line)


class Spec(unittest.TestCase):
    def test_hand_points_only_where_the_line_is_uncertain(self):
        for f in historic_spec.FEATURES:
            refs = list(build_historic.refs(f))
            if any(r[0] == 'at' for r in refs):
                self.assertIn(f['certainty'], build_historic.HAND_OK, f['id'])

    def test_every_feature_is_dated_sourced_and_bilingual(self):
        source_ids = {s['id'] for s in historic_spec.SOURCES}
        for f in historic_spec.FEATURES:
            self.assertTrue(set(f['sources']) <= source_ids, f['id'])
            self.assertTrue(f['names']['en'] and f['names']['tr'], f['id'])
            self.assertTrue(f['note']['en'] and f['note']['tr'], f['id'])
            self.assertTrue(f['end'] is None or f['end'] >= f['start'], f['id'])


class Built(unittest.TestCase):
    def test_assets_match_their_evidence(self):
        evidence = json.loads((ROOT / 'studio/atlas/atlas_source.json').read_text())
        data = (ROOT / 'assets/atlas/atlas.bin').read_bytes()
        self.assertFalse(evidence['partial'])
        self.assertEqual(hashlib.sha256(data).hexdigest(), evidence['atlasBinSha256'])
        self.assertLessEqual(len(data), build_atlas.BUDGET_BYTES)
        self.assertEqual(data[:4], b'MLAT')
        historic = json.loads((ROOT / 'assets/atlas/historic.json').read_text())
        self.assertEqual(len(historic['features']), len(historic_spec.FEATURES))

    def test_the_shore_then_only_removes_land_on_the_marmara_side(self):
        from shapely.geometry import Point, Polygon
        coast, _ = build_atlas.load('coastline')
        ways = [build_atlas.way_points(e) for e in coast['elements'] if e['type'] == 'way']
        land = build_atlas.land_polygons(build_atlas.chain(ways), build_atlas.clip_box())
        changed, then = build_atlas.land_then(land)
        self.assertEqual(len(changed), 1)
        before = Polygon(land[next(iter(changed))]).buffer(0)
        after = Polygon(max(then, key=lambda r: Polygon(r).area)).buffer(0)
        lost = before.area - after.area
        # The fills along the coast road and at Yenikapı: about 1–3 km².
        self.assertGreater(lost, 0.5e6)
        self.assertLess(lost, 4e6)
        # Hagia Sophia and the Galata Tower stay on land then.
        for lat, lng in [(41.0086, 28.9802), (41.0256, 28.9742)]:
            self.assertTrue(after.contains(Point(build_atlas.project(lat, lng))))
        # The Yenikapı event square (built on the fill) was sea.
        self.assertFalse(after.contains(Point(build_atlas.project(40.9986, 28.9456))))


if __name__ == '__main__':
    unittest.main()
