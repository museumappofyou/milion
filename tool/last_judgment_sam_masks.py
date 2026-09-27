"""Optional SAM authoring aid. Committed masks make normal builds independent of SAM.
SAM_CHECKPOINT=/path/to/sam_vit_h.pth python3.11 tool/last_judgment_sam_masks.py
"""
import json, os, sys
from pathlib import Path
import cv2
import numpy as np
# Reuse the existing optional torchvision compatibility shim and SAM imports.
from anastasis_v5_sam_masks import torch, sam_model_registry, SamPredictor

ROOT = Path(__file__).resolve().parents[1]
AUTH = ROOT / 'studio/last_judgment_25d/v5/authoring'

def main():
    image = cv2.cvtColor(cv2.imread(str(ROOT / 'assets/last_judgment/vault_reference.jpg')), cv2.COLOR_BGR2RGB)
    h,w = image.shape[:2]
    scale = np.array([w/1500,h/1000])
    model = sam_model_registry['vit_h'](checkpoint=os.environ['SAM_CHECKPOINT'])
    model.to('mps' if torch.backends.mps.is_available() else 'cpu')
    predictor = SamPredictor(model)
    predictor.set_image(image)
    for name,item in json.loads((AUTH/'sam_prompts.json').read_text()).items():
        if len(sys.argv)>1 and name not in sys.argv[1:]: continue
        points = np.array(item['pos']+item['neg'])*scale
        labels = np.array([1]*len(item['pos'])+[0]*len(item['neg']))
        masks,scores,_ = predictor.predict(point_coords=points,point_labels=labels,
            box=np.array(item['box'])*np.tile(scale,2),multimask_output=False)
        mask=masks[0].astype(np.uint8)*255
        # Enforce the reviewed bounding region; SAM may spill onto adjacent robes.
        x0,y0,x1,y1=np.round(np.array(item['box'])*np.tile(scale,2)).astype(int)
        keep=np.zeros_like(mask);keep[y0:y1,x0:x1]=mask[y0:y1,x0:x1]
        cv2.imwrite(str(AUTH/'masks'/f'{name}.png'),keep)
        print(name,round(float(scores[0]),3),int((keep>0).sum()),flush=True)

if __name__=='__main__': main()
