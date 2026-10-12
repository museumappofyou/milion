"""Stage (d) optional pop-up (PU) layer split.

Input: the master RGB array, segment masks and `popup` entries
({id, segment, lift}). Output: for each entry an RGBA cut-out of the segment
and one background with the union of lifted regions inpainted (OpenCV Telea;
LaMa is not installed locally), plus coverage stats. Written to the plate's
studio build folder; the runtime PU renderer arrives with the first PU
Milestone (P14), so nothing here is bundled yet.
"""
import cv2
import numpy as np


def split(master, masks, entries):
    if not entries:
        return None, [], {}
    union = np.zeros(master.shape[:2], np.uint8)
    layers = []
    for e in entries:
        m = (masks[e['segment']] > .5).astype(np.uint8)
        alpha = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.0)
        layers.append((e['id'], float(e['lift']), np.dstack([master, (alpha * 255).astype(np.uint8)])))
        union |= m
    hole = cv2.dilate(union, np.ones((7, 7), np.uint8))
    background = cv2.inpaint(master, hole * 255, 5, cv2.INPAINT_TELEA)
    record = dict(method='opencv-telea', layers=[e['id'] for e in entries],
                  inpaintedCoverage=round(float(hole.mean()), 4))
    return background, layers, record
