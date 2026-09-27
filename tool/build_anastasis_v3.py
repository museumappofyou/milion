"""Third-pass manually authored painted relief in 2048x1091 master pixels.

Usage: python3.11 tool/build_anastasis_v3.py
"""
from __future__ import annotations
import argparse, json, shutil
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/anastasis/conch_reference.jpg'
OLD=ROOT/'assets/anastasis/relief'
OUT=ROOT/'assets/anastasis/relief_v3'
DOC=ROOT/'studio/anastasis_25d/v3'
W,H=2048,1091

# Only visible painted rock bands receive relief. Slopes and joins follow the
# fresco's planes rather than bright pigment or an automatic depth estimator.
POLYGONS={
 'left_mountain_back': [[(172,360),(216,296),(281,170),(361,150),(448,183),(527,162),(582,196),(675,199),(776,224),(795,267),(733,296),(675,319),(592,318),(525,302),(448,292),(375,315),(299,353)]],
 'left_mountain_mid': [[(279,173),(360,150),(448,184),(519,165),(586,195),(625,236),(590,266),(530,264),(475,245),(431,257),(382,245),(326,263)]],
 'left_mountain_front': [[(494,213),(559,193),(624,205),(675,201),(776,226),(794,264),(748,286),(704,280),(675,304),(624,290),(581,303),(543,276),(508,271)]],
 'right_mountain_back': [[(1172,250),(1229,184),(1352,151),(1390,180),(1496,162),(1595,182),(1669,218),(1645,280),(1575,306),(1495,304),(1428,290),(1359,319),(1288,338),(1195,322)]],
 'right_mountain_mid': [[(1280,205),(1351,151),(1391,180),(1494,162),(1591,184),(1574,241),(1520,270),(1462,253),(1422,286),(1368,273),(1309,302),(1264,272)]],
 'right_mountain_front': [[(1173,250),(1212,202),(1282,193),(1351,209),(1374,243),(1335,268),(1307,291),(1254,306),(1190,321),(1169,291)]],
 'left_rear_group': [[(291,297),(309,260),(337,232),(361,239),(374,209),(400,195),(430,190),(460,210),(479,225),(496,218),(519,242),(533,273),(519,298),(485,313),(447,307),(419,335),(391,333),(356,314),(325,329)]],
 'left_mid_group': [[(50,454),(76,402),(104,356),(137,316),(172,281),(207,266),(243,253),(268,243),(289,253),(315,282),(342,313),(365,344),(381,380),(366,414),(393,448),(425,482),(414,530),(388,563),(350,602),(302,638),(261,647),(223,617),(179,604),(134,564),(88,533),(61,489)]],
 'left_front_group': [
  [(341,378),(378,329),(412,300),(448,296),(480,315),(507,343),(538,346),(561,379),(552,429),(568,461),(562,525),(541,584),(509,637),(479,669),(437,681),(395,651),(370,612),(342,571),(317,546),(324,492)],
  [(539,433),(565,368),(607,328),(638,312),(673,302),(703,315),(725,346),(724,393),(745,440),(779,475),(768,518),(732,552),(682,558),(650,583),(606,560),(582,514)]],
 'right_rear_group': [[(1359,353),(1383,310),(1419,274),(1450,261),(1478,237),(1512,221),(1545,214),(1580,229),(1610,255),(1612,293),(1590,329),(1566,344),(1538,368),(1497,375),(1458,382),(1415,380),(1381,395)]],
 'right_mid_group': [[(1300,382),(1323,343),(1351,325),(1380,330),(1413,346),(1441,373),(1478,356),(1506,345),(1541,359),(1570,385),(1597,416),(1624,452),(1618,495),(1635,527),(1608,571),(1581,603),(1535,644),(1513,690),(1482,691),(1451,650),(1407,616),(1385,567),(1352,537),(1330,487)]],
 'right_front_group': [
  [(1490,346),(1515,304),(1543,281),(1584,276),(1621,292),(1651,333),(1674,376),(1708,396),(1733,427),(1761,479),(1801,510),(1814,553),(1795,591),(1756,619),(1710,644),(1654,649),(1610,630),(1576,595),(1544,551),(1518,501)],
  [(1572,266),(1604,233),(1639,216),(1696,213),(1743,232),(1792,249),(1845,290),(1885,332),(1913,374),(1943,420),(1930,470),(1905,514),(1873,541),(1836,548),(1795,522),(1744,482),(1703,432),(1664,389),(1630,341),(1596,314)]],
 'adam': [[(361,757),(383,733),(418,697),(457,663),(496,636),(537,617),(579,603),(609,585),(639,576),(666,584),(692,604),(724,605),(748,594),(785,588),(832,587),(856,598),(854,613),(827,617),(793,617),(757,627),(731,641),(718,670),(696,702),(666,734),(628,764),(581,794),(537,819),(491,836),(451,837),(408,823),(376,799)]],
}

