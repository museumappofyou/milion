"""Build the Last Judgment with the Anastasis v5 continuous-surface method.

python3.11 tool/build_last_judgment_v5.py
Requires NumPy, OpenCV and SciPy. SAM is optional: authored masks are committed.
One source pixel per surface point; fixed light; no cutouts or duplicated paint.
"""
import json
from pathlib import Path
import cv2
import numpy as np
from build_anastasis_v5 import (
    relief_profile, shading_maps, shade_mode, height_viz, normal_viz, H_SCALE,
)
from render_anastasis_v5 import side_view, fit, label, hstack

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'last_judgment_25d/v5'
AUTH = OUT / 'authoring'
ASSETS = ROOT / 'assets/last_judgment/relief_v5'
MASTER = 'assets/last_judgment/vault_reference.jpg'


def shape_mask(shape, part, scale):
    mask = np.zeros(shape, np.uint8)
    if part.get('sam'):
        path = AUTH / 'masks' / (part['id'] + '.png')
        mask = cv2.imread(str(path), 0)
        if mask is None or mask.shape != shape:
            raise ValueError(f'Missing or mismatched authored mask: {path}')
    if 'poly' in part:
        cv2.fillPoly(mask, [np.round(np.array(part['poly']) * scale).astype(np.int32)], 255)
    if 'ellipse' in part:
        x,y,rx,ry = np.array(part['ellipse']) * np.tile(scale,2)
        cv2.ellipse(mask, (round(x),round(y)),(round(rx),round(ry)),0,0,360,255,-1)
    if part.get('sam'):
        # Fill pigment-sized holes; pigment variation is not physical geometry.
        from scipy.ndimage import binary_fill_holes
        mask = binary_fill_holes(mask > 127).astype(np.uint8) * 255
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    return mask > 127


def export_mesh(height, color):
    """Connected, vertex-colored inspection mesh, in photograph pixel units."""
    step = 4
    ys = np.unique(np.r_[np.arange(0,height.shape[0],step),height.shape[0]-1])
    xs = np.unique(np.r_[np.arange(0,height.shape[1],step),height.shape[1]-1])
    w,h = len(xs),len(ys)
    with (OUT/'relief_mesh.ply').open('w') as f:
        f.write(f'ply\nformat ascii 1.0\ncomment Authored pictorial relief; not surveyed geometry\nelement vertex {w*h}\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nelement face {(w-1)*(h-1)*2}\nproperty list uchar int vertex_indices\nend_header\n')
        for y in ys:
            for x in xs:
                b,g,r=color[y,x]
                f.write(f'{x} {-y} {height[y,x]:.3f} {r} {g} {b}\n')
        for y in range(h-1):
            for x in range(w-1):
                a=y*w+x;b=a+1;c=a+w;d=c+1
                f.write(f'3 {a} {c} {b}\n3 {b} {c} {d}\n')


