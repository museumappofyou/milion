"""Mobile-size visual acceptance renders for the physical Anastasis relief.

This raster diagnostic uses the same shipped textures, depth maps and layer
order as the Flutter viewer. It also exports original/v1/v2 close-up sheets.
"""
from pathlib import Path
import json
import cv2
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
ASSET=ROOT/'assets/anastasis/relief'
OUT=ROOT/'anastasis_25d/mobile_v2'
OUT.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ASSET/'manifest.json').read_text())
master=cv2.imread(str(ROOT/manifest['master']))

def composite(yaw=0,pitch=0,lit=True,shadows=True,relief_scale=1.5):
    canvas=master.astype(np.float32)
    for layer in manifest['layers']:
        name=layer['id'];x,y,w,h=layer['crop']
        path=layer['litTexture'] if lit else layer['texture']
        tex=cv2.imread(str(ROOT/path),cv2.IMREAD_UNCHANGED)
        if lit and relief_scale != 1.5:
            original=cv2.imread(str(ROOT/layer['texture']),cv2.IMREAD_UNCHANGED)
            factor=relief_scale/1.5
            tex[:,:,:3]=np.clip(original[:,:,:3].astype(np.float32)+(tex[:,:,:3].astype(np.float32)-original[:,:,:3].astype(np.float32))*factor,0,255).astype(np.uint8)
        shadow=cv2.imread(str(ROOT/layer['contactShadow']),cv2.IMREAD_UNCHANGED)
        ao=cv2.imread(str(ROOT/layer['aoOverlay']),cv2.IMREAD_UNCHANGED)
        height=cv2.imread(str(ROOT/layer['height']),0).astype(np.float32)/255
        depth=layer['depth']*.27
        local=height*layer['physicalRelief']*relief_scale
        # Pixel-varying motion is a shallow perspective change of the mesh,
        # not an independent animation of the mountain or person.
        dx=(yaw/5)*(depth+local)*105
        dy=(pitch/3)*(depth+local)*85
        if yaw or pitch:
            yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
            mx=xx-dx.astype(np.float32);my=yy-dy.astype(np.float32)
            tex=cv2.remap(tex,mx,my,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
            shadow=cv2.remap(shadow,mx,my,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
            ao=cv2.remap(ao,mx,my,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
        region=canvas[y:y+h,x:x+w]
        if shadows:
            sa=shadow[:,:,3:4].astype(np.float32)/255*min(relief_scale/1.5,1.34)
            region[:]=region*(1-sa)+shadow[:,:,:3].astype(np.float32)*sa
        alpha=tex[:,:,3:4].astype(np.float32)/255
        region[:]=region*(1-alpha)+tex[:,:,:3].astype(np.float32)*alpha
        if lit:
            aa=ao[:,:,3:4].astype(np.float32)/255*min(relief_scale/1.5,1.34)
            region[:]=region*(1-aa)+ao[:,:,:3].astype(np.float32)*aa
    return np.clip(canvas,0,255).astype(np.uint8)

def fit_crop(image,box,size):
    x0,y0,x1,y1=box
    crop=image[y0:y1,x0:x1]
    w,h=size
    scale=max(w/crop.shape[1],h/crop.shape[0])
    resized=cv2.resize(crop,(round(crop.shape[1]*scale),round(crop.shape[0]*scale)),interpolation=cv2.INTER_AREA)
    dx=(resized.shape[1]-w)//2;dy=(resized.shape[0]-h)//2
    return resized[dy:dy+h,dx:dx+w]

def mobile(image,width,height,style='relief'):
    display=np.full((height,width,3),(27,24,23),np.uint8)
    margin=12;content=width-24
    cv2.putText(display,'ANASTASIS',(18,42),cv2.FONT_HERSHEY_SIMPLEX,.60,(220,214,203),1,cv2.LINE_AA)
    cv2.putText(display,'Parekklesion  /  painted relief',(18,66),cv2.FONT_HERSHEY_SIMPLEX,.37,(154,149,140),1,cv2.LINE_AA)
    full_h=round(content*master.shape[0]/master.shape[1])
    display[84:84+full_h,margin:margin+content]=cv2.resize(image,(content,full_h),interpolation=cv2.INTER_AREA)
    y=84+full_h+24
    cv2.putText(display,'MOUNTAIN RELIEF',(18,y),cv2.FONT_HERSHEY_SIMPLEX,.42,(201,190,167),1,cv2.LINE_AA)
    y+=13
    available=height-y-70
    each=max(100,(available-12)//2)
    left=(0,135,780,725);right=(1210,135,2048,730)
    display[y:y+each,margin:margin+content]=fit_crop(image,left,(content,each))
    y+=each+12
    display[y:y+each,margin:margin+content]=fit_crop(image,right,(content,each))
    cv2.putText(display,'Original      |      Relief',(width//2-100,height-24),cv2.FONT_HERSHEY_SIMPLEX,.45,(210,200,182),1,cv2.LINE_AA)
    return display

def comparisons(new):
    old=cv2.imread(str(ROOT/'anastasis_25d/v1_baseline/center.png'))
    boxes={
      'christ_mandorla':(790,300,1220,850),
      'adam_left_group':(150,440,865,860),
      'eve_right_group':(1090,475,1560,825),
      'mountain_left':(0,130,830,725),
      'mountain_right':(1160,130,2048,730),
    }
    for name,box in boxes.items():
        x0,y0,x1,y1=box
        crops=[]
        for source in [master,old,new]:
            part=source[y0:y1,x0:x1]
            part=cv2.resize(part,(400,round(part.shape[0]*400/part.shape[1])),interpolation=cv2.INTER_AREA)
            crops.append(part)
        target_h=max(c.shape[0] for c in crops)
        sheet=np.full((target_h+45,1200,3),(34,31,29),np.uint8)
        for i,(label,crop) in enumerate(zip(['ORIGINAL','V1','PHYSICAL RELIEF'],crops)):
            sheet[45:45+crop.shape[0],i*400:(i+1)*400]=crop
            cv2.putText(sheet,label,(i*400+12,28),cv2.FONT_HERSHEY_SIMPLEX,.55,(225,216,200),1,cv2.LINE_AA)
        cv2.imwrite(str(OUT/(name+'_comparison.png')),sheet)

if __name__=='__main__':
    center=composite();flat=composite(lit=False,shadows=False)
    cv2.imwrite(str(OUT/'center_full.png'),center)
    cv2.imwrite(str(OUT/'flat_full.png'),flat)
    for width,height in [(360,800),(390,844),(430,932)]:
        cv2.imwrite(str(OUT/(f'center_{width}x{height}.png')),mobile(center,width,height))
        cv2.imwrite(str(OUT/(f'flat_{width}x{height}.png')),mobile(flat,width,height,'flat'))
    for strength in [.75,1,1.25,1.5,2]:
        key=str(strength).replace('.','_')
        cv2.imwrite(str(OUT/(f'relief_scale_{key}_390x844.png')),mobile(composite(relief_scale=strength),390,844))
    for name,yaw,pitch in [('left',-5,0),('right',5,0),('up',0,-3),('down',0,3)]:
        frame=composite(yaw,pitch)
        cv2.imwrite(str(OUT/(f'{name}_390x844.png')),mobile(frame,390,844))
    comparisons(center)