# Z is artistic relief depth, positive toward the viewer. The last pair is the
# clean in-plane slope; no color/luminance enters mountain geometry.
ORDER=[
 ('left_mountain_back',.075,.018,'#777e99',(-.16,.10)),
 ('right_mountain_back',.077,.018,'#777e99',(.15,.08)),
 ('left_mountain_mid',.112,.018,'#bea568',(.11,.20)),
 ('right_mountain_mid',.114,.018,'#b6a275',(-.12,.20)),
 ('left_mountain_front',.153,.020,'#e2ca77',(-.19,.16)),
 ('right_mountain_front',.155,.020,'#e0c280',(.21,.17)),
 ('left_rear_group',.190,.006,'#766998',(0,0)),
 ('right_rear_group',.192,.006,'#8b6b93',(0,0)),
 ('left_mid_group',.232,.008,'#537d9e',(0,0)),
 ('right_mid_group',.234,.008,'#5e9e91',(0,0)),
 ('tomb_left',.240,.003,'#766d5d',(0,0)),
 ('tomb_right',.241,.003,'#766d5d',(0,0)),
 ('lower_gates',.245,.003,'#4f5763',(0,0)),
 ('left_front_group',.280,.010,'#b86e67',(0,0)),
 ('right_front_group',.282,.010,'#bb805a',(0,0)),
 ('mandorla',.308,.004,'#c8b893',(0,0)),
 ('adam',.352,.013,'#527ec5',(0,0)),
 ('eve',.354,.013,'#4da668',(0,0)),
 ('christ',.438,.018,'#c9474b',(0,0))]
FOCAL={'christ','eve','mandorla','tomb_left','tomb_right','lower_gates'}
MOUNTAINS={row[0] for row in ORDER if 'mountain' in row[0]}
GROUPS={name for name, *_ in ORDER if name.endswith('_group')}

def polygon_mask(polys):
    big=np.zeros((H*2,W*2),np.uint8)
    for pts in polys: cv2.fillPoly(big,[np.asarray(pts,np.int32)*2],255)
    return cv2.GaussianBlur(cv2.resize(big,(W,H),interpolation=cv2.INTER_AREA),(0,0),.85)

def get_mask(name,bgr):
    if name in FOCAL: return cv2.imread(str(OLD/f'{name}_mask.png'),0)
    mask=polygon_mask(POLYGONS[name])
    if name in MOUNTAINS:
        source='mountain_left' if name.startswith('left') else 'mountain_right'
        mask=cv2.min(mask,cv2.imread(str(OLD/f'{source}_mask.png'),0))
    elif name in GROUPS:
        # Narrow GrabCut only adjusts the hand-drawn outline. The polygon is
        # still a strict outer limit, preventing invented painted silhouettes.
        outer=(mask>127).astype(np.uint8)
        support=cv2.dilate(outer,np.ones((21,21),np.uint8))
        core=cv2.erode(outer,np.ones((41,41),np.uint8))
        labels=np.zeros((H,W),np.uint8)
        labels[support>0]=cv2.GC_PR_BGD
        labels[outer>0]=cv2.GC_PR_FGD
        labels[core>0]=cv2.GC_FGD
        bg=np.zeros((1,65),np.float64);fg=np.zeros((1,65),np.float64)
        cv2.grabCut(bgr,labels,None,bg,fg,4,cv2.GC_INIT_WITH_MASK)
        selected=np.where((labels==cv2.GC_FGD)|(labels==cv2.GC_PR_FGD),255,0).astype(np.uint8)
        mask=cv2.min(mask,cv2.GaussianBlur(selected,(0,0),.8))
    return mask

