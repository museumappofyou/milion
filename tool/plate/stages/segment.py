"""Stage (b) segmentation: prompts in, one float mask per segment out.

Input: the master RGB array and `segments` from the yaml, each with a
normalised box and optional positive points. A manual mask PNG
(`segments[].mask`, white = inside) always overrides the model.
Output: {segment id: float32 HxW in 0..1} and a record of how each mask was
made (manual / SAM 2.1 with its pinned revision and score).

Model: SAM 2.1 hiera-small through transformers, run on CPU so the result is
reproducible; outputs are cached by master hash, prompt and revision.
"""
import numpy as np
from PIL import Image

from . import cache

SAM = ('facebook/sam2.1-hiera-small', 'ee5bba1d82bb8749febdf90f45e84b687142ba03')
_model = None


def _sam():
    global _model
    if _model is None:
        from transformers import Sam2Model, Sam2Processor
        _model = (Sam2Processor.from_pretrained(SAM[0], revision=SAM[1]),
                  Sam2Model.from_pretrained(SAM[0], revision=SAM[1]).eval())
    return _model


def _predict(master, box, points):
    import torch
    processor, model = _sam()
    h, w = master.shape[:2]
    kwargs = dict(images=Image.fromarray(master),
                  input_boxes=[[[box[0] * w, box[1] * h, box[2] * w, box[3] * h]]],
                  return_tensors='pt')
    if points:
        kwargs['input_points'] = [[[[x * w, y * h] for x, y in points]]]
        kwargs['input_labels'] = [[[1] * len(points)]]
    inputs = processor(**kwargs)
    with torch.no_grad():
        out = model(**inputs, multimask_output=False)
    mask = processor.post_process_masks(out.pred_masks, inputs['original_sizes'])[0]
    score = float(out.iou_scores.reshape(-1)[0])
    return mask.reshape(-1, h, w)[0].numpy().astype(np.float32), score


def segment(spec, master, master_sha):
    masks, record = {}, {}
    for s in spec.get('segments', []):
        if s.get('mask'):
            m = np.asarray(Image.open(spec.local(s['mask'])).convert('L'), np.float32) / 255
            if m.shape != master.shape[:2]:
                raise SystemExit(f'{s["mask"]}: mask size differs from the master')
            masks[s['id']] = m
            record[s['id']] = dict(method='manual', path=s['mask'], coverage=round(float(m.mean()), 4))
            continue
        k = cache.key('sam', SAM, master_sha, s['box'], s.get('points', []))

        def run():
            m, iou = _predict(master, s['box'], s.get('points', []))
            return m, dict(iou=round(iou, 3))
        m, info = cache.cached('sam', k, run)
        masks[s['id']] = m
        record[s['id']] = dict(method='sam2.1-hiera-small', revision=SAM[1],
                               coverage=round(float(m.mean()), 4), **info)
    return masks, record
