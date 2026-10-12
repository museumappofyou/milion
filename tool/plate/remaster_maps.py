"""Usage: python3.11 tool/plate/remaster_maps.py — builds the P06 plate maps.

Offline and deterministic. Reads the P05-era studio builds and the credited
masters, and writes the runtime maps under assets/plates/:

  anastasis/surface.png  RGB normal (encoded 0..1) + alpha height
  anastasis/gold.png     gilded-zone mask (mandorla cluster + gold pigment)
  anastasis/damaged.png  damaged-zone mask for the reconstruction wipe
  judgment/surface.png   same, from the Last Judgment build
  judgment/gold.png      authored gilded-zone mask (mandorla + halos)
  judgment/river.png     river of fire mask + flow direction in GB
  judgment/scroll.png    rolled-heaven mask for the UV spiral

Inputs (all committed or studio-kept): the v5 height/normal maps, the Part
labels of the Last Judgment build (the parts order matches
studio/last_judgment_25d/v5/authoring/layers.json), the semantic cluster map
of the Anastasis build, and the credited 4K Anastasis restoration image.
These are I and II's hand-authored inputs; tool/plate/build.py reads them as
provided maps and writes the manifests.
"""
import json
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/plates'
STUDIO_A = ROOT / 'studio/anastasis_25d/v5'
STUDIO_J = ROOT / 'studio/last_judgment_25d/v5'


def write(path, image):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not cv2.imwrite(str(path), image):
        raise RuntimeError(f'could not write {path}')


def surface_map(height16, normals, height_max):
    h = np.clip(height16.astype(np.float32) / 256.0 / height_max, 0, 1)
    b, g, r = normals[..., 0], normals[..., 1], normals[..., 2]
    return np.dstack([b, g, r, (h * 255).astype(np.uint8)])


def clean_mask(mask, close=5, open_=3, blur=1.6):
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (close, close))
    mask = cv2.morphologyEx((mask > 0).astype(np.uint8) * 255, cv2.MORPH_CLOSE, kernel, iterations=2)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (open_, open_))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    return cv2.GaussianBlur(mask, (0, 0), blur)


def largest_components(mask, count=3, min_area=4000):
    mask = (mask > 0).astype(np.uint8)
    n, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    keep = sorted(range(1, n), key=lambda i: -stats[i, cv2.CC_STAT_AREA])[:count]
    out = np.zeros_like(mask)
    for i in keep:
        if stats[i, cv2.CC_STAT_AREA] >= min_area:
            out[labels == i] = 1
    return out


def damage_map(master, restored_path):
    restored = cv2.imread(str(restored_path))
    if restored is None:
        raise SystemExit(f'Missing reconstruction study: {restored_path}')
    restored = cv2.resize(restored, (master.shape[1], master.shape[0]), interpolation=cv2.INTER_AREA)
    diff = np.abs(restored.astype(np.float32) - master.astype(np.float32)).mean(2)
    hsv = cv2.cvtColor(master, cv2.COLOR_BGR2HSV)
    pale = ((hsv[..., 1] < 55) & (diff > 22)).astype(np.uint8)
    damaged = largest_components(clean_mask(pale * 255, close=9, open_=5, blur=6.0), count=4)
    return clean_mask(damaged * 255, close=7, blur=4.0)


