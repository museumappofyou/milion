"""Run: python3.11 -m pytest -q tool/plate/test_build.py (or python3.11 tool/plate/test_build.py)

The P07 pipeline's own checks: I and II reproduce P06 through yaml alone,
ingest strips metadata without touching pixels, the mesh validator catches
flips and tears, pop-up inpainting stays inside its hole, the spec is
strict, (P12) a reconstruction recipe changes only its loss, and (P13) a
sway mask covers only its segments, each with its own unit direction.
"""
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from stages import flowmask, ingest, mesh, popup, spec as specs  # noqa: E402
import reconstruct  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SHARED = ['kind', 'milestone', 'artwork', 'title', 'size', 'manifestPath', 'details', 'beats',
          'revealSeconds', 'storySeconds', 'reveal', 'credit', 'sources', 'originalSourceUrl',
          'citations']


class Reproduction(unittest.TestCase):
    """The committed I/II manifests equal P06's on every shared field, so the
    generic pipeline reproduces them with no scene-specific code."""

    def test_i_and_ii(self):
        for name in ['anastasis', 'judgment']:
            old = json.loads((ROOT / f'tool/plate/fixtures/p06/{name}.json').read_text())
            new = json.loads((ROOT / f'assets/plates/{name}/manifest.json').read_text())
            for key in SHARED:
                self.assertEqual(old[key], new[key], f'{name}.{key}')
            self.assertEqual(new['schemaVersion'], 2)
            self.assertEqual(old['maps']['surface'], new['maps']['surface'])
            self.assertEqual(old['maps']['gold'], new['maps']['gold'])
            self.assertEqual(old['layers'][:2], new['layers'][:2])
        a = json.loads((ROOT / 'assets/plates/anastasis/manifest.json').read_text())
        self.assertEqual(a['layers'][2]['id'], 'reconstruction')
        self.assertEqual(a['rig']['path'], 'assets/explorer/anastasis_figures_v2.json')
        j = json.loads((ROOT / 'assets/plates/judgment/manifest.json').read_text())
        # Documented P07 changes: no wipe or rig for II; the scroll pivots on its mask.
        self.assertEqual([l['id'] for l in j['layers']], ['original', 'depth'])
        self.assertIsNone(j['rig'])
        self.assertEqual(j['spiral']['center'], [.489, .46])
        self.assertEqual(j['flow']['mask'], 'assets/plates/judgment/river.png')

    def test_no_scene_specific_code(self):
        for path in (ROOT / 'tool/plate').glob('**/*.py'):
            if path.name in {'remaster_maps.py', 'test_build.py'}:
                continue
            text = path.read_text()
            for token in ['anastasis', 'judgment', 'F02', 'F05', 'M11', 'M13', 'M35']:
                self.assertNotIn(token, text, f'{path.name} names {token}')


class Ingest(unittest.TestCase):
    def test_strip_keeps_pixels_and_drops_exif(self):
        image = Image.fromarray(np.random.default_rng(1).integers(0, 255, (40, 60, 3), np.uint8))
        exif = Image.Exif()
        exif[0x010F] = 'Camera maker'
        buf = io.BytesIO()
        image.save(buf, 'JPEG', exif=exif, quality=90)
        data = buf.getvalue()
        self.assertTrue(len(Image.open(io.BytesIO(data)).getexif()))
        out = ingest.strip_jpeg(data)
        self.assertEqual(len(Image.open(io.BytesIO(out)).getexif()), 0)
        self.assertTrue(np.array_equal(np.asarray(Image.open(io.BytesIO(out))),
                                       np.asarray(Image.open(io.BytesIO(data)))))
        with self.assertRaises(ValueError):
            ingest.strip_jpeg(b'not a jpeg')