def main():
    ASSETS.mkdir(parents=True,exist_ok=True)
    cfg=json.loads((AUTH/'layers.json').read_text())
    img=cv2.imread(str(ROOT/MASTER));h,w=img.shape[:2]
    scale=np.array([w/cfg['grid'][0],h/cfg['grid'][1]])
    height=np.zeros((h,w),np.float32)
    labels=np.zeros((h,w),np.uint16)
    semantic=np.full_like(img,(50,46,46))
    stats=[]
    for i,part in enumerate(cfg['parts'],1):
        mask=shape_mask((h,w),part,scale)
        if mask.sum()<10: raise ValueError(f'Empty part: {part["id"]}')
        heads=[[x*scale[0],y*scale[1],r*scale.mean()] for x,y,r in part.get('heads',[])]
        profile=relief_profile(mask,dict(bevel=2,bevel_r=3.5,body=part['body'],body_r=16,head=2.5),heads,None)
        # Explicit painting order, avoiding automatic elevation of neighboring figures.
        height[mask]=part['z']+profile[mask]
        labels[mask]=i
        semantic[mask]=cfg['colors'][part['kind']][::-1]
        stats.append(dict(id=part['id'],kind=part['kind'],z=part['z'],pixels=int(mask.sum())))
    for loss in cfg['losses']:
        mask=shape_mask((h,w),loss,scale)
        # Keep existing losses shallow and unpainted. Soft transitions avoid a stencil rim.
        mix=cv2.GaussianBlur(mask.astype(np.float32),(0,0),1.2)
        height=height*(1-mix)+loss['z']*mix
        semantic[mask]=(92,109,120)
        labels[mask]=0
    # Keep depths proportional to the 2048 px Anastasis master.
    height *= w / 2048.0
    maps=shading_maps(height);maps['H']=height
    front=shade_mode(img,maps)
    debug=shade_mode(img,maps,'debug')
    for name,im in [('relief_front.jpg',front),('raking_debug.jpg',debug),('height.jpg',height_viz(height)),('normals.jpg',normal_viz(maps['N'])),('semantic_layers.png',semantic)]:
        cv2.imwrite(str(ASSETS/name),im,[] if name.endswith('.png') else [cv2.IMWRITE_JPEG_QUALITY,96])
    cv2.imwrite(str(OUT/'height16.png'),np.round(height*H_SCALE).astype(np.uint16))
    cv2.imwrite(str(OUT/'part_labels.png'),labels)
    cv2.imwrite(str(OUT/'shadow_ao.png'),np.round(maps['shadow']*maps['ao']*255).astype(np.uint8))
    side=side_view(front,height,yaw=45,pitch=14,zscale=1.5,out_scale=.75)
    cv2.imwrite(str(ASSETS/'side45.jpg'),side,[cv2.IMWRITE_JPEG_QUALITY,95])
    cv2.imwrite(str(OUT/'comparison.jpg'),hstack([label(fit(im,width=900),title) for im,title in [(img,'Original'),(front,'Painted relief'),(debug,'Raking light / inspection')]]))
    overlays=cv2.addWeighted(img,.55,semantic,.45,0)
    cv2.imwrite(str(OUT/'semantic_overlay.jpg'),overlays)
    export_mesh(height,front)
    views=[('relief','Relief','relief_front.jpg'),('raking','Raking light','raking_debug.jpg'),('semantic','Semantic layers','semantic_layers.png'),('normals','Normals','normals.jpg'),('depth','Height','height.jpg'),('side','45° surface','side45.jpg')]
    manifest=dict(sceneId='F05',title='The Last Judgment',master=MASTER,size=[w,h],
        generator='tool/build_last_judgment_v5.py',camera='centered orthographic; no animation or parallax',
        method='one continuous authored height field, following Anastasis v5',
        lighting=dict(direction=[-.45,-.60,.66],reliefLightClamp=[.88,1.08],formula='originalRGB * reliefLight * contactShadow * occlusion'),
        parts=stats,views=[dict(id=id,label=title,file=f'assets/last_judgment/relief_v5/{name}') for id,title,name in views],
        focus=[dict(label=title,rect=None if rect is None else list(np.round(np.array(rect)*np.tile(scale,2),2))) for title,rect in [('Overview',[230,0,1290,1000]),('Whole vault',None),('Deesis',[290,490,1240,760]),('Christ',[603,540,902,766]),('Heavens',[307,0,1230,531]),('Throne',[590,756,952,1000])]],
        sourceCredit='Caner Cangül · supplied reference photographs',
        limitations=['Interpretive pictorial depth, not measured architecture.','Original plaster losses retained; no reconstructed faces or missing paint.','Fixed baked illumination; side view uses 1.5× depth for inspection.','Masks approximate some robe edges and overlapping court figures.'])
    (ASSETS/'manifest.json').write_text(json.dumps(manifest,indent=2))
    ratio=front.sum(2)/(img.sum(2)+1e-6)
    report=dict(size=[w,h],parts=len(stats),heightRange=[float(height.min()),float(height.max())],changedFraction=float((np.abs(front.astype(float)-img).mean(2)>3).mean()),lightRatioPercentiles=np.percentile(ratio,[5,50,95,99]).tolist())
    (OUT/'build_report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

if __name__=='__main__': main()
