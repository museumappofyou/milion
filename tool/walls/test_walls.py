"""Usage: python3.11 tool/walls/test_walls.py

P15's two builders: the strip (Milestone XVIII) and the map sequence (XIX).
Projection onto the line, outer towers kept clear of the gates, the day
scale of the siege, and both shipped manifests being what their specs build.
"""
import json
import math
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tool/walls'))
sys.path.insert(0, str(ROOT / 'tool/siege'))
import build_strip  # noqa: E402
import build_siege  # noqa: E402

STRIP = ROOT / 'assets/walls/land-walls/strip.json'
SIEGE = ROOT / 'assets/siege/1453/siege.json'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


class Projection(unittest.TestCase):
    def test_a_point_beside_a_straight_line(self):
        # 0.001° of latitude is about 110.6 m north at the start of the line.
        line = [((41.0, 28.9), 0.0), ((41.001, 28.9), 110.574)]
        at, off = build_strip.project(line, (41.0005, 28.9001))
        self.assertAlmostEqual(at, 55.3, delta=0.5)
        self.assertAlmostEqual(off, 0.0001 * math.cos(math.radians(41.0005)) * 111320, delta=0.5)

    def test_beyond_the_end_clamps(self):
        line = [((41.0, 28.9), 0.0), ((41.001, 28.9), 110.574)]
        at, _ = build_strip.project(line, (41.002, 28.9))
        self.assertAlmostEqual(at, 110.574)


class Strip(unittest.TestCase):
    def setUp(self):
        self.strip = load(STRIP)

    def test_the_shipped_strip_is_the_build(self):
        with tempfile.TemporaryDirectory() as tmp:
            saved = build_strip.ASSETS
            build_strip.ASSETS = Path(tmp)
            try:
                build_strip.build(ROOT / 'studio/walls/land-walls.yaml')
            finally:
                build_strip.ASSETS = saved
            built = (Path(tmp) / 'land-walls/strip.json').read_text(encoding='utf-8')
        self.assertEqual(built, STRIP.read_text(encoding='utf-8'))

    def test_outer_towers_stand_clear_of_the_gates(self):
        import yaml
        spec = yaml.safe_load((ROOT / 'studio/walls/land-walls.yaml').read_text(encoding='utf-8'))
        clearance = spec['outerTowers']['gateClearance']
        openings = [g['at'] for g in self.strip['gates'] if g['kind'] in ('public', 'military')]
        outer = [t for t in self.strip['towers'] if t['wall'] == 'outer']
        inner = sorted(t['at'] for t in self.strip['towers'] if t['wall'] == 'inner')
        self.assertTrue(outer)
        for t in outer:
            self.assertFalse(t['surveyed'])
            self.assertTrue(all(abs(t['at'] - o) > clearance for o in openings), t)
            # Midway between two neighbouring great towers.
            after = next(i for i, a in enumerate(inner) if a > t['at'])
            self.assertAlmostEqual(t['at'], (inner[after - 1] + inner[after]) / 2, delta=0.1)

    def test_gates_lie_on_the_line_in_order(self):
        ats = [g['at'] for g in self.strip['gates']]
        self.assertEqual(ats, sorted(ats))
        self.assertTrue(all(0 <= a <= self.strip['length'] for a in ats))
        chainage = [p[2] for p in self.strip['line']]
        self.assertEqual(chainage[0], 0)
        self.assertEqual(chainage, sorted(chainage))
        self.assertAlmostEqual(chainage[-1], self.strip['length'], delta=0.1)


class Siege(unittest.TestCase):
    def setUp(self):
        self.siege = load(SIEGE)

    def test_the_shipped_map_is_the_build(self):
        with tempfile.TemporaryDirectory() as tmp:
            saved = build_siege.ASSETS
            build_siege.ASSETS = Path(tmp)
            try:
                build_siege.build(ROOT / 'studio/siege/1453.yaml')
            finally:
                build_siege.ASSETS = saved
            built = (Path(tmp) / '1453/siege.json').read_text(encoding='utf-8')
        self.assertEqual(built, SIEGE.read_text(encoding='utf-8'))

    def test_six_april_to_twenty_nine_may(self):
        first = date.fromisoformat(self.siege['firstDay'])
        self.assertEqual(first, date(1453, 4, 6))
        self.assertEqual(self.siege['days'], (date(1453, 5, 29) - first).days + 1)
        for e in self.siege['events']:
            self.assertTrue(1 <= e['day'] <= self.siege['days'], e['id'])
            if e.get('until') is not None:
                self.assertTrue(e['day'] <= e['until'] <= self.siege['days'], e['id'])

    def test_every_event_is_attributed(self):
        for e in self.siege['events']:
            self.assertTrue(e['accounts'], e['id'])
            for a in e['accounts']:
                self.assertIn(a['side'], build_siege.SIDES)
                self.assertTrue(a['sources'], e['id'])


if __name__ == '__main__':
    unittest.main()
