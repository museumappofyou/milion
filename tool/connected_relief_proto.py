"""Connected, authored low-poly rock mesh prototype for the left Anastasis ridge."""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'anastasis_25d/v4'
SOURCE=np.asarray(Image.open(ROOT/'assets/anastasis/conch_reference.jpg').convert('RGB'))
H,W=SOURCE.shape[:2]
CROP=(255,135,815,350)

# Shared ridge vertices keep the surface watertight. The coordinate triplets
# are master-photo x/y and artistic positive Z. Faces are deliberately small
# in number and are bounded by visible painted crests and joins.
NODES={
 'a':(470,183,.085),'b':(527,162,.115),'c':(625,203,.145),
 'd':(674,199,.165),'e':(777,226,.183),'f':(793,248,.182),
 'g':(470,218,.095),'h':(527,212,.145),'i':(590,237,.172),
 'j':(625,229,.190),'k':(687,230,.220),'l':(746,244,.235),
 'm':(775,267,.205),'n':(470,262,.070),'o':(510,255,.107),
 'p':(562,264,.130),'q':(609,270,.162),'r':(657,285,.182),
 's':(728,272,.184),'t':(751,279,.186),
}
QUADS=[
 ('a','b','h','g'),('b','c','i','h'),('c','d','k','j'),
 ('d','e','l','k'),('e','f','m','l'),
 ('g','h','o','n'),('h','i','p','o'),('i','j','q','p'),
 ('j','k','r','q'),('k','l','s','r'),('l','m','t','s'),
]
CREASE_EDGES=[('c','i'),('d','k'),('e','l')]
CROWN_EDGES=[('c','d'),('d','e')]


def triangles():
    result=[]
    for a,b,c,d in QUADS:
        result.extend([(a,b,c),(a,c,d)])
    result.append(('c','j','i'))
    return result


