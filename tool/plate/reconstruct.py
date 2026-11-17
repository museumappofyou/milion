"""Usage: python3.11 tool/plate/reconstruct.py studio/plates/<id>/reconstruct.yaml

Authoring tool for a WR layer that fills a mosaic's losses (P12, Milestone
VII). Input: the plate's master (assets/plates/<id>/original.jpg, written by
the pipeline's ingest) and a small yaml:

    out: {image: assets/plates/<id>/<name>.jpg, mask: assets/plates/<id>/<name>.png}
    loss: {box: [l, t, r, b], saturation: <max>, value: <min>, close: px, open: px,
           keep: [[cx, cy, rx, ry], ...]}   # bare plaster: pale and grey; faces kept
       or {shapes: [[cx, cy, rx, ry], ...]} # a chosen slot (an IMAGINED layer)
    ground: {box: [l, t, r, b], hue: [lo, hi], saturation: <min>, value: <min>,
             patch: px, seed: n}            # where the surviving gold is sampled
    lines: [{points: [[x, y], ...], width: px, colour: [r, g, b], dash: [on, off]?}]

Output: the image with the loss re-laid in gold sampled patch by patch from
the surviving ground (the setting pattern continues; nothing is invented
beyond the gold), the lines drawn over it in hairline (what is conjectured is
only drawn, never painted), and the loss mask the player wipes inside. The
master itself is never changed. Deterministic for a given seed.
"""
import sys
from pathlib import Path

import cv2
import numpy as np
import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def box_px(b, w, h):
    return int(b[0] * w), int(b[1] * h), int(b[2] * w), int(b[3] * h)


def loss_mask(rgb, spec):
    h, w = rgb.shape[:2]
    if 'shapes' in spec:      # a chosen slot rather than a measured loss
        m = np.zeros((h, w), np.uint8)
        for k in spec['shapes']:
            cv2.ellipse(m, (int(k[0] * w), int(k[1] * h)), (int(k[2] * w), int(k[3] * h)),
                        0, 0, 360, 1, -1)
        return m
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    s, v = hsv[..., 1].astype(np.float32) / 255, hsv[..., 2].astype(np.float32) / 255
    m = ((s <= spec['saturation']) & (v >= spec['value'])).astype(np.uint8)
    l, t, r, b = box_px(spec['box'], w, h)
    region = np.zeros_like(m)
    region[t:b, l:r] = 1
    m &= region
    for k in spec.get('keep', []):         # [cx, cy, rx, ry]: an ellipse kept as it is
        cv2.ellipse(m, (int(k[0] * w), int(k[1] * h)), (int(k[2] * w), int(k[3] * h)),
                    0, 0, 360, 0, -1)
    if spec.get('open'):
        k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (spec['open'],) * 2)
        m = cv2.morphologyEx(m, cv2.MORPH_OPEN, k)
    if spec.get('close'):
        k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (spec['close'],) * 2)
        m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, k)
    # Keep only large connected losses: specks of pale tesserae are not loss.
    n, labels, stats, _ = cv2.connectedComponentsWithStats(m, 8)
    keep = np.zeros_like(m)
    for i in range(1, n):
        if stats[i, cv2.CC_STAT_AREA] >= spec.get('min_area', 4000):
            keep[labels == i] = 1
    return keep


def ground_mask(rgb, spec):
    h, w = rgb.shape[:2]
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    hue = hsv[..., 0].astype(np.float32) * 2
    s, v = hsv[..., 1].astype(np.float32) / 255, hsv[..., 2].astype(np.float32) / 255
    lo, hi = spec['hue']
    m = ((hue >= lo) & (hue <= hi) & (s >= spec['saturation']) & (v >= spec['value'])).astype(np.uint8)
    l, t, r, b = box_px(spec['box'], w, h)
    region = np.zeros_like(m)
    region[t:b, l:r] = 1
    return m & region


