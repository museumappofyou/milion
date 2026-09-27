"""Second-pass painted-plaster relief assets from the existing semantic masks.

Usage: python3.11 tool/physical_relief.py
The mountain fields are sculpted from documented ridge controls, then smoothed;
the original fresco RGB remains the only visible painting. The generated matte
light textures are reversible display assets, not a repaint of the source.
"""
from pathlib import Path
import json
import math

import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/anastasis/relief'
DOC=ROOT/'studio/anastasis_25d/physical'

# Ridge points are master-image pixels. A ridge controls a broad elevated spine;
# widths are in source pixels. These follow the painted rock masses, not pigment
# microtexture. Separate spines and saddles give physically legible slopes.
RIDGES={
 'mountain_left': [
   ([(265,176),(358,164),(435,192),(523,177),(600,198),(692,208),(773,232)],.58,58),
   ([(65,470),(150,378),(251,298),(336,259),(429,270),(514,315),(638,320),(738,385)],.72,94),
   ([(100,593),(215,620),(321,651),(432,647),(535,616),(659,565),(764,518)],.43,103),
   ([(328,232),(389,285),(454,340),(488,401),(531,446)],.20,44),
 ],
 'mountain_right': [
   ([(1188,261),(1265,201),(1358,166),(1436,187),(1504,171),(1600,189),(1695,228)],.80,64),
   ([(1284,357),(1384,315),(1495,321),(1609,294),(1725,312),(1838,373),(1950,451)],.63,88),
   ([(1353,525),(1455,577),(1571,633),(1672,669),(1786,650),(1900,600),(2004,523)],.56,94),
   ([(1550,250),(1589,325),(1637,394),(1703,460),(1762,524)],.21,50),
 ],
}

# Large painted planes traced inside the two rock masses. The third value is
# the plane's local height; the fourth is its matte raking-light response.
# These are intentionally broad, because sub-10-pixel facets vanish on phones.
FACETS={
 'mountain_left':[
  ([(272,164),(349,151),(459,187),(449,240),(366,283),(285,244)],.83,1.12),
  ([(350,154),(511,168),(610,198),(552,286),(447,239)],.53,.70),
  ([(513,174),(649,188),(790,225),(750,288),(638,317),(544,282)],.77,1.14),
  ([(286,240),(368,280),(448,243),(550,285),(501,377),(387,355)],.44,.73),
  ([(520,284),(638,318),(751,286),(796,368),(706,420),(581,373)],.61,1.09),
  ([(87,328),(194,252),(292,227),(285,345),(194,439),(74,485)],.66,1.09),
  ([(14,473),(78,477),(192,438),(282,345),(295,485),(195,584)],.41,.78),
 ],
 'mountain_right':[
  ([(1175,258),(1230,191),(1353,156),(1436,182),(1385,259),(1278,316)],.85,1.17),
  ([(1353,156),(1492,167),(1574,207),(1518,273),(1384,260)],.48,.67),
  ([(1492,167),(1617,185),(1758,226),(1814,295),(1641,297),(1522,270)],.79,1.13),
  ([(1220,272),(1274,316),(1385,261),(1521,272),(1451,364),(1310,391)],.42,.73),
  ([(1520,271),(1643,297),(1812,293),(1928,380),(1799,433),(1624,394)],.64,1.07),
  ([(1830,431),(1930,388),(2043,489),(1993,570),(1892,617),(1771,595)],.58,.75),
 ],
}

PHYSICAL={
 'mountain_left':(.23,.30),'mountain_right':(.25,.30),
 'figures_left_rear':(.022,.20),'figures_right_rear':(.022,.20),
 'tomb_left':(.018,.10),'tomb_right':(.018,.10),'lower_gates':(.018,.07),
 'mandorla':(.025,.18),'adam':(.065,.72),'eve':(.065,.72),'christ':(.082,.72),
}