def top_mask():
    mountain=np.zeros((H,W),np.uint8)
    for name in ('left_mountain_back','left_mountain_mid','left_mountain_front'):
        mountain=cv2.max(mountain,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{name}_mask.png'),0))
    people=np.zeros((H,W),np.uint8)
    for name in ('left_rear_group','left_mid_group','left_front_group','adam'):
        people=cv2.max(people,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{name}_mask.png'),0))
    return (mountain.astype(np.float32)/255)*(1-people.astype(np.float32)/255)


def face_normal(tri):
    xyz=[]
    for name in tri:
        x,y,z=NODES[name]
        xyz.append((x,y,z*410))
    a,b,c=np.asarray(xyz,np.float32)
    n=np.cross(b-a,c-a)
    if n[2]<0:n=-n
    return n/np.linalg.norm(n)


def facet_normal(index,tri):
    """One lighting normal per painted quadrilateral, not per split triangle.

    The triangles still form the connected mesh, but their shared diagonal is
    a triangulation detail, not a painted ridge. Lighting must not reveal it.
    """
    if index>=2*len(QUADS):
        return face_normal(tri)
    a,b,c,d=QUADS[index//2]
    n1=face_normal((a,b,c));n2=face_normal((a,c,d))
    n=n1+n2
    return n/np.linalg.norm(n)


def light_factor(normal,angle=-35,debug=False):
    a=np.deg2rad(angle)
    light=np.array([np.sin(a)*.58,-np.cos(a)*.58,.82],np.float32)
    light/=np.linalg.norm(light)
    response=1+(normal@light-light[2])*(1.20 if debug else .43)
    return float(np.clip(response,.65 if debug else .88,1.35 if debug else 1.08))


def triangle_mask(tri):
    m=np.zeros((H,W),np.uint8)
    cv2.fillConvexPoly(m,np.array([NODES[n][:2] for n in tri],np.int32),255)
    return m.astype(np.float32)/255*top_mask_cache


def render_front(debug=False,angle=-35):
    img=SOURCE.astype(np.float32).copy()
    toned_all=230+(img-230)*1.18
    img=img*(1-top_mask_cache[:,:,None])+np.clip(toned_all,0,255)*top_mask_cache[:,:,None]
    normals=np.full_like(SOURCE,(128,128,255),np.uint8)
    labels=np.zeros_like(SOURCE)
    depth=np.zeros((H,W),np.float32)
    face_masks=[]
    for index,tri in enumerate(triangles()):
        mask=triangle_mask(tri)
        n=facet_normal(index,tri)
        val=light_factor(n,angle,debug)
        inside=mask>0.5
        # The complete source fresco remains layer zero, including under
        # every triangle and every masked figure.
        # The chosen master is washed out over the rock. A reversible display
        # curve pivots at the pale plaster value; it reveals existing painted
        # contours without drawing a new texture or changing hue.
        source_rgb=SOURCE[inside].astype(np.float32)
        toned=230+(source_rgb-230)*1.18
        img[inside]=np.clip(toned*val,0,255)
        normals[inside]=np.clip((n+1)*127.5,0,255).astype(np.uint8)
        color=np.clip((n+1)*127.5,0,255).astype(np.uint8)
        labels[inside]=color
        pts=np.array([NODES[p] for p in tri],np.float32)
        yy,xx=np.where(inside)
        if len(xx):
            bary=cv2.getAffineTransform(np.ascontiguousarray(pts[:,:2]),np.array([[pts[0,2],0],[pts[1,2],0],[pts[2,2],0]],np.float32))
            depth[yy,xx]=bary[0,0]*xx+bary[0,1]*yy+bary[0,2]
        face_masks.append(mask)
    # Narrow self-occlusion is placed only beneath three visible painted
    # ridge creases. It is a soft form shadow, not a silhouette outline.
    crease=np.zeros((H,W),np.uint8)
    for aa,bb in CREASE_EDGES:
        p1=np.array(NODES[aa][:2],np.int32)+(4,5)
        p2=np.array(NODES[bb][:2],np.int32)+(4,5)
        cv2.line(crease,tuple(p1),tuple(p2),255,8)
    crease=cv2.GaussianBlur(crease,(0,0),5).astype(np.float32)/255
    shadow=crease*top_mask_cache*(.38 if debug else .28)
    # The foremost painted crown casts a wider, soft shadow across the
    # descending face. Only this visible crest receives the longer contact.
    crown=np.zeros((H,W),np.uint8)
    for aa,bb in CROWN_EDGES:
        p1=np.array(NODES[aa][:2],np.int32)+(7,12)
        p2=np.array(NODES[bb][:2],np.int32)+(7,12)
        cv2.line(crown,tuple(p1),tuple(p2),255,15)
    crown=cv2.GaussianBlur(crown,(0,0),8).astype(np.float32)/255
    shadow=np.maximum(shadow,crown*top_mask_cache*(.30 if debug else .22))
    img*=1-shadow[:,:,None]
    return np.clip(img,0,255).astype(np.uint8),normals,labels,depth,face_masks


def crop2(arr):
    x0,y0,x1,y1=CROP
    return Image.fromarray(arr[y0:y1,x0:x1]).resize(((x1-x0)*2,(y1-y0)*2),Image.Resampling.LANCZOS)


def projected(name,depth_px=400,angle=45):
    x0,y0,_,_=CROP
    x,y,z=NODES[name]
    return ((x-x0)*2*np.cos(np.deg2rad(angle))+95+z*depth_px,
            (y-y0)*2+80-z*48)


def render_side(face_masks):
    x0,y0,x1,y1=CROP
    cw,ch=x1-x0,y1-y0
    canvas=np.full((ch*2+190,cw*2+300,3),27,np.uint8)
    source=cv2.resize(SOURCE[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
    base=np.clip(source.astype(np.float32)*.32,0,255).astype(np.uint8)
    co=np.cos(np.deg2rad(45))
    mat=np.float32([[co,0,95],[0,1,80]])
    flat=cv2.warpAffine(base,mat,(canvas.shape[1],canvas.shape[0]))
    bm=cv2.warpAffine(np.ones(base.shape[:2],np.uint8)*255,mat,(canvas.shape[1],canvas.shape[0]))
    canvas[bm>0]=flat[bm>0]
    # Find the actual outside boundary; shared ridge edges receive no walls.
    count=Counter(tuple(sorted((a,b))) for tri in triangles() for a,b in zip(tri,tri[1:]+tri[:1]))
    for (a,b),times in count.items():
        if times!=1:continue
        pa,pb=projected(a),projected(b)
        xa,ya,_=NODES[a];xb,yb,_=NODES[b]
        wall=np.array([((xa-x0)*2*co+95,(ya-y0)*2+80),
                       ((xb-x0)*2*co+95,(yb-y0)*2+80),pb,pa],np.int32)
        cv2.fillConvexPoly(canvas,wall,(75,59,44))
    for index,(tri,mask) in enumerate(zip(triangles(),face_masks)):
        src=np.array([((NODES[n][0]-x0)*2,(NODES[n][1]-y0)*2) for n in tri],np.float32)
        dst=np.array([projected(n) for n in tri],np.float32)
        affine=cv2.getAffineTransform(src,dst)
        tex=np.clip(source.astype(np.float32)*light_factor(facet_normal(index,tri)),0,255).astype(np.uint8)
        warped=cv2.warpAffine(tex,affine,(canvas.shape[1],canvas.shape[0]),flags=cv2.INTER_LINEAR)
        mask_local=cv2.resize(mask[y0:y1,x0:x1],(cw*2,ch*2),interpolation=cv2.INTER_LINEAR)
        alpha=cv2.warpAffine(mask_local,affine,(canvas.shape[1],canvas.shape[0]),flags=cv2.INTER_LINEAR)
        limit=np.zeros(canvas.shape[:2],np.uint8);cv2.fillConvexPoly(limit,dst.round().astype(np.int32),255)
        a=(alpha*(limit.astype(np.float32)/255))[:,:,None]
        canvas=np.clip(canvas*(1-a)+warped*a,0,255).astype(np.uint8)
    return Image.fromarray(canvas)


def main():
    global top_mask_cache
    OUT.mkdir(parents=True,exist_ok=True)
    top_mask_cache=top_mask()
    front,normals,labels,depth,masks=render_front()
    debug,*_=render_front(True)
    crop2(SOURCE).save(OUT/'connected_left_original.png')
    crop2(front).save(OUT/'connected_left_front.png')
    crop2(debug).save(OUT/'connected_left_raking.png')
    crop2(normals).save(OUT/'connected_left_normals.png')
    crop2(labels).save(OUT/'connected_left_geometry.png')
    render_side(masks).save(OUT/'connected_left_side45.png')
    cv2.imwrite(str(OUT/'connected_left_depth.png'),np.clip(depth/.25*255,0,255).astype(np.uint8))
    (OUT/'connected_left_mesh.json').write_text(json.dumps({'vertices':NODES,'triangles':triangles()},indent=2))
    edges=Counter(tuple(sorted((a,b))) for tri in triangles() for a,b in zip(tri,tri[1:]+tri[:1]))
    print('triangles',len(triangles()),'shared edges',sum(v==2 for v in edges.values()),'open boundary',sum(v==1 for v in edges.values()),'bad',sum(v>2 for v in edges.values()))

if __name__=='__main__':main()