class Mesh(unittest.TestCase):
    def height(self):
        yy, xx = np.mgrid[:120, :200]
        h = np.exp(-((xx - 100) ** 2 + (yy - 60) ** 2) / 400.0)
        h[30:50, 20:40] = 1.0  # a cliff that must be relaxed, not folded
        return h.astype(np.float32)

    def test_adaptive_mesh_is_valid_and_within_budget(self):
        v, t, record = mesh.build(self.height(), 3000)
        self.assertTrue(record['valid'], record)
        self.assertLessEqual(record['vertices'], 3000)
        self.assertEqual((record['flippedAtRest'], record['flippedAtMaxTilt']), (0, 0))
        self.assertGreater(record['relaxation']['verticesEased'], 0)
        flat_v, _, flat = mesh.build(np.zeros((120, 200), np.float32), 3000)
        self.assertLess(flat['vertices'], record['vertices'])  # adaptive, not uniform

    def test_validator_catches_flips_and_tears(self):
        v, t, _ = mesh.build(self.height(), 3000)
        flipped = t.astype(np.int64).copy()
        flipped[0] = flipped[0][[0, 2, 1]]
        self.assertIn('flipped triangles', mesh.validate(v, flipped, 3000)['problems'])
        torn = np.delete(t.astype(np.int64), len(t) // 2, axis=0)
        self.assertFalse(mesh.validate(v, torn, 3000)['valid'])
        self.assertIn('over the vertex budget', mesh.validate(v, t.astype(np.int64), 10)['problems'])


class Popup(unittest.TestCase):
    def test_split_inpaints_only_the_lifted_region(self):
        master = np.full((60, 80, 3), 120, np.uint8)
        master[20:40, 30:50] = (200, 40, 40)
        mask = np.zeros((60, 80), np.float32)
        mask[20:40, 30:50] = 1
        background, layers, record = popup.split(master, {'figure': mask},
                                                 [dict(id='figure', segment='figure', lift=.1)])
        self.assertEqual(layers[0][0], 'figure')
        self.assertEqual(layers[0][2].shape, (60, 80, 4))
        self.assertLess(abs(int(background[30, 40, 0]) - 120), 25)  # the figure is filled in
        self.assertTrue(np.array_equal(background[:5, :5], master[:5, :5]))  # outside untouched


class Spec(unittest.TestCase):
    def test_strict_keys_and_pinned_hash(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d) / 'x'
            folder.mkdir()
            base = dict(id='x', milestone='m', artwork='a', title=dict(en='T', tr='T'),
                        description=dict(en='D', tr='D'), manualMinutes=0,
                        source=dict(repo='a.jpg', sha256='0'), beats=[], reveal=dict(detail='d'),
                        sources=[])
            for broken in [dict(base, typo=1), dict(base, source=dict(repo='a.jpg')),
                           dict(base, title=dict(en='T')), dict(base, id='y')]:
                (folder / 'plate.yaml').write_text(json.dumps(broken))
                with self.assertRaises(SystemExit):
                    specs.load(folder / 'plate.yaml')

    def test_a_beat_wipes_only_a_layer_the_plate_has(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d) / 'x'
            folder.mkdir()
            base = dict(id='x', milestone='m', artwork='a', title=dict(en='T', tr='T'),
                        description=dict(en='D', tr='D'), manualMinutes=0,
                        source=dict(repo='a.jpg', sha256='0'), reveal=dict(detail='d'), sources=[])
            (folder / 'plate.yaml').write_text(json.dumps(
                dict(base, beats=[dict(detail='d', layer='imagined')])))
            with self.assertRaises(SystemExit):
                specs.load(folder / 'plate.yaml')
            (folder / 'plate.yaml').write_text(json.dumps(dict(
                base, layers=dict(imagined=dict(asset='i.jpg', mask='m.png')),
                beats=[dict(detail='d', layer='imagined')])))
            self.assertEqual(specs.load(folder / 'plate.yaml').beats[0]['layer'], 'imagined')


class Reconstruct(unittest.TestCase):
    """P12's WR recipe: gold re-laid only inside the measured loss."""

    def test_gold_fills_the_plaster_and_nothing_else(self):
        rng = np.random.default_rng(3)
        h, w = 120, 160
        img = np.full((h, w, 3), (200, 160, 60), np.int32) + rng.integers(-20, 20, (h, w, 3))
        img = np.clip(img, 0, 255).astype(np.uint8)
        img[70:110, 40:120] = (210, 210, 205)            # bare plaster
        loss = reconstruct.loss_mask(img, dict(box=[0, 0, 1, 1], saturation=.16, value=.55,
                                               min_area=100))
        self.assertEqual(loss[90, 80], 1)
        self.assertEqual(loss[20, 20], 0)
        ground = reconstruct.ground_mask(img, dict(box=[0, 0, 1, 1], hue=[30, 62],
                                                   saturation=.35, value=.45))
        out = reconstruct.fill(img, loss, ground, 16, 1)
        self.assertTrue(np.allclose(out[:50], img[:50], atol=1))   # far from the loss: untouched
        self.assertGreater(out[90, 80, 0] - out[90, 80, 2], 60)    # the plaster is gold now
        again = reconstruct.fill(img, loss, ground, 16, 1)
        self.assertTrue(np.array_equal(out, again))                # deterministic for a seed

    def test_a_chosen_slot_is_its_shapes(self):
        img = np.zeros((100, 200, 3), np.uint8)
        m = reconstruct.loss_mask(img, dict(shapes=[[.5, .5, .1, .2]]))
        self.assertEqual(m[50, 100], 1)
        self.assertEqual(m[50, 140], 0)


class SwayMask(unittest.TestCase):
    def test_a_sway_mask_is_its_segments_feathered_inward(self):
        h, w = 120, 200
        a = np.zeros((h, w), np.float32)
        a[20:80, 20:80] = 1
        b = np.zeros((h, w), np.float32)
        b[30:90, 120:180] = 1
        with tempfile.TemporaryDirectory() as d:
            rel = Path(d).relative_to(ROOT) if Path(d).is_relative_to(ROOT) else None
            out = Path(d) / 'm.png'

            class Spec:
                id = 'x'

                def get(self, key, default=None):
                    return dict(mask=str(out), feather=.02, motion='sway', from_=None,
                                **{'from': [dict(segment='a', direction=[0, -2]),
                                            dict(segment='b', direction=[3, 4])]})
            flowmask.ROOT = Path('/')
            try:
                rec = flowmask.compose(Spec(), dict(a=a, b=b), (h, w, 3))
            finally:
                flowmask.ROOT = ROOT
            self.assertIsNotNone(rel or rec)
            m = np.asarray(Image.open(out).convert('RGB')).astype(np.float32) / 255
        cov = m[..., 0]
        # Nothing outside the segments; the middles fully covered; the edge
        # feathered inside the outline, so it stays pinned.
        self.assertEqual(cov[a + b == 0].max(), 0)
        self.assertGreater(cov[50, 50], .99)
        self.assertLess(cov[20, 50], .2)
        self.assertLess(cov[20, 50], cov[22, 50])
        self.assertGreater(cov[24, 50], .99)
        # Each segment keeps its own direction, normalised.
        self.assertAlmostEqual(m[50, 50, 1] * 2 - 1, 0, delta=.01)
        self.assertAlmostEqual(m[50, 50, 2] * 2 - 1, -1, delta=.01)
        self.assertAlmostEqual(m[60, 150, 1] * 2 - 1, .6, delta=.01)
        self.assertAlmostEqual(m[60, 150, 2] * 2 - 1, .8, delta=.01)
        self.assertEqual(rec['segments']['b']['direction'], [.6, .8])


if __name__ == '__main__':
    unittest.main()