def build_masks():
    OUT.mkdir(parents=True,exist_ok=True);DOC.mkdir(parents=True,exist_ok=True)
    rgb=np.asarray(Image.open(SOURCE).convert('RGB'))
    bgr=cv2.cvtColor(rgb,cv2.COLOR_RGB2BGR)
    review=np.zeros_like(rgb);labels=np.zeros((H,W),np.uint8);layers=[]
    for i,(name,depth,relief,color,slope) in enumerate(ORDER):
        mask=get_mask(name,bgr)
        cv2.imwrite(str(OUT/f'{name}_mask.png'),mask)
        ys,xs=np.where(mask>1)
        assert len(xs)>1000,(name,len(xs))
        x0=max(0,int(xs.min())-18);x1=min(W,int(xs.max())+19)
        y0=max(0,int(ys.min())-18);y1=min(H,int(ys.max())+19)
        crop=[x0,y0,x1-x0,y1-y0]
        base=f'assets/anastasis/relief_v3/{name}'
        layer=dict(id=name,depth=depth,reliefStrength=relief,priority=i,color=color,
          kind='mountain' if name in MOUNTAINS else 'figure',slope=list(slope),crop=crop,
          mask=base+'_mask.png',texture=base+'.png',height=base+'_height.png',
          normal=base+'_normal.png',edge=base+'_edge.png',litTexture=base+'_lit.png',
          ao=base+'_ao.png',aoOverlay=base+'_ao_overlay.png',
          heightViz=base+'_height_viz.png',combinedViz=base+'_combined_viz.png',
          contactShadow=base+'_shadow.png')
        layers.append(layer)
        review[mask>127]=tuple(int(color[k:k+2],16) for k in (1,3,5))
        labels[mask>127]=i+1
    Image.fromarray(review).save(DOC/'02_segmentation_masks_full.png')
    Image.fromarray(labels).save(DOC/'segmentation_labels.png')
    manifest=dict(master='assets/anastasis/conch_reference.jpg',size=[W,H],
      coordinateConvention='master pixels from upper left; positive depth toward viewer',
      physicalVersion=3,layers=layers)
    (DOC/'mask_review_manifest.json').write_text(json.dumps(manifest,indent=2))
    return layers,rgb

# A shadow is allowed only where a named surface overlaps a known surface
# behind it. This avoids an outline around every sprite.
BEHIND={
 'left_mountain_mid':['left_mountain_back'],
 'right_mountain_mid':['right_mountain_back'],
 'left_mountain_front':['left_mountain_mid','left_mountain_back'],
 'right_mountain_front':['right_mountain_mid','right_mountain_back'],
 'left_rear_group':['left_mountain_back','left_mountain_mid'],
 'right_rear_group':['right_mountain_back','right_mountain_mid'],
 'left_mid_group':['left_rear_group'],
 'right_mid_group':['right_rear_group'],
 'left_front_group':['left_mid_group','left_rear_group'],
 'right_front_group':['right_mid_group','right_rear_group'],
 'adam':['left_front_group','left_mid_group','tomb_left'],
 'eve':['right_front_group','right_mid_group','tomb_right'],
 'christ':['mandorla','adam','eve'],
}

