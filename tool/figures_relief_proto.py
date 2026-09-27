"""Three overlapping left witnesses: conservative masks and shallow body relief."""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'anastasis_25d/v4'
SOURCE=np.asarray(Image.open(ROOT/'assets/anastasis/conch_reference.jpg').convert('RGB'))
REFERENCE=np.asarray(Image.open(ROOT/'anastasis_25d/v4/left_webke_local_aligned.jpg').convert('RGB'))
H,W=SOURCE.shape[:2]
CROP=(335,290,815,635)

# The contours select three compositional witnesses, not individual anatomy.
# Uncertain boundaries stay inside the painted figure rather than taking
# adjacent fresco material. Positive Z approaches the viewer.
FIGURES=[
 dict(id='rear_witness',z=.190,color=(119,96,157),light=.88,
     head=(451,355,29,35),torso=(415,451,48,73),polygon=[
     (426,332),(450,324),(476,339),(485,368),(470,395),
     (453,415),(462,463),(437,509),(398,534),(371,500),
     (374,447),(394,401)]),
 dict(id='middle_witness',z=.242,color=(65,129,166),light=.965,
     head=(533,359,30,35),torso=(522,454,54,80),polygon=[
     (507,338),(532,330),(556,342),(568,369),(555,395),
     (584,416),(592,455),(572,494),(544,529),(496,535),
     (461,490),(457,442),(480,404)]),
 dict(id='front_witness',z=.296,color=(107,166,113),light=1.075,
     head=(694,360,33,38),torso=(687,457,66,86),polygon=[
     (670,333),(696,327),(720,342),(730,371),(715,397),
     (745,415),(762,467),(752,505),(716,527),(655,527),
     (616,487),(620,431),(645,400)]),
]


def mask(points):
    m=np.zeros((H,W),np.uint8)
    cv2.fillPoly(m,[np.array(points,np.int32)],255)
    return m


def refine_mask(points):
    outer=mask(points)
    support=cv2.dilate(outer,np.ones((19,19),np.uint8))
    core=cv2.erode(outer,np.ones((35,35),np.uint8))
    labels=np.zeros((H,W),np.uint8)
    labels[support>0]=cv2.GC_PR_BGD
    labels[outer>0]=cv2.GC_PR_FGD
    labels[core>0]=cv2.GC_FGD
    bg=np.zeros((1,65),np.float64);fg=np.zeros((1,65),np.float64)
    guide=SOURCE.copy()
    guide[130:700,200:850]=REFERENCE
    cv2.grabCut(cv2.cvtColor(guide,cv2.COLOR_RGB2BGR),labels,None,bg,fg,5,cv2.GC_INIT_WITH_MASK)
    selected=np.where((labels==cv2.GC_FGD)|(labels==cv2.GC_PR_FGD),255,0).astype(np.uint8)
    # GrabCut can move the outline both inward and outward. The former
    # implementation clipped it back to the coarse guide polygon, leaving
    # visibly geometric cuts through painted robes and halos.
    components,counted,stats,_=cv2.connectedComponentsWithStats(selected,8)
    if components<=1:
        return outer
    scores=[]
    for label in range(1,components):
        scores.append((np.count_nonzero((counted==label)&(core>0)),stats[label,cv2.CC_STAT_AREA],label))
    chosen=max(scores)[2]
    selected=np.where(counted==chosen,255,0).astype(np.uint8)
    selected=cv2.morphologyEx(selected,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))
    return selected


def crop2(arr):
    x0,y0,x1,y1=CROP
    return Image.fromarray(arr[y0:y1,x0:x1]).resize(((x1-x0)*2,(y1-y0)*2),Image.Resampling.LANCZOS)


