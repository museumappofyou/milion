"""Authoring aid for the v5 semantic masks.

Usage: python3.11 tool/anastasis_v5_sam_masks.py
Runs Segment Anything (ViT-H) with hand-placed point and box prompts from
studio/anastasis_25d/v5/authoring/sam_prompts.json on crops of the master photograph.
The resulting binary masks are written to studio/anastasis_25d/v5/authoring/sam/ and
are only a starting point: tool/build_anastasis_v5.py reads them, resolves the
painted overlap order and applies the hand corrections in its own polygons.

Requires: pip install segment-anything torch, plus the ViT-H checkpoint
(sam_vit_h_4b8939.pth) given by SAM_CHECKPOINT.
"""
import json, os, sys
from pathlib import Path
import cv2
import numpy as np
import torch

try:
    import torchvision  # noqa: F401
except ImportError:  # segment_anything only needs two PIL helpers from it.
    import types
    from PIL import Image
    tv = types.ModuleType('torchvision'); tvt = types.ModuleType('torchvision.transforms')
    tvf = types.ModuleType('torchvision.transforms.functional')
    tvf.to_pil_image = lambda a: Image.fromarray(np.asarray(a))
    tvf.resize = lambda im, size: im.resize((size[1], size[0]), Image.BILINEAR)
    ops = types.ModuleType('torchvision.ops'); boxes = types.ModuleType('torchvision.ops.boxes')
    boxes.batched_nms = boxes.box_area = None  # automatic generator is unused
    tv.transforms = tvt; tvt.functional = tvf; tv.ops = ops; ops.boxes = boxes
    sys.modules.update({'torchvision': tv, 'torchvision.transforms': tvt,
                        'torchvision.transforms.functional': tvf,
                        'torchvision.ops': ops, 'torchvision.ops.boxes': boxes})
from segment_anything import sam_model_registry, SamPredictor

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / 'assets/anastasis/conch_reference.jpg'
AUTH = ROOT / 'studio/anastasis_25d/v5/authoring'
OUT = AUTH / 'sam'


def main(only=None):
    ckpt = os.environ.get('SAM_CHECKPOINT')
    if not ckpt:
        sys.exit('Set SAM_CHECKPOINT to sam_vit_h_4b8939.pth')
    prompts = json.loads((AUTH / 'sam_prompts.json').read_text())
    image = cv2.cvtColor(cv2.imread(str(MASTER)), cv2.COLOR_BGR2RGB)
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    sam = sam_model_registry['vit_h'](checkpoint=ckpt)
    sam.to(device)
    predictor = SamPredictor(sam)
    OUT.mkdir(parents=True, exist_ok=True)
    by_crop = {}
    for item in prompts['masks']:
        if only and item['id'] not in only:
            continue
        by_crop.setdefault(tuple(item['crop']), []).append(item)
    for crop, items in by_crop.items():
        x0, y0, x1, y1 = crop
        predictor.set_image(image[y0:y1, x0:x1])
        for item in items:
            pts = np.array([[p[0] - x0, p[1] - y0] for p in item['pos'] + item.get('neg', [])], float)
            lab = np.array([1] * len(item['pos']) + [0] * len(item.get('neg', [])))
            box = None
            if 'box' in item:
                bx = item['box']
                box = np.array([bx[0] - x0, bx[1] - y0, bx[2] - x0, bx[3] - y0], float)
            masks, scores, _ = predictor.predict(
                point_coords=pts, point_labels=lab, box=box,
                multimask_output=item.get('multi', False))
            pick = int(item.get('pick', int(np.argmax(scores))))
            m = masks[pick].astype(np.uint8) * 255
            full = np.zeros(image.shape[:2], np.uint8)
            full[y0:y1, x0:x1] = m
            cv2.imwrite(str(OUT / f"{item['id']}.png"), full)
            print(item['id'], 'scores', np.round(scores, 3).tolist(), 'area', int((full > 0).sum()))


if __name__ == '__main__':
    main(set(sys.argv[1:]) or None)
