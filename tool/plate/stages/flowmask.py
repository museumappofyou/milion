"""Stage (b2), P13: a flow mask composed from segments.

Input: the segment masks of stage (b) and `flow.from` in the yaml, a list of
{segment, direction: [dx, dy]} in plate space (x right, y down), with
`flow.feather` (a fraction of the plate's longer side) the inward soft edge.
Output: the RGB PNG at `flow.mask` that shaders/plate.frag reads — R the
coverage, G and B the direction as 0.5 + d / 2 — and a record of it.

With `motion: sway` the shader moves the pixels back and forth along that
direction, scaled by the coverage, so a feathered edge stays pinned while the
middle of the figure moves: a short loop inside the figure, never a tear at
its outline. Overlapping segments take the stronger coverage's direction.
"""
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt

from .spec import ROOT


def compose(spec, masks, shape):
    flow = spec.get('flow') or {}
    sources = flow.get('from')
    if not sources:
        return None
    h, w = shape[:2]
    coverage = np.zeros((h, w), np.float32)
    dx = np.zeros((h, w), np.float32)
    dy = np.zeros((h, w), np.float32)
    radius = flow.get('feather', 0.006) * max(h, w)
    record = {}
    for s in sources:
        if s['segment'] not in masks:
            raise SystemExit(f'{spec.id}: flow.from names no segment {s["segment"]}')
        d = np.asarray(s['direction'], np.float32)
        n = float(np.hypot(*d))
        if n == 0:
            raise SystemExit(f'{spec.id}: {s["segment"]}: a zero direction')
        d /= n
        # Feather inward only: the coverage rises from 0 on the outline to 1
        # at `radius` inside it, so nothing outside the figure ever moves.
        inside = distance_transform_edt(masks[s['segment']] > .5)
        t = np.clip(inside / max(radius, 1.0), 0, 1).astype(np.float32)
        c = t * t * (3 - 2 * t)
        stronger = c > coverage
        dx[stronger], dy[stronger] = d[0], d[1]
        coverage = np.maximum(coverage, c)
        record[s['segment']] = dict(direction=[round(float(v), 3) for v in d],
                                    coverage=round(float(c.mean()), 4))
    rgb = np.dstack([coverage, dx * .5 + .5, dy * .5 + .5])
    out = ROOT / flow['mask']
    out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(rgb, 0, 1) * 255).round().astype(np.uint8)).save(out, optimize=True)
    return dict(path=flow['mask'], feather=round(radius, 1), segments=record,
                coverage=round(float(coverage.mean()), 4))