def render():
    source=SOURCE.astype(np.float32)
    result=source.copy()
    colors=np.zeros_like(SOURCE)
    normal_view=np.full_like(SOURCE,(128,128,255))
    masks=[]
    heights=[]
    for i,figure in enumerate(FIGURES):
        m=refine_mask(figure['polygon'])
        masks.append(m)
        inside=m>127
        # A short displaced silhouette shadow is visible even in a stationary
        # phone frame. It lands on the complete fresco backing, then the
        # opaque foreground pixels cover the original painted counterpart.
        # The subtraction keeps the shadow outside the object rather than
        # darkening its own perimeter like an outline.
        contact=cv2.warpAffine(m,np.float32([[1,0,7],[0,1,9]]),(W,H))
        contact=cv2.GaussianBlur(contact,(0,0),4).astype(np.float32)/255
        contact*=1-inside.astype(np.float32)
        result*=1-(contact*.22)[:,:,None]
        # A very shallow silhouette dome changes normals without following
        # brush marks, pigment cracks or invented face detail.
        distance=cv2.distanceTransform(inside.astype(np.uint8),cv2.DIST_L2,5)
        height=.45+.08*np.tanh(distance/35)
        yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
        hx,hy,hw,hh=figure['head'];tx,ty,tw,th=figure['torso']
        height+=.095*np.exp(-.5*(((xx-hx)/hw)**2+((yy-hy)/hh)**2))
        height+=.045*np.exp(-.5*(((xx-tx)/tw)**2+((yy-ty)/th)**2))
        height=cv2.GaussianBlur(height.astype(np.float32),(0,0),5)
        heights.append(height)
        gx=cv2.Sobel(height,cv2.CV_32F,1,0,ksize=3)/8
        gy=cv2.Sobel(height,cv2.CV_32F,0,1,ksize=3)/8
        n=np.stack((-gx*185,-gy*185,np.ones_like(gx)),axis=2)
        n/=np.linalg.norm(n,axis=2,keepdims=True)
        # Upper-left museum light, limited to a narrow matte response.
        light=np.array([-.34,-.40,.85],np.float32)
        light/=np.linalg.norm(light)
        response=np.clip(figure['light']+(n@light-light[2])*.25,.88,1.08)
        result[inside]=np.clip(source[inside]*response[inside,None],0,255)
        colors[inside]=figure['color']
        normal_view[inside]=np.clip((n[inside]+1)*127.5,0,255).astype(np.uint8)
    return np.clip(result,0,255).astype(np.uint8),colors,normal_view,masks,heights


def side45(masks):
    x0,y0,x1,y1=CROP;cw=x1-x0;ch=y1-y0
    canvas=np.full((ch*2+130,cw*2+220,3),27,np.uint8)
    source=cv2.resize(SOURCE[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
    base=cv2.warpAffine((source*.38).astype(np.uint8),np.float32([[.707,0,60],[0,1,50]]),(canvas.shape[1],canvas.shape[0]))
    bm=cv2.warpAffine(np.ones((ch*2,cw*2),np.uint8)*255,np.float32([[.707,0,60],[0,1,50]]),(canvas.shape[1],canvas.shape[0]))
    canvas[bm>0]=base[bm>0]
    for figure,m in zip(FIGURES,masks):
        z=figure['z'];shift=z*330
        affine=np.float32([[.707,0,60+shift],[0,1,50-z*26]])
        tex=np.clip(source.astype(np.float32)*figure['light'],0,255).astype(np.uint8)
        projected=cv2.warpAffine(tex,affine,(canvas.shape[1],canvas.shape[0]))
        alpha=cv2.warpAffine(cv2.resize(m[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR),affine,(canvas.shape[1],canvas.shape[0]))/255
        a=alpha[:,:,None]
        canvas=np.clip(canvas*(1-a)+projected*a,0,255).astype(np.uint8)
    return Image.fromarray(canvas)


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    front,colors,normals,masks,heights=render()
    crop2(SOURCE).save(OUT/'figures_original.png')
    crop2(colors).save(OUT/'figures_masks.png')
    crop2(front).save(OUT/'figures_front.png')
    crop2(normals).save(OUT/'figures_normals.png')
    for figure,m in zip(FIGURES,masks):
        Image.fromarray(m).save(OUT/f"{figure['id']}_mask.png")
    side45(masks).save(OUT/'figures_side45.png')
    (OUT/'figures_manifest.json').write_text(json.dumps(FIGURES,indent=2))
    print('three separate witnesses')

if __name__=='__main__':main()
