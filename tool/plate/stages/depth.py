"""Stage (c) depth, normals and gold.

Input: the master RGB array, segment masks, and the yaml's `depth` and
`gold` blocks. Output: `height` (float32 HxW, 0..1, higher = nearer the
viewer), `normals` (float32 HxWx3, unit, image-space: x right, y down, z out)
and `gold` (float32 HxW, 0..1), plus measurements.

Height = modelWeight x the monocular relief + per-segment priors:
`planar` flattens a segment onto its least-squares plane (walls, grounds),
`bulge` raises a rounded profile from the mask's distance transform (figures,
domes), `none` keeps the model. A `provided` surface (P06's hand-built
relief for I and II) replaces the estimate; `measure` then scores each model
against it (Spearman rank correlation, raw and of the fine `detail`) and
records its runtime. The model contributes only its fine detail: see
`detail()`.

Models (pinned): Depth Anything V2 (small/base, transformers, CPU) and
Marigold depth v1.1 (diffusers; MPS when available, fixed seed).
Normals use n = normalize(-dh/dx, -dh/dy, 1/strength), the convention of the
P06 v5 maps that shaders/plate.frag reads. Gold = hue/saturation/value
heuristic for gilded tesserae, cleaned, optionally unioned with a hand mask.
"""
import time

import cv2
import numpy as np
from PIL import Image

from . import cache

MODELS = {
    'depth-anything-v2-small': ('depth-anything/Depth-Anything-V2-Small-hf',
                                '5426e4f0f36572d16453bbda7a8389317b1bef99'),
    'depth-anything-v2-base': ('depth-anything/Depth-Anything-V2-Base-hf',
                               'b1958afc87fb45a9e3746cb387596094de553ed8'),
    'marigold': ('prs-eth/marigold-depth-v1-1', '9571e7123e258cf052b4e54241f17971c290e9a8'),
}


def _depth_anything(master, name):
    import torch
    from transformers import AutoImageProcessor, AutoModelForDepthEstimation
    repo, rev = MODELS[name]
    processor = AutoImageProcessor.from_pretrained(repo, revision=rev)
    model = AutoModelForDepthEstimation.from_pretrained(repo, revision=rev).eval()
    inputs = processor(images=Image.fromarray(master), return_tensors='pt')
    with torch.no_grad():
        out = model(**inputs)
    h, w = master.shape[:2]
    post = processor.post_process_depth_estimation(out, target_sizes=[(h, w)])
    return post[0]['predicted_depth'].numpy().astype(np.float32)  # relative inverse depth


def _marigold(master):
    import torch
    from diffusers import MarigoldDepthPipeline
    repo, rev = MODELS['marigold']
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    pipe = MarigoldDepthPipeline.from_pretrained(
        repo, revision=rev, variant='fp16', torch_dtype=torch.float16).to(device)
    out = pipe(Image.fromarray(master), generator=torch.Generator('cpu').manual_seed(7),
               output_type='np')
    depth = np.asarray(out.prediction, np.float32).reshape(out.prediction.shape[-3:-1] if out.prediction.ndim == 4 else out.prediction.shape[-2:])
    depth = cv2.resize(depth, (master.shape[1], master.shape[0]), interpolation=cv2.INTER_CUBIC)
    return 1.0 - depth  # Marigold: 0 near, 1 far


def estimate(master, master_sha, name):
    """Model relief normalised to 0..1 (near = 1), cached, with its runtime."""
    def run():
        t = time.perf_counter()
        d = _marigold(master) if name == 'marigold' else _depth_anything(master, name)
        return d, dict(seconds=round(time.perf_counter() - t, 2))
    d, info = cache.cached('depth', cache.key(name, MODELS[name], master_sha), run)
    lo, hi = np.percentile(d, [1, 99])
    return np.clip((d - lo) / max(hi - lo, 1e-6), 0, 1).astype(np.float32), info.get('seconds')


def detail(relief):
    """The model's fine relief only. Monocular depth on a photographed wall
    or apse mostly measures the architecture (a concave conch reads as a
    bowl), not the pictorial depth a plate needs (P07 measurement), so the
    large-scale shape is removed and the priors give the figures their lift."""
    sigma = max(relief.shape) / 40
    high = relief - cv2.GaussianBlur(relief, (0, 0), sigma)
    lo, hi = np.percentile(high, [1, 99])
    return np.clip((high - lo) / max(hi - lo, 1e-6), 0, 1).astype(np.float32)