def local_height(mask,crop,layer,lower_support):
    x,y,w,h=crop
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    if layer['kind']=='mountain':
        sx,sy=layer['slope']
        # One coherent painted plane per semantic rock layer. The three Z
        # levels carry the large relief; this field carries only local tilt.
        raw=.5+sx*((xx-w/2)/max(1,w/2))+sy*((yy-h/2)/max(1,h/2))
        raw=cv2.GaussianBlur(raw,(0,0),1.4)
        normal_scale=520.
    elif layer['id'] in {'christ','adam','eve','left_front_group','right_front_group'}:
        distance=cv2.distanceTransform((mask>127).astype(np.uint8),cv2.DIST_L2,5)
        raw=.42+.12*np.tanh(distance/52)
        raw=cv2.GaussianBlur(raw.astype(np.float32),(0,0),7)
        normal_scale=110.
    else:
        raw=np.full((h,w),.5,np.float32)
        normal_scale=0.
    # Only a boundary resting on a named lower surface gets a tiny inward
    # bevel. This is an actual local Z transition; no RGB edge is sampled.
    if layer['id'] in BEHIND:
        edge_distance=cv2.distanceTransform((mask>127).astype(np.uint8),cv2.DIST_L2,5)
        support=cv2.dilate(lower_support,np.ones((17,17),np.uint8)).astype(np.float32)/255
        edge=np.exp(-edge_distance/11.0)*support*(mask>127)
        raw=raw-edge*(.045 if layer['kind']=='mountain' else .018)
    raw=np.clip(raw,.12,.88).astype(np.float32)
    gx=cv2.Sobel(raw,cv2.CV_32F,1,0,ksize=3)/8
    gy=cv2.Sobel(raw,cv2.CV_32F,0,1,ksize=3)/8
    nx=-gx*normal_scale;ny=-gy*normal_scale;nz=np.ones_like(nx)
    norm=np.sqrt(nx*nx+ny*ny+nz*nz)
    normal=np.stack((nx/norm,ny/norm,nz/norm),axis=2)
    return raw,normal