def ridge_field(shape,crop,lines):
    h,w=shape; x0,y0,_,_=crop
    field=np.zeros((h,w),np.float32)
    for points,height,width in lines:
        ridge=np.zeros((h,w),np.uint8)
        relative=np.array([[(x-x0,y-y0) for x,y in points]],np.int32)
        cv2.polylines(ridge,relative,False,255,5,cv2.LINE_AA)
        distance=cv2.distanceTransform(255-ridge,cv2.DIST_L2,5)
        field+=height*np.exp(-.5*(distance/width)**2)
    return field

def facet_fields(shape,crop,name):
    h,w=shape;x0,y0,_,_=crop
    height=np.full((h,w),.35,np.float32)
    response=np.ones((h,w),np.float32)
    for points,z,shade in FACETS[name]:
        region=np.zeros((h,w),np.uint8)
        relative=np.array([[(x-x0,y-y0) for x,y in points]],np.int32)
        cv2.fillPoly(region,relative,255)
        weight=cv2.GaussianBlur(region.astype(np.float32)/255,(0,0),5)
        height=height*(1-weight)+z*weight
        response=response*(1-weight)+shade*weight
    return height,response

def mountain_height(mask,crop,name):
    h,w=mask.shape
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    # Broad downhill trend prevents each painted mountain mass from becoming a
    # single inflated blob; spines, saddles and smaller crossing ridges remain.
    slope=.19+.13*(1-yy/max(1,h))
    ridges=ridge_field((h,w),crop,RIDGES[name])
    facets,facet_light=facet_fields((h,w),crop,name)
    raw=slope+ridges*.40+facets*.88
    smooth=cv2.GaussianBlur(raw,(0,0),3.0)
    binary=(mask>127).astype(np.uint8)
    edge=cv2.distanceTransform(binary,cv2.DIST_L2,5)
    bevel=.40+.60*np.clip(edge/24,0,1)
    clean=smooth*bevel
    inside=clean[binary>0]
    low,high=np.percentile(inside,[2,98])
    clean=np.clip((clean-low)/max(.01,high-low),0,1)
    clean*=mask.astype(np.float32)/255
    return raw.astype(np.float32),cv2.GaussianBlur(clean.astype(np.float32),(0,0),1.5),facet_light

def figure_height(rgb,mask,name):
    binary=(mask>127).astype(np.uint8)
    dist=cv2.distanceTransform(binary,cv2.DIST_L2,5)
    rounded=.18+.48*np.minimum(dist/68,1)
    lab=cv2.cvtColor(rgb,cv2.COLOR_RGB2LAB)[:,:,0].astype(np.float32)/255
    broad=cv2.GaussianBlur(lab,(0,0),34)
    fold=cv2.GaussianBlur(lab,(0,0),8)-broad
    raw=rounded+np.clip(fold*1.6,-.14,.14)
    if name=='christ':
        # The painted face is preserved as a shallow part of the figure.
        h,w=mask.shape
        face=np.zeros((h,w),np.uint8)
        # Local crop coordinates are obtained from its known master location.
        # The face mask is applied below in build() after crop normalization.
    clean=cv2.bilateralFilter(raw.astype(np.float32),9,.08,18)
    clean=np.clip(clean,0,1)*mask.astype(np.float32)/255
    return raw,clean