def _spearman(a, b):
    from scipy.stats import spearmanr
    step = max(1, a.size // 200000)
    return float(spearmanr(a.reshape(-1)[::step], b.reshape(-1)[::step]).statistic)


def _plane(height, mask):
    ys, xs = np.nonzero(mask > .5)
    if len(xs) < 3:
        return height
    A = np.c_[xs, ys, np.ones_like(xs)].astype(np.float64)
    coef, *_ = np.linalg.lstsq(A, height[ys, xs], rcond=None)
    yy, xx = np.mgrid[:height.shape[0], :height.shape[1]]
    return (coef[0] * xx + coef[1] * yy + coef[2]).astype(np.float32)


def _bulge(mask):
    m = (mask > .5).astype(np.uint8)
    if not m.any():
        return np.zeros(mask.shape, np.float32)
    d = cv2.distanceTransform(m, cv2.DIST_L2, 5)
    d /= max(float(d.max()), 1e-6)
    return np.sqrt(1 - (1 - d) ** 2).astype(np.float32)  # rounded, steep at the rim


def compose(model, segments, masks):
    """Blend the model relief with the per-segment priors (nearest segment wins)."""
    height = model.copy()
    for s in segments:
        m = cv2.GaussianBlur(masks[s['id']], (0, 0), 3)
        w = float(s.get('weight', .6))
        prior = s.get('prior', 'none')
        if prior == 'planar':
            target = _plane(model, masks[s['id']])
        elif prior == 'bulge':
            base = _plane(model, cv2.dilate((masks[s['id']] > .5).astype(np.uint8), np.ones((25, 25))) -
                          (masks[s['id']] > .5))
            target = base + .35 * _bulge(masks[s['id']])
        else:
            continue
        height = height * (1 - w * m) + target * (w * m)
    height = cv2.bilateralFilter(height.astype(np.float32), 9, .08, 5)
    lo, hi = np.percentile(height, [.5, 99.5])
    return np.clip((height - lo) / max(hi - lo, 1e-6), 0, 1).astype(np.float32)


def normals(height, strength=6.0):
    gx = cv2.Sobel(height, cv2.CV_32F, 1, 0, ksize=3)
    gy = cv2.Sobel(height, cv2.CV_32F, 0, 1, ksize=3)
    n = np.dstack([-gx * strength, -gy * strength, np.ones_like(height)])
    return n / np.linalg.norm(n, axis=2, keepdims=True)


def gold_mask(master, hand=None):
    """Gilded tesserae: warm hue, strongly saturated, and textured like
    tesserae. Measured on III–V (P07): gold ground is S 190–236 even in
    shadow (V 88–121), while bare plaster is S ~80 with a local deviation
    under 5, so value alone mislabels both; small specks are removed."""
    hsv = cv2.cvtColor(master, cv2.COLOR_RGB2HSV)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    gray = cv2.cvtColor(master, cv2.COLOR_RGB2GRAY).astype(np.float32)
    texture = np.sqrt(np.maximum(cv2.GaussianBlur(gray * gray, (0, 0), 3) -
                                 cv2.GaussianBlur(gray, (0, 0), 3) ** 2, 0))
    m = ((h >= 12) & (h <= 30) & (s >= 120) & (v >= 55) & (texture >= 6)).astype(np.uint8) * 255
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    m = cv2.morphologyEx(cv2.morphologyEx(m, cv2.MORPH_OPEN, k), cv2.MORPH_CLOSE, k)
    gold = cv2.GaussianBlur(m, (0, 0), 1.2).astype(np.float32) / 255
    if hand is not None:
        gold = np.maximum(gold, hand)
    return gold


def run(spec, master, master_sha, masks):
    cfg = spec.get('depth', {})
    record = {}
    provided = cfg.get('provided')
    if provided:
        surface = cv2.imread(str(spec.local(provided)), cv2.IMREAD_UNCHANGED)
        if surface is None or surface.shape[:2] != master.shape[:2]:
            raise SystemExit(f'{provided}: provided surface must match the master grid')
        height = surface[..., 3].astype(np.float32) / 255
        rgb = surface[..., [2, 1, 0]].astype(np.float32) / 255 * 2 - 1
        normal = rgb / np.maximum(np.linalg.norm(rgb, axis=2, keepdims=True), 1e-6)
        record['method'] = f'provided ({provided})'
    else:
        model, seconds = estimate(master, master_sha, cfg['model'])
        mw = float(cfg.get('modelWeight', .35))
        height = compose(detail(model) * mw + (1 - mw) * .5, spec.get('segments', []), masks)
        normal = normals(height, float(cfg.get('normalStrength', 6.0)))
        record.update(method=f'{cfg["model"]} x {mw} + priors', model=MODELS[cfg['model']],
                      seconds=seconds)
    measures = {}
    for name in cfg.get('measure', []):
        est, seconds = estimate(master, master_sha, name)
        measures[name] = dict(spearmanRaw=round(_spearman(est, height), 3),
                              spearmanDetail=round(_spearman(detail(est), height), 3),
                              seconds=seconds, revision=MODELS[name][1])
    if measures:
        record['measure'] = measures
    g = spec.get('gold', {})
    if g.get('provided'):
        gold = cv2.imread(str(spec.local(g['provided'])), cv2.IMREAD_GRAYSCALE).astype(np.float32) / 255
        record['gold'] = f'provided ({g["provided"]})'
    else:
        hand = None
        if g.get('hand'):
            hand = np.asarray(Image.open(spec.local(g['hand'])).convert('L'), np.float32) / 255
        gold = gold_mask(master, hand) if g.get('heuristic', True) else hand
        record['gold'] = 'heuristic' + (' + hand mask' if hand is not None else '')
    record['goldCoverage'] = round(float((gold > .5).mean()), 4)
    record['heightRange'] = [round(float(height.min()), 3), round(float(height.max()), 3)]
    return height, normal, gold, record