def fill(rgb, loss, ground, patch, seed):
    """The ground's colour, smoothed and carried into the loss (a normalised
    convolution of the surviving ground), plus the fine texture of random
    patches of that ground (each patch less its own blur), so the setting
    pattern continues without patchy tones; the loss's edge is feathered."""
    h, w = loss.shape
    rng = np.random.default_rng(seed)
    img = rgb.astype(np.float32)
    g = ground.astype(np.float32)
    sigma = max(h, w) / 18
    weight = cv2.GaussianBlur(g, (0, 0), sigma)
    mean = (img * g[..., None]).reshape(-1, 3).sum(0) / max(g.sum(), 1)
    base = cv2.GaussianBlur(img * g[..., None], (0, 0), sigma) / np.maximum(weight, 1e-4)[..., None]
    trust = np.clip(weight / .15, 0, 1)[..., None]
    base = base * trust + mean * (1 - trust)
    detail = img - cv2.GaussianBlur(img, (0, 0), patch / 6)
    integral = cv2.integral(ground)
    ys, xs = np.mgrid[0:h - patch:patch // 4, 0:w - patch:patch // 4]
    sums = (integral[ys + patch, xs + patch] - integral[ys, xs + patch]
            - integral[ys + patch, xs] + integral[ys, xs])
    cand = np.stack([ys[sums >= patch * patch * .97], xs[sums >= patch * patch * .97]], 1)
    if len(cand) < 8:
        raise SystemExit('too little ground to sample from')
    tex = np.zeros_like(img)
    norm = np.zeros((h, w, 1), np.float32)
    step = patch // 2
    ramp = np.minimum(1, (np.minimum(np.arange(patch), np.arange(patch)[::-1]) + 1) / (patch / 2))
    feather = np.minimum.outer(ramp, ramp)[..., None]
    grown = cv2.dilate(loss, np.ones((patch, patch), np.uint8))
    for y in range(-patch // 2, h, step):
        for x in range(-patch // 2, w, step):
            y0, x0 = max(0, y), max(0, x)
            y1, x1 = min(h, y + patch), min(w, x + patch)
            if y1 <= y0 or x1 <= x0 or not grown[y0:y1, x0:x1].any():
                continue
            sy, sx = cand[rng.integers(len(cand))]
            f = feather[y0 - y:y1 - y, x0 - x:x1 - x]
            tex[y0:y1, x0:x1] += detail[sy + (y0 - y):sy + (y1 - y), sx + (x0 - x):sx + (x1 - x)] * f
            norm[y0:y1, x0:x1] += f
    out = base + tex / np.maximum(norm, 1e-4)
    soft = cv2.GaussianBlur(loss.astype(np.float32), (0, 0), 2.5)[..., None]
    return img * (1 - soft) + out * soft


def draw_lines(img, lines, w, h):
    for line in lines:
        pts = np.array([[p[0] * w, p[1] * h] for p in line['points']], np.float32)
        colour = tuple(int(c) for c in line.get('colour', [40, 32, 28]))
        width = line.get('width', 3)
        dash = line.get('dash')
        if not dash:
            cv2.polylines(img, [np.round(pts).astype(np.int32)], False, colour, width, cv2.LINE_AA)
            continue
        on, off = dash
        for a, b in zip(pts, pts[1:]):
            length = float(np.hypot(*(b - a)))
            t = 0.0
            while t < length:
                p0 = a + (b - a) * (t / length)
                p1 = a + (b - a) * (min(length, t + on) / length)
                cv2.line(img, tuple(np.round(p0).astype(int)), tuple(np.round(p1).astype(int)),
                         colour, width, cv2.LINE_AA)
                t += on + off


def main(path):
    spec = yaml.safe_load(Path(path).read_text())
    plate = spec.get('plate', Path(path).parent.name)
    master = ROOT / f'assets/plates/{plate}/original.jpg'
    rgb = np.asarray(Image.open(master).convert('RGB'))
    h, w = rgb.shape[:2]
    loss = loss_mask(rgb, spec['loss'])
    ground = ground_mask(rgb, spec['ground'])
    filled = fill(rgb, loss, ground, spec['ground'].get('patch', 48), spec['ground'].get('seed', 1))
    img = np.clip(filled + .5, 0, 255).astype(np.uint8)
    img = np.ascontiguousarray(img)
    draw_lines(img, spec.get('lines', []), w, h)
    out = spec['out']
    Image.fromarray(img).save(ROOT / out['image'], quality=88, subsampling=0)
    mask = cv2.GaussianBlur(loss.astype(np.float32), (0, 0), 1.5)
    Image.fromarray(np.clip(mask * 255 + .5, 0, 255).astype(np.uint8), 'L').save(ROOT / out['mask'])
    print(f'{out["image"]}: loss {loss.mean():.1%} of the plate, ground {ground.mean():.1%}')


if __name__ == '__main__':
    main(sys.argv[1])