def normals_and_light(height,mask,kind,scale=1.5,light=(-.52,-.47,.70)):
    # Normals are derived from cleaned displacement, never from RGB pigment.
    gradient_x=cv2.Sobel(height,cv2.CV_32F,1,0,ksize=3)/8
    gradient_y=cv2.Sobel(height,cv2.CV_32F,0,1,ksize=3)/8
    normal_scale=(29 if kind=='mountain' else 13)*scale
    nx=-gradient_x*normal_scale;ny=-gradient_y*normal_scale
    nz=np.ones_like(nx)
    norm=np.sqrt(nx*nx+ny*ny+nz*nz)
    nx/=norm;ny/=norm;nz/=norm
    lx,ly,lz=light;length=math.sqrt(lx*lx+ly*ly+lz*lz)
    dot=np.clip((nx*lx+ny*ly+nz*lz)/length,0,1)
    # A shifted height comparison approximates short self-occlusion on the
    # side opposite a broad upper-left museum light.
    shifted=cv2.warpAffine(height,np.float32([[1,0,11],[0,1,9]]),
                         (height.shape[1],height.shape[0]),borderMode=cv2.BORDER_REPLICATE)
    valley=np.maximum(cv2.GaussianBlur(height,(0,0),24)-height,0)
    self_occ=np.clip((shifted-height)*.65+valley*.28,0,.18 if kind=='mountain' else .07)
    if kind=='mountain':
        shade=np.clip(.63+.54*dot,.65,1.12)
    else:
        shade=np.clip(.76+.32*dot,.78,1.07)
    encoded=np.stack(((nx+1)*127.5,(ny+1)*127.5,(nz+1)*127.5),axis=2)
    encoded=np.clip(encoded,0,255).astype(np.uint8)
    return encoded,shade.astype(np.float32),self_occ

def contact_shadow(mask,strength):
    alpha=mask.astype(np.float32)/255
    spread=cv2.GaussianBlur(alpha,(0,0),12)
    outside=np.clip(spread-alpha,0,1)
    # A second narrow term gives a plausible thin bevel at overlaps.
    near=cv2.GaussianBlur(alpha,(0,0),4)
    outside=np.clip(outside*.8+np.clip(near-alpha,0,1)*.4,0,1)
    return np.clip(outside*strength*255,0,255).astype(np.uint8)

