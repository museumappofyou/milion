"""Fast, deterministic diagnostic renders from the shipped layer manifest.

Usage: python3.11 tool/render_anastasis_relief.py
This matches the photo projector's layer order and depth/parallax formula.
It does not replace the Flutter screenshots; it makes segmentation and ghost
edges inspectable without depending on a GPU or simulator.
"""
from pathlib import Path
import json
import cv2
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'studio/anastasis_25d/screenshots'
ASSET=ROOT/'assets/anastasis/relief'
manifest=json.loads((ASSET/'manifest.json').read_text())
base=cv2.imread(str(ROOT/manifest['master']))
layers=manifest['layers']
OUT.mkdir(parents=True,exist_ok=True)

def render(name,yaw=0,pitch=0,mode='original'):
    canvas=base.astype(np.float32)
    for layer in layers:
        path=ROOT/layer['texture']
        tex=cv2.imread(str(path),cv2.IMREAD_UNCHANGED)
        if tex is None: continue
        x,y,w,h=layer['crop']
        depth=layer['depth']*.25
        dx=(yaw/10.9)*depth*170
        dy=(pitch/6.9)*depth*145
        shift=cv2.getRotationMatrix2D((0,0),0,1)
        shift[0,2]=dx;shift[1,2]=dy
        shifted=cv2.warpAffine(tex,shift,(w,h),flags=cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
        if mode=='colors':
            rgb=tuple(int(layer['color'][i:i+2],16) for i in (5,3,1))
            shifted[:,:,:3]=rgb
        elif mode=='depth':
            t=min(1,layer['depth']/.4)
            shifted[:,:,:3]=(int(255*(1-t)),0,int(255*t))
        elif mode=='edges':
            mask=shifted[:,:,3]
            shifted[:,:,3]=cv2.morphologyEx(mask,cv2.MORPH_GRADIENT,np.ones((5,5),np.uint8))
            shifted[:,:,:3]=(35,55,255)
        region=canvas[y:y+h,x:x+w]
        alpha=shifted[:,:,3:4].astype(np.float32)/255
        region[:]=region*(1-alpha)+shifted[:,:,:3].astype(np.float32)*alpha
    cv2.imwrite(str(OUT/(name+'_diagnostic.png')),canvas.clip(0,255).astype(np.uint8))

for name,yaw,pitch in [('center',0,0),('slightly_left',-8,0),
                       ('slightly_right',8,0),('slightly_above',0,-5),
                       ('slightly_below',0,5)]:
    render(name,yaw,pitch)
(OUT/'center.png').write_bytes((OUT/'center_diagnostic.png').read_bytes())
for mode in ['colors','depth','edges']:
    render(mode,mode=mode)
im=cv2.imread(str(OUT/'center_diagnostic.png'))
cv2.imwrite(str(OUT/'christ_closeup.png'),im[290:860,790:1220])
