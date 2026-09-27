"""Authored Anastasis rock-facet prototype; source RGB is always the texture.

Usage: python3.11 tool/build_anastasis_v4_rock.py
Run from the repository root with Python 3.11. This first focuses only on
the exposed upper-left painted rock. Facet points are master-photo pixels.
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'studio/anastasis_25d/v4'
ASSETS = ROOT / 'assets/anastasis/relief_v4'
SOURCE = np.asarray(Image.open(ROOT / 'assets/anastasis/conch_reference.jpg').convert('RGB'))
H, W = SOURCE.shape[:2]
LEFT_CROP = (255, 135, 815, 350)

# A separate 3D plane corresponds to each visibly painted rock facet. The
# angles are art-direction choices, not inferred from pigment brightness.
# Base Z is artistic relief depth, positive toward the viewer. All polygons
# use source-photo pixel coordinates and retain source RGB through UVs.
LEFT_FACETS = [
    dict(id='left_back_ridge',band='back',z=.080,slope=[-.24,.10],color='#777e99',
         polygon=[(282,175),(354,150),(449,183),(470,208),(422,208),(354,202)]),
    dict(id='left_rear_slope',band='back',z=.085,slope=[-.15,.25],color='#8995a3',
         polygon=[(470,183),(527,162),(581,194),(545,212),(505,205),(470,208)]),
    dict(id='left_peak_flank',band='mid',z=.125,slope=[.35,-.10],color='#ac9674',
         polygon=[(527,162),(625,203),(590,238),(545,212),(581,194)]),
    dict(id='left_lower_plane',band='mid',z=.134,slope=[-.20,-.27],color='#c3a86c',
         polygon=[(505,205),(545,212),(590,238),(562,264),(510,255)]),
    dict(id='left_front_crest',band='front',z=.205,slope=[-.41,-.12],color='#e8ca77',
         polygon=[(625,203),(674,199),(777,226),(746,244),(687,230)]),
    dict(id='left_front_face',band='front',z=.184,slope=[.27,.32],color='#d3b568',
         polygon=[(590,238),(625,203),(687,230),(746,244),(728,272),(657,285),(609,270)]),
    dict(id='left_tip',band='front',z=.220,slope=[-.28,.25],color='#ead07f',
         polygon=[(746,244),(777,226),(793,248),(775,267)]),
]


def mask_for(points):
    mask = np.zeros((H,W),np.uint8)
    cv2.fillPoly(mask,[np.array(points,np.int32)],255)
    return mask


def normal_for(facet):
    sx,sy = facet['slope']
    n = np.array([-sx,-sy,1.0],np.float32)
    return n / np.linalg.norm(n)


def vertex_z(facet,point):
    pts=np.asarray(facet['polygon'],np.float32)
    cx,cy=pts.mean(axis=0)
    sx,sy=facet['slope']
    x,y=point
    return facet['z']+(x-cx)*sx*.00040+(y-cy)*sy*.00040


def fonts(size):
    path=Path('/System/Library/Fonts/Supplemental/Arial.ttf')
    return ImageFont.truetype(path,size) if path.exists() else ImageFont.load_default()


def lighting(normal,angle=-35,debug=False):
    a=np.deg2rad(angle)
    light=np.array([np.sin(a)*.58,-np.cos(a)*.58,.82],np.float32)
    light/=np.linalg.norm(light)
    flat=float(light[2]);dot=float(normal@light)
    power=1.40 if debug else .50
    lo,hi=(.65,1.35) if debug else (.88,1.08)
    return float(np.clip(1+(dot-flat)*power,lo,hi))


def source_window(array):
    x0,y0,x1,y1=LEFT_CROP
    return Image.fromarray(array[y0:y1,x0:x1]).resize(((x1-x0)*2,(y1-y0)*2),Image.Resampling.LANCZOS)


def paint_front(angle=-35,debug=False):
    img=SOURCE.astype(np.float32).copy()
    normal_view=np.full_like(SOURCE,(128,128,255))
    depth=np.zeros((H,W),np.float32)
    semantic=np.zeros((H,W,3),np.uint8)
    mountain=cv2.imread(str(ROOT/'assets/anastasis/relief_v3/left_mountain_back_mask.png'),0)
    for suffix in ('mid','front'):
        mountain=cv2.max(mountain,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/left_mountain_{suffix}_mask.png'),0))
    people=np.zeros((H,W),np.uint8)
    for name in ('left_rear_group','left_mid_group','left_front_group','adam'):
        people=cv2.max(people,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{name}_mask.png'),0))
    # These are only the exposed original painted rock pixels. The complete
    # source photo remains underneath, including at every facet join.
    support=np.minimum(mountain,255-people).astype(np.float32)/255
    facet_masks={}
    lower_visible=np.zeros((H,W),np.float32)
    for facet in LEFT_FACETS:
        m=mask_for(facet['polygon']).astype(np.float32)/255*support
        facet_masks[facet['id']]=m
        n=normal_for(facet)
        mult=lighting(n,angle,debug)
        x0,y0,x1,y1=LEFT_CROP
        if facet['band'] != 'back':
            # A light-source-consistent shadow falls only onto previously
            # authored lower rock, never around the outside of the mountain.
            moved=cv2.warpAffine(m,np.float32([[1,0,3],[0,1,4]]),(W,H))
            fringe=np.clip(cv2.GaussianBlur(moved,(0,0),7)-m,0,1)
            receiver=cv2.dilate(lower_visible,np.ones((9,9),np.uint8))
            shadow=fringe*receiver*(.42 if debug else .34)
            img[y0:y1,x0:x1]*=(1-shadow[y0:y1,x0:x1,None])
        a=m[y0:y1,x0:x1,None]
        img[y0:y1,x0:x1]=img[y0:y1,x0:x1]*(1-a)+np.clip(SOURCE[y0:y1,x0:x1].astype(np.float32)*mult,0,255)*a
        visible=m>0.5
        normal_view[visible]=np.clip((n+1)*127.5,0,255).astype(np.uint8)
        col=facet['color']
        semantic[visible]=[int(col[j:j+2],16) for j in (1,3,5)]
        ys,xs=np.where(visible)
        if len(xs):
            pts=np.asarray(facet['polygon'],np.float32);cx,cy=pts.mean(axis=0);sx,sy=facet['slope']
            depth[ys,xs]=facet['z']+(xs-cx)*sx*.00040+(ys-cy)*sy*.00040
        lower_visible=np.maximum(lower_visible,m)
    return np.clip(img,0,255).astype(np.uint8),normal_view,depth,semantic,facet_masks


def draw_side(facet_masks,angle=45):
    x0,y0,x1,y1=LEFT_CROP
    cw,ch=x1-x0,y1-y0
    canvas=np.full((ch*2+190,cw*2+300,3),27,np.uint8)
    cos=np.cos(np.deg2rad(angle));depth_px=360
    # Source projection is the complete base fresco. Each facet lies in front
    # of it and its UV stays tied to the same photo pixels.
    base=cv2.resize(SOURCE[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
    base=np.clip(base.astype(np.float32)*.34,0,255).astype(np.uint8)
    base_warp=np.float32([[cos,0,85],[0,1,80]])
    base_out=cv2.warpAffine(base,base_warp,(canvas.shape[1],canvas.shape[0]),flags=cv2.INTER_LINEAR)
    base_mask=cv2.warpAffine(np.ones((ch*2,cw*2),np.uint8)*255,base_warp,(canvas.shape[1],canvas.shape[0]))
    canvas[base_mask>0]=base_out[base_mask>0]
    for facet in LEFT_FACETS:
        points=facet['polygon'];fullmask=facet_masks[facet['id']]
        shade=lighting(normal_for(facet))
        # Developer-only plaster side walls expose the true facet depth.
        # They do not add unseen RGB to the frontal painting.
        for a,b in zip(points,points[1:]+points[:1]):
            if a[0] < x0 or b[0] > x1: continue
            za,zb=vertex_z(facet,a),vertex_z(facet,b)
            wall=np.array([
                ((a[0]-x0)*2*cos+85,(a[1]-y0)*2+80),
                ((b[0]-x0)*2*cos+85,(b[1]-y0)*2+80),
                ((b[0]-x0)*2*cos+85+zb*depth_px,(b[1]-y0)*2+80-zb*38),
                ((a[0]-x0)*2*cos+85+za*depth_px,(a[1]-y0)*2+80-za*38),
            ],np.int32)
            cv2.fillConvexPoly(canvas,wall,(74,58,42))
        for i in range(1,len(points)-1):
            tri=np.array([points[0],points[i],points[i+1]],np.float32)
            src=np.array([[(x-x0)*2,(y-y0)*2] for x,y in tri],np.float32)
            dst=np.array([[(x-x0)*2*cos+85+vertex_z(facet,(x,y))*depth_px,(y-y0)*2+80-vertex_z(facet,(x,y))*38] for x,y in tri],np.float32)
            mat=cv2.getAffineTransform(src,dst)
            original=cv2.resize(SOURCE[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
            tex=np.clip(original.astype(np.float32)*shade,0,255).astype(np.uint8)
            warped=cv2.warpAffine(tex,mat,(canvas.shape[1],canvas.shape[0]),flags=cv2.INTER_LINEAR)
            mask=cv2.resize(fullmask[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
            alpha=cv2.warpAffine(mask,mat,(canvas.shape[1],canvas.shape[0]),flags=cv2.INTER_LINEAR)
            triangle=np.zeros(canvas.shape[:2],np.uint8);cv2.fillConvexPoly(triangle,dst.round().astype(np.int32),255)
            a=(alpha*(triangle.astype(np.float32)/255))[:,:,None]
            canvas=np.clip(canvas*(1-a)+warped*a,0,255).astype(np.uint8)
    return Image.fromarray(canvas)


def main():
    OUT.mkdir(parents=True,exist_ok=True);ASSETS.mkdir(parents=True,exist_ok=True)
    front,normals,depth,semantic,masks=paint_front()
    debug,*_=paint_front(debug=True)
    source_window(SOURCE).save(OUT/'left_rock_original.png')
    source_window(front).save(OUT/'left_rock_front.png')
    source_window(debug).save(OUT/'left_rock_raking_light.png')
    source_window(normals).save(OUT/'left_rock_normals.png')
    source_window(semantic).save(OUT/'left_rock_geometry.png')
    draw_side(masks).save(OUT/'left_rock_side45.png')
    cv2.imwrite(str(OUT/'left_rock_depth.png'),np.clip(depth/.25*255,0,255).astype(np.uint8))
    (OUT/'left_facets.json').write_text(json.dumps(LEFT_FACETS,indent=2))
    print('Built',len(LEFT_FACETS),'authored left rock facets')


if __name__=='__main__': main()