def build_physical():
    DOC.mkdir(parents=True,exist_ok=True)
    manifest_path=ASSETS/'manifest.json'
    manifest=json.loads(manifest_path.read_text())
    master=np.array(Image.open(ROOT/manifest['master']).convert('RGB'))
    full_height=np.zeros(master.shape[:2],np.float32)
    raw_debug={}
    for layer in manifest['layers']:
        name=layer['id'];x,y,w,h=layer['crop']
        rgb=master[y:y+h,x:x+w]
        mask=cv2.imread(str(ASSETS/(name+'_mask.png')),0)[y:y+h,x:x+w]
        kind='mountain' if name.startswith('mountain') else 'figure'
        if kind=='mountain':
            occluders=['figures_left_rear','adam'] if name.endswith('left') \
                else ['figures_right_rear','eve']
            hidden=np.zeros((h,w),np.uint8)
            for other in occluders:
                full=cv2.imread(str(ASSETS/(other+'_mask.png')),0)
                hidden=np.maximum(hidden,full[y:y+h,x:x+w])
            hidden=cv2.dilate(hidden,np.ones((7,7),np.uint8))
            mask=np.clip(mask.astype(np.float32)*(1-hidden.astype(np.float32)/255),0,255).astype(np.uint8)
        cv2.imwrite(str(ASSETS/(name+'_physical_mask.png')),mask)
        if kind=='mountain':raw,height,facet_light=mountain_height(mask,(x,y,w,h),name)
        else:
            raw,height=figure_height(rgb,mask,name)
            facet_light=np.ones_like(height)
        if name=='christ':
            # Protect face proportions from the robe's fold-derived variation.
            cx,cy=977-x,414-y
            yy,xx=np.mgrid[0:h,0:w]
            face=((xx-cx)/43)**2+((yy-cy)/57)**2<1
            height[face]=cv2.GaussianBlur(height,(0,0),10)[face]
        normal,shade,ao=normals_and_light(height,mask,kind)
        if kind=='mountain':
            light_strength=1.0
        elif name in {'christ','adam','eve'}:
            light_strength=.82
        else:
            light_strength=.55
        effective=(1+(shade-1)*light_strength)*facet_light
        if kind=='mountain':effective=np.clip(effective,.60,1.18)
        lit=np.clip(rgb.astype(np.float32)*effective[:,:,None],0,255).astype(np.uint8)
        rgba=np.dstack((lit,mask));Image.fromarray(rgba).save(ASSETS/(name+'_lit.png'),optimize=True)
        normal_rgba=np.dstack((normal,mask));Image.fromarray(normal_rgba).save(ASSETS/(name+'_normal.png'),optimize=True)
        ao_gray=np.clip(ao/.18*255,0,255).astype(np.uint8)
        Image.fromarray(np.dstack((ao_gray,ao_gray,ao_gray,mask))).save(ASSETS/(name+'_ao.png'),optimize=True)
        ao_alpha=np.clip(ao/.18*95,0,95).astype(np.uint8)
        ao_overlay=np.zeros((h,w,4),np.uint8)
        ao_overlay[:,:,:3]=(45,37,30)
        ao_overlay[:,:,3]=(ao_alpha.astype(np.float32)*mask/255).astype(np.uint8)
        Image.fromarray(ao_overlay).save(ASSETS/(name+'_ao_overlay.png'),optimize=True)
        depth_gray=np.clip(height*255,0,255).astype(np.uint8)
        cv2.imwrite(str(ASSETS/(name+'_height.png')),depth_gray)
        Image.fromarray(np.dstack((depth_gray,depth_gray,depth_gray,mask))).save(ASSETS/(name+'_height_viz.png'),optimize=True)
        combined=np.clip((layer['depth']+height*PHYSICAL[name][0])/.7*255,0,255).astype(np.uint8)
        Image.fromarray(np.dstack((combined,combined,combined,mask))).save(ASSETS/(name+'_combined_viz.png'),optimize=True)
        cv2.imwrite(str(DOC/(name+'_raw.png')),np.clip(raw*150,0,255).astype(np.uint8))
        cv2.imwrite(str(DOC/(name+'_clean.png')),depth_gray)
        strength=PHYSICAL[name][1]
        shadow_alpha=contact_shadow(mask,strength)
        shadow=np.zeros((h,w,4),np.uint8)
        shadow[:,:,:3]=(39,30,25);shadow[:,:,3]=shadow_alpha
        Image.fromarray(shadow).save(ASSETS/(name+'_shadow.png'),optimize=True)
        layer['litTexture']=f'assets/anastasis/relief/{name}_lit.png'
        layer['normal']=f'assets/anastasis/relief/{name}_normal.png'
        layer['ao']=f'assets/anastasis/relief/{name}_ao.png'
        layer['aoOverlay']=f'assets/anastasis/relief/{name}_ao_overlay.png'
        layer['heightViz']=f'assets/anastasis/relief/{name}_height_viz.png'
        layer['combinedViz']=f'assets/anastasis/relief/{name}_combined_viz.png'
        layer['contactShadow']=f'assets/anastasis/relief/{name}_shadow.png'
        layer['physicalMask']=f'assets/anastasis/relief/{name}_physical_mask.png'
        layer['physicalRelief']=PHYSICAL[name][0]
        layer['contactStrength']=strength
        layer['reliefStrength']=PHYSICAL[name][0]
        full_height[y:y+h,x:x+w]=np.where(mask>127,
            layer['depth']+height*PHYSICAL[name][0],full_height[y:y+h,x:x+w])
    cv2.imwrite(str(DOC/'combined_depth.png'),np.clip(full_height/.7*255,0,255).astype(np.uint8))
    manifest['physicalVersion']=2
    manifest['lighting']={'model':'matte baked normal diffuse + short self occlusion',
                          'direction':[-.52,-.47,.70],'ambient':.63,
                          'defaultReliefScale':1.5,
                          'sourceRGB':'unchanged master capture'}
    text=json.dumps(manifest,indent=2)
    manifest_path.write_text(text)
    (ROOT/'studio/anastasis_25d/layer_manifest.json').write_text(text)

if __name__=='__main__':build_physical()
