"""Fixed-camera renders of the v5 relief height field.

Usage: python3.11 tool/render_anastasis_v5.py
* front: centered orthographic view, no parallax (identical pixel positions
  to the photograph), restrained production light or exaggerated debug light;
* side: the same height field seen from 45 degrees, rendered as a solid with
  plaster side walls so physical stacking is visible;
* crops, phone-size frames and labelled comparison sheets.
"""
import cv2
import numpy as np

from build_anastasis_v5 import LIGHT, to_linear, to_srgb


def side_view(color, H, region=None, yaw=45.0, pitch=16.0, zscale=1.0,
              out_scale=0.75, light=LIGHT, bg=(28, 28, 32)):
    """Orthographic view of a height field from the right at `yaw` degrees and
    slightly above at `pitch` degrees. `color` is the front-lit RGB (BGR),
    `region` = (x0, y0, x1, y1) restricts the rendered part."""
    if region is not None:
        x0, y0, x1, y1 = region
        color, H = color[y0:y1, x0:x1], H[y0:y1, x0:x1]
    final_scale, out_scale = out_scale, min(out_scale, 0.9)
    h, w = H.shape
    Z = H.astype(np.float32) * zscale
    th, ph = np.radians(yaw), np.radians(pitch)
    # Camera direction (toward the viewer), screen right and screen down.
    c = np.array([np.sin(th) * np.cos(ph), -np.sin(ph), np.cos(th) * np.cos(ph)])
    right = np.array([np.cos(th), 0.0, -np.sin(th)])
    down = np.cross(c, right)  # image y grows downward
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    pts = [np.stack([xx.ravel(), yy.ravel(), Z.ravel()], 1)]
    cols = [color.reshape(-1, 3).astype(np.float32)]
    # Side walls: columns down to the lowest 4-neighbour.
    zp = np.pad(Z, 1, mode='edge')
    zmin = np.minimum.reduce([zp[1:-1, :-2], zp[1:-1, 2:], zp[:-2, 1:-1], zp[2:, 1:-1]])
    drop = Z - zmin
    gy, gx = np.gradient(Z)
    mag = np.hypot(gx, gy) + 1e-6
    wall_n = np.dstack([-gx / mag, -gy / mag, np.zeros_like(gx)])
    wl = 0.45 + 0.55 * np.clip(np.tensordot(wall_n, light, axes=([2], [0])) / np.hypot(light[0], light[1]), 0, 1)
    lin = to_linear(color[..., ::-1])
    plaster = to_srgb(lin * 0.55 + 0.28 * np.array([0.62, 0.57, 0.5]))[..., ::-1].astype(np.float32)
    ys, xs = np.nonzero(drop > 0.8)
    if len(ys):
        steps = np.ceil(drop[ys, xs] / 0.6).astype(int)
        rep = np.repeat(np.arange(len(ys)), steps)
        frac = (np.arange(len(rep)) - np.repeat(np.cumsum(steps) - steps, steps) + 0.5) / np.repeat(steps, steps)
        zz = zmin[ys, xs][rep] + frac * drop[ys, xs][rep]
        pts.append(np.stack([xs[rep].astype(np.float32), ys[rep].astype(np.float32), zz], 1))
        cols.append(plaster[ys, xs][rep] * wl[ys, xs][rep][:, None])
    P = np.concatenate(pts)
    C = np.concatenate(cols)
    P[:, 0] -= w / 2
    P[:, 1] -= h / 2
    sx = P @ right
    sy = P @ down
    depth = P @ c
    sx = (sx - sx.min()) * out_scale
    sy = (sy - sy.min()) * out_scale
    W, Hh = int(sx.max()) + 3, int(sy.max()) + 3
    u, v = sx.astype(np.int32) + 1, sy.astype(np.int32) + 1
    out = np.zeros((Hh, W, 3), np.uint8)
    out[:] = bg
    filled = np.zeros((Hh, W), bool)
    for du, dv in ((0, 0), (1, 0), (0, 1), (1, 1)):
        li = (v + dv) * W + (u + du)
        order = np.lexsort((depth, li))
        lo = li[order]
        last = np.r_[lo[1:] != lo[:-1], True]
        sel = order[last]
        # Only fill with the offset splat where no direct sample landed.
        tv, tu = v[sel] + dv, u[sel] + du
        if (du, dv) == (0, 0):
            out[tv, tu] = np.clip(C[sel], 0, 255)
            filled[tv, tu] = True
            zbuf = np.full((Hh, W), -1e9, np.float32)
            zbuf[tv, tu] = depth[sel]
        else:
            ok = ~filled[tv, tu] | (depth[sel] > zbuf[tv, tu] + 1.5)
            out[tv[ok], tu[ok]] = np.clip(C[sel][ok], 0, 255)
            zbuf[tv[ok], tu[ok]] = np.maximum(zbuf[tv[ok], tu[ok]], depth[sel][ok])
            filled[tv[ok], tu[ok]] = True
    if final_scale != out_scale:
        out = cv2.resize(out, None, fx=final_scale / out_scale, fy=final_scale / out_scale,
                         interpolation=cv2.INTER_CUBIC)
    return out


def label(img, text, scale=0.7, pad=8):
    out = img.copy()
    (tw, th), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, scale, 2)
    cv2.rectangle(out, (0, 0), (tw + 2 * pad, th + 2 * pad), (20, 20, 20), -1)
    cv2.putText(out, text, (pad, th + pad), cv2.FONT_HERSHEY_SIMPLEX, scale, (240, 240, 240), 2, cv2.LINE_AA)
    return out


def fit(img, width=None, height=None):
    h, w = img.shape[:2]
    s = (width / w) if width else (height / h)
    return cv2.resize(img, (max(1, round(w * s)), max(1, round(h * s))),
                      interpolation=cv2.INTER_AREA if s < 1 else cv2.INTER_CUBIC)


def hstack(imgs, gap=6, bg=(18, 18, 18)):
    h = max(i.shape[0] for i in imgs)
    row = []
    for i, im in enumerate(imgs):
        if im.shape[0] < h:
            im = np.vstack([im, np.full((h - im.shape[0], im.shape[1], 3), bg, np.uint8)])
        row.append(im)
        if i < len(imgs) - 1:
            row.append(np.full((h, gap, 3), bg, np.uint8))
    return np.hstack(row)


def vstack(imgs, gap=6, bg=(18, 18, 18)):
    w = max(i.shape[1] for i in imgs)
    col = []
    for i, im in enumerate(imgs):
        if im.shape[1] < w:
            im = np.hstack([im, np.full((im.shape[0], w - im.shape[1], 3), bg, np.uint8)])
        col.append(im)
        if i < len(imgs) - 1:
            col.append(np.full((gap, w, 3), bg, np.uint8))
    return np.vstack(col)
