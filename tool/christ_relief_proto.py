"""Fixed-camera Christ and mandorla relief with a complete fresco backing."""
from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'anastasis_25d/v4'
SOURCE=np.asarray(Image.open(ROOT/'assets/anastasis/conch_reference.jpg').convert('RGB'))
H,W=SOURCE.shape[:2]
CROP=(720,275,1320,885)
MASKS={n:cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{n}_mask.png'),0) for n in ('mandorla','christ')}


def crop2(arr):
    x0,y0,x1,y1=CROP
    return Image.fromarray(arr[y0:y1,x0:x1]).resize(((x1-x0),y1-y0),Image.Resampling.LANCZOS)


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    result=SOURCE.astype(np.float32).copy()
    mand=MASKS['mandorla'].astype(np.float32)/255
    christ=MASKS['christ'].astype(np.float32)/255
    # Always draw over the complete source fresco. Mask edges can only reveal
    # original paint, never transparency or a fabricated black crescent.
    mand_lit=np.clip(SOURCE.astype(np.float32)*.985,0,255)
    result=result*(1-mand[:,:,None])+mand_lit*mand[:,:,None]
    shifted=cv2.warpAffine(christ,np.float32([[1,0,2],[0,1,3]]),(W,H))
    contact=np.clip(cv2.GaussianBlur(shifted,(0,0),6)-christ,0,1)*mand*.32
    result*=1-contact[:,:,None]
    distance=cv2.distanceTransform((christ>.5).astype(np.uint8),cv2.DIST_L2,5)
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    height=.46+.085*np.tanh(distance/50)
    height+=.035*np.exp(-.5*(((xx-1005)/70)**2+((yy-427)/90)**2))
    height+=.025*np.exp(-.5*(((xx-1010)/115)**2+((yy-602)/150)**2))
    height=cv2.GaussianBlur(height.astype(np.float32),(0,0),6)
    gx=cv2.Sobel(height,cv2.CV_32F,1,0,ksize=3)/8
    gy=cv2.Sobel(height,cv2.CV_32F,0,1,ksize=3)/8
    normal=np.stack((-gx*105,-gy*105,np.ones_like(gx)),axis=2)
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    light=np.array([-.32,-.40,.86],np.float32);light/=np.linalg.norm(light)
    shade=np.clip(1.012+(normal@light-light[2])*.16,.95,1.055)
    painted=np.clip(SOURCE.astype(np.float32)*shade[:,:,None],0,255)
    result=result*(1-christ[:,:,None])+painted*christ[:,:,None]
    original=crop2(SOURCE)
    original.save(OUT/'christ_original.png')
    crop2(np.clip(result,0,255).astype(np.uint8)).save(OUT/'christ_relief.png')
    normals=np.full_like(SOURCE,(128,128,255),np.uint8)
    normals[christ>.5]=np.clip((normal[christ>.5]+1)*127.5,0,255).astype(np.uint8)
    crop2(normals).save(OUT/'christ_normals.png')
    x0,y0,x1,y1=CROP;cw=x1-x0;ch=y1-y0
    base=SOURCE[y0:y1,x0:x1]
    canvas=np.full((ch+110,cw+270,3),27,np.uint8)
    affine_base=np.float32([[.707,0,45],[0,1,40]])
    warped=cv2.warpAffine((base*.35).astype(np.uint8),affine_base,(canvas.shape[1],canvas.shape[0]))
    alpha=cv2.warpAffine(np.ones((ch,cw),np.uint8)*255,affine_base,(canvas.shape[1],canvas.shape[0]))
    canvas[alpha>0]=warped[alpha>0]
    for name,z,shade_value in [('mandorla',.308,.985),('christ',.438,1.012)]:
        affine=np.float32([[.707,0,45+z*300],[0,1,40-z*20]])
        pixels=cv2.warpAffine(np.clip(base.astype(np.float32)*shade_value,0,255).astype(np.uint8),affine,(canvas.shape[1],canvas.shape[0]))
        a=cv2.warpAffine(MASKS[name][y0:y1,x0:x1],affine,(canvas.shape[1],canvas.shape[0])).astype(np.float32)/255
        canvas=np.clip(canvas*(1-a[:,:,None])+pixels*a[:,:,None],0,255).astype(np.uint8)
    Image.fromarray(canvas).save(OUT/'christ_side45.png')
    print('Christ and mandorla over complete fresco base')

if __name__=='__main__':main()
