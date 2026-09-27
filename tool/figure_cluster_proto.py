"""Static left witness prototype: three depth clusters inside the painted outer edge.

The v3 outer group mask keeps the photographed silhouette. Hand-authored
partition curves follow the visible overlaps, not a global depth estimate.
Every result is derived from the original RGB photograph.
"""
from __future__ import annotations

import json
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'anastasis_25d/v4'
SOURCE=np.array(Image.open(ROOT/'assets/anastasis/conch_reference.jpg').convert('RGB'))
H,W=SOURCE.shape[:2]
CROP=(300,260,820,700)
OUTER=cv2.imread(str(ROOT/'assets/anastasis/relief_v3/left_front_group_mask.png'),0)
# x at each y. These divisions track the rear blue-cloaked witness, the
# red/green middle witness, and the front bearded witness in yellow robes.
# They are boundaries of compositional clusters, not claims about anatomy.
DIVISIONS={
 'rear_middle':[(260,500),(320,500),(350,495),(390,471),(435,442),(480,435),(540,423),(610,405),(700,392)],
 'middle_front':[(260,623),(335,623),(385,605),(430,595),(480,575),(540,557),(610,544),(700,524)],
}
LAYER=[
 {'id':'left_witness_rear','z':.175,'color':(139,103,163),'base':.934,'head':(453,350,35,42),'torso':(417,480,75,135)},
 {'id':'left_witness_middle','z':.235,'color':(57,137,171),'base':.980,'head':(532,362,35,43),'torso':(500,475,85,140)},
 {'id':'left_witness_front','z':.303,'color':(97,174,99),'base':1.035,'head':(691,360,38,47),'torso':(671,470,107,137)},
]

def partitions():
    ys=np.arange(H)
    limits=[np.interp(ys,*zip(*DIVISIONS[k])) for k in DIVISIONS]
    xx=np.arange(W)[None,:]
    base=OUTER>127
    masks=[base&(xx<limits[0][:,None]),
           base&(xx>=limits[0][:,None])&(xx<limits[1][:,None]),
           base&(xx>=limits[1][:,None])]
    return [np.uint8(m)*255 for m in masks]

def height_and_normal(info,mask):
    yy,xx=np.mgrid[:H,:W].astype(np.float32)
    inside=mask>0
    distance=cv2.distanceTransform(inside.astype(np.uint8),cv2.DIST_L2,5)
    height=np.float32(info['z']+.012*np.tanh(distance/24))
    for center,amp in [('head',.024),('torso',.014)]:
        cx,cy,rx,ry=info[center]
        height+=np.float32(amp*np.exp(-.5*(((xx-cx)/rx)**2+((yy-cy)/ry)**2)))
    height=cv2.GaussianBlur(height,(0,0),7)
    gx=cv2.Sobel(height,cv2.CV_32F,1,0,ksize=3)/8
    gy=cv2.Sobel(height,cv2.CV_32F,0,1,ksize=3)/8
    normal=np.stack((-gx*175,-gy*175,np.ones_like(gx)),axis=2)
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    return height,normal

def curve_shadow(canvas,name,receiving):
    curve=np.zeros((H,W),np.uint8)
    points=np.array([(x-6,y+7) for y,x in DIVISIONS[name]],np.int32)
    cv2.polylines(curve,[points],False,255,7,cv2.LINE_AA)
    curve=cv2.GaussianBlur(curve,(0,0),5).astype(np.float32)/255
    curve*=receiving.astype(np.float32)
    canvas*=1-(curve*.16)[:,:,None]

def crop2(a):
    x0,y0,x1,y1=CROP
    return Image.fromarray(a[y0:y1,x0:x1]).resize(((x1-x0)*2,(y1-y0)*2))

def render():
    masks=partitions()
    output=SOURCE.astype(np.float32).copy()
    colors=np.zeros_like(SOURCE)
    normals=np.full_like(SOURCE,(128,128,255))
    depth=np.zeros((H,W),np.float32)
    for i,(info,mask) in enumerate(zip(LAYER,masks)):
        inside=mask>0
        if i==1:curve_shadow(output,'rear_middle',masks[0]>0)
        if i==2:curve_shadow(output,'middle_front',masks[1]>0)
        height,normal=height_and_normal(info,mask)
        light=np.array([-.38,-.42,.82],np.float32);light/=np.linalg.norm(light)
        # Narrow matte response leaves photographed pigment in control.
        factor=np.clip(info['base']+(normal@light-light[2])*.39,.88,1.08)
        output[inside]=SOURCE[inside]*factor[inside,None]
        colors[inside]=info['color']
        normals[inside]=np.uint8(np.clip((normal[inside]+1)*127.5,0,255))
        depth[inside]=height[inside]
    return np.uint8(np.clip(output,0,255)),colors,normals,depth,masks

def side45(masks,depth):
    # Triangle strips sample the same local depth function as the front
    # renderer. This exposes the shallow curved witness surfaces in profile.
    x0,y0,x1,y1=CROP
    width=(x1-x0)*2; height=(y1-y0)*2
    canvas=np.full((height+180,width+330,3),30,np.uint8)
    src=cv2.resize(SOURCE[y0:y1,x0:x1],(width,height))
    for layer in [-1,0,1,2]:
        if layer<0:
            alpha=np.ones((height,width),np.uint8)*255
            z=np.zeros((height,width),np.float32)
            color=np.uint8(src.astype(np.float32)*.46)
        else:
            alpha=cv2.resize(masks[layer][y0:y1,x0:x1],(width,height))
            z=cv2.resize(depth[y0:y1,x0:x1],(width,height))
            color=src
        # Forward warp of image strips with depth-aware horizontal offsets.
        # Every 8 px strip has its own X/Z projection (the figure is curved,
        # whereas the previous prototype projected one flat plane per mask).
        for y in range(0,height,8):
            for x in range(0,width,8):
                patch_alpha=alpha[y:y+8,x:x+8]
                if not np.any(patch_alpha):continue
                zz=float(np.mean(z[y:y+8,x:x+8][patch_alpha>0])) if layer>=0 else 0
                dx=int(x*.707+85+zz*410);dy=y+60-int(zz*42)
                ph,pw=patch_alpha.shape
                if dx+pw>=canvas.shape[1] or dy+ph>=canvas.shape[0]:continue
                a=patch_alpha[:,:,None].astype(np.float32)/255
                canvas[dy:dy+ph,dx:dx+pw]=np.uint8(np.clip(
                    canvas[dy:dy+ph,dx:dx+pw]*(1-a)+color[y:y+ph,x:x+pw]*a,0,255))
    return Image.fromarray(canvas)

def main():
    OUT.mkdir(exist_ok=True,parents=True)
    front,colors,normals,depth,masks=render()
    crop2(SOURCE).save(OUT/'figures_original.png')
    crop2(colors).save(OUT/'figures_masks.png')
    crop2(front).save(OUT/'figures_front.png')
    crop2(normals).save(OUT/'figures_normals.png')
    side45(masks,depth).save(OUT/'figures_side45.png')
    for info,m in zip(LAYER,masks):
        Image.fromarray(m).save(OUT/f"{info['id']}_mask.png")
    (OUT/'figure_cluster_manifest.json').write_text(json.dumps({'layers':LAYER,'divisionCurves':DIVISIONS},indent=2))
    print('three painted left witness clusters')

if __name__=='__main__':main()