def anastasis():
    master = cv2.imread(str(ROOT / 'assets/anastasis/conch_reference.jpg'))
    height16 = cv2.imread(str(STUDIO_A / 'build/height16.png'), cv2.IMREAD_UNCHANGED)
    normals = cv2.imread(str(STUDIO_A / 'build/normals.png'))
    if master is None or height16 is None or normals is None:
        raise SystemExit('Anastasis studio inputs missing; run tool/build_anastasis_v5.py first')
    assert master.shape[:2] == height16.shape == normals.shape[:2]

    write(OUT / 'anastasis/surface.png', surface_map(height16, normals, 90.0))

    # Authored mandorla/halo masks, not a warm-pigment heuristic across robes
    # and plaster. The prepared heuristic had gilded two thirds of the plate.
    mandorla = cv2.imread(str(STUDIO_A / 'authoring/sam/mandorla.png'), cv2.IMREAD_GRAYSCALE)
    halos = cv2.imread(str(STUDIO_A / 'authoring/sam/l_rear_halos.png'), cv2.IMREAD_GRAYSCALE)
    if mandorla is None or halos is None:
        raise SystemExit('Anastasis authored gold masks missing')
    assert mandorla.shape == halos.shape == master.shape[:2]
    cv2.circle(halos, (968, 398), 52, 255, -1)  # authoring/layers.json: christ_halo
    mandorla = clean_mask(mandorla, close=9, blur=3.0)
    gold = np.maximum(mandorla, clean_mask(halos, blur=2.0))
    write(OUT / 'anastasis/gold.png', gold)

    # Damaged zones: where the 4K study repaints most and the pigment is pale.
    damaged = damage_map(master, ROOT / 'assets/restoration/anastasis_restored_4k_v2.jpg')
    write(OUT / 'anastasis/damaged.png', damaged)
    print('anastasis gold px', int((gold > 96).sum()), 'damaged px', int((damaged > 96).sum()))


def judgment():
    master = cv2.imread(str(ROOT / 'assets/last_judgment/vault_reference.jpg'))
    height16 = cv2.imread(str(STUDIO_J / 'height16.png'), cv2.IMREAD_UNCHANGED)
    normals = cv2.imread(str(ROOT / 'assets/last_judgment/relief_v5/normals.jpg'))
    labels = cv2.imread(str(STUDIO_J / 'part_labels.png'), cv2.IMREAD_UNCHANGED)
    layers = json.loads((STUDIO_J / 'authoring/layers.json').read_text())
    assert master.shape[:2] == height16.shape == labels.shape

    write(OUT / 'judgment/surface.png', surface_map(height16, normals, 90.0))

    index = {part['id']: i + 1 for i, part in enumerate(layers['parts'])}
    def mask_of(*ids):
        m = np.zeros(labels.shape, np.uint8)
        for id in ids:
            m |= (labels == index[id]).astype(np.uint8)
        return m * 255

    halos = [id for id in index if id.endswith('_halo')]
    gold_parts = mask_of('mandorla', 'christ_halo', *halos)
    gold = clean_mask(gold_parts, close=7, blur=2.5)
    write(OUT / 'judgment/gold.png', gold)
    # No reconstruction wipe for II: WR is not one of its techniques, and the
    # pale-and-differs heuristic swallowed half the fresco (P07 audit).

    river = clean_mask(mask_of('river_of_fire'), close=7, blur=1.8)
    ys, xs = np.nonzero(river > 96)
    print('river px', len(xs), 'bbox', xs.min(), ys.min(), xs.max(), ys.max())

    # Flow follows the painted river toward the lake of fire (lower right):
    # a constant heading bent slightly by the horizontal position.
    h, w = river.shape
    x = np.arange(w, dtype=np.float32)[None, :]
    angle = np.deg2rad(66.0) - 0.55 * (x / w - 0.5)
    dx = np.broadcast_to(np.sin(angle), (h, w))
    dy = np.broadcast_to(np.cos(angle), (h, w))
    # OpenCV writes BGR, while plate.frag samples RGB: coverage must be R,
    # with dx in G and dy in B. Putting the mask in B moves the whole plate.
    flow = np.dstack([
        ((dy * 0.5 + 0.5) * 255).astype(np.uint8),
        ((dx * 0.5 + 0.5) * 255).astype(np.uint8),
        river,
    ])
    write(OUT / 'judgment/river.png', flow)

    scroll = clean_mask(mask_of('rolled_heaven', 'heaven_scroll_lip'), close=7, blur=1.5)
    ys, xs = np.nonzero(scroll > 96)
    print('scroll px', len(xs), 'bbox', xs.min(), ys.min(), xs.max(), ys.max())
    write(OUT / 'judgment/scroll.png', scroll)


if __name__ == '__main__':
    anastasis()
    judgment()
    print('wrote', OUT)