def build_geometry(layers,rgb):
    masks={layer['id']:cv2.imread(str(ROOT/layer['mask']),0) for layer in layers}
    semantic=np.zeros((H,W),np.float32)
    combined=np.zeros((H,W),np.float32)
    normal_view=np.full((H,W,3),(128,128,255),np.uint8)
    debug_heights={}
    for layer in layers:
        name=layer['id'];x,y,w,h=layer['crop']
        mask=masks[name][y:y+h,x:x+w]
        alpha=mask.astype(np.float32)/255
        source=rgb[y:y+h,x:x+w]
        lower=np.zeros((H,W),np.uint8)
        for other in BEHIND.get(name,[]): lower=cv2.max(lower,masks[other])
        height,normal=local_height(mask,(x,y,w,h),layer,lower[y:y+h,x:x+w])
        encoded=np.clip((normal+1)*127.5,0,255).astype(np.uint8)
        prefix=OUT/name
        # Source and lit texture use identical photograph pixels. The 1.015
        # headroom enables the Flutter vertex shader to darken and gently
        # brighten a slope while keeping final RGB near its source.
        original=np.dstack((source,mask))
        lit=np.dstack((np.clip(source.astype(np.float32)*1.015,0,255).astype(np.uint8),mask))
        Image.fromarray(original).save(str(prefix)+'.png',optimize=True)
        Image.fromarray(lit).save(str(prefix)+'_lit.png',optimize=True)
        Image.fromarray(np.dstack((encoded,mask))).save(str(prefix)+'_normal.png',optimize=True)
        depth_gray=np.clip(height*255,0,255).astype(np.uint8)
        cv2.imwrite(str(prefix)+'_height.png',depth_gray)
        Image.fromarray(np.dstack((depth_gray,depth_gray,depth_gray,mask))).save(str(prefix)+'_height_viz.png',optimize=True)
        scaled=np.clip((layer['depth']+height*layer['reliefStrength'])/.48*255,0,255).astype(np.uint8)
        Image.fromarray(np.dstack((scaled,scaled,scaled,mask))).save(str(prefix)+'_combined_viz.png',optimize=True)
        boundary=cv2.morphologyEx(mask,cv2.MORPH_GRADIENT,np.ones((3,3),np.uint8))
        edge=np.zeros((h,w,4),np.uint8);edge[:,:,:3]=(255,56,40);edge[:,:,3]=boundary
        Image.fromarray(edge).save(str(prefix)+'_edge.png',optimize=True)
        # Broad plane fields have no pigment-driven AO. Only a shallow figure
        # dome can create a small local valley; inter-layer occlusion is below.
        valley=np.maximum(cv2.GaussianBlur(height,(0,0),18)-height,0)
        ao_gray=np.clip(valley*1000,0,255).astype(np.uint8)
        Image.fromarray(np.dstack((ao_gray,ao_gray,ao_gray,mask))).save(str(prefix)+'_ao.png',optimize=True)
        ao_overlay=np.zeros((h,w,4),np.uint8)
        ao_overlay[:,:,:3]=(42,37,31)
        ao_overlay[:,:,3]=np.clip(ao_gray.astype(np.float32)*.12*alpha,0,24).astype(np.uint8)
        Image.fromarray(ao_overlay).save(str(prefix)+'_ao_overlay.png',optimize=True)
        behind=np.zeros((H,W),np.uint8)
        for other in BEHIND.get(name,[]): behind=cv2.max(behind,masks[other])
        behind=behind[y:y+h,x:x+w].astype(np.float32)/255
        spread=cv2.GaussianBlur(alpha,(0,0),10 if layer['kind']=='mountain' else 11)
        outside=np.clip(spread-alpha,0,1)
        # The masks meet at many painted boundaries without sharing pixels.
        # A tiny support dilation lets the contact cue land on the actual
        # lower surface; it does not generate any new painted RGB.
        behind=cv2.dilate(behind,np.ones((9,9),np.uint8))
        max_shadow=.38 if layer['kind']=='mountain' else .28
        if name in {'adam','eve','christ'}: max_shadow=.36
        shadow=np.zeros((h,w,4),np.uint8)
        shadow[:,:,:3]=(43,38,32)
        shadow[:,:,3]=np.clip(outside*behind*max_shadow*255,0,255).astype(np.uint8)
        Image.fromarray(shadow).save(str(prefix)+'_shadow.png',optimize=True)
        visible=mask>127
        semantic[y:y+h,x:x+w][visible]=layer['depth']
        combined[y:y+h,x:x+w][visible]=layer['depth']+height[visible]*layer['reliefStrength']
        normal_view[y:y+h,x:x+w][visible]=encoded[visible]
        if layer['kind']=='mountain': debug_heights[name]=(mask,height,layer)
    # Diagnostic maps use fixed Z scales, so the three rock planes cannot be
    # artificially normalized into white blobs as they were in v2.
    cv2.imwrite(str(DOC/'03_semantic_depth.png'),np.clip(semantic/.48*255,0,255).astype(np.uint8))
    cv2.imwrite(str(DOC/'06_combined_depth.png'),np.clip(combined/.48*255,0,255).astype(np.uint8))
    Image.fromarray(normal_view).save(DOC/'07_normal_debug.png')
    for side,index in [('left','04'),('right','05')]:
        field=np.zeros((H,W),np.float32)
        for layer in layers:
            if layer['id'] not in debug_heights or not layer['id'].startswith(side):continue
            name=layer['id'];x,y,w,h=layer['crop'];mask,height,_=debug_heights[name]
            field[y:y+h,x:x+w][mask>127]=layer['depth']+height[mask>127]*layer['reliefStrength']
        # Dark rear, mid gray, light front ridge.
        grayscale=np.clip((field-.06)/.12*255,0,255).astype(np.uint8)
        grayscale[field==0]=0
        cv2.imwrite(str(DOC/f'{index}_{side}_mountain_heightmap.png'),grayscale)
    shutil.copyfile(SOURCE,DOC/'original_master_reference.jpg')
    Image.open(SOURCE).save(DOC/'01_original.png')
    manifest=dict(master='assets/anastasis/conch_reference.jpg',size=[W,H],
       coordinateConvention='master pixels from upper left; positive depth toward viewer',
       physicalVersion=3,renderer='Flutter Canvas.drawVertices, opaque ordered RGBA crops',
       lighting=dict(sourceRGB='original master only',textureHeadroom=1.015,
           defaultAngleDegrees=-20,displayMultiplier=[.83,1.015],
           material='matte painted plaster; no specular or metalness'),
       layers=layers)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    (DOC/'layer_manifest.json').write_text(json.dumps(manifest,indent=2))
    return masks

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--masks-only',action='store_true')
    args=parser.parse_args()
    layers,rgb=build_masks()
    if args.masks_only:
        print('review',len(layers),'masks at',DOC/'02_segmentation_masks_full.png')
        return
    build_geometry(layers,rgb)
    print('built',len(layers),'v3 layers and clean depth maps')

if __name__=='__main__':main()
