"""Continuous bas-relief surface for three overlapping left witnesses.

Usage: python3.11 tool/figures_continuous_proto.py
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from figure_cluster_proto import ROOT,OUT,SOURCE,H,W,CROP,OUTER,LAYER,partitions,crop2

def render():
    masks=partitions()
    yy,xx=np.mgrid[:H,:W].astype(np.float32)
    # Semantic Z steps are smoothed only across uncertain internal group
    # boundaries. The outer silhouette remains the photographed v3 mask.
    z=np.zeros((H,W),np.float32)
    for info,m in zip(LAYER,masks):z[m>0]=info['z']
    z=cv2.GaussianBlur(z,(0,0),10)
    outer=(OUTER>127).astype(np.float32)
    local=np.zeros((H,W),np.float32)
    # Authored head/torso domes describe iconographic mass, not face anatomy.
    for info,m in zip(LAYER,masks):
        support=cv2.GaussianBlur((m>0).astype(np.float32),(0,0),12)
        for key,amp in [('head',.030),('torso',.017)]:
            cx,cy,rx,ry=info[key]
            local+=np.float32(amp*np.exp(-.5*(((xx-cx)/rx)**2+((yy-cy)/ry)**2)))*support
    z+=local
    z=cv2.GaussianBlur(z,(0,0),3)
    # Retain zero outside the original painted silhouette for the mesh.
    # Compute normals before clipping so its boundary does not form a wall of
    # unrealistically dark normals.
    # Only the modeled head/torso domes affect broad illumination. Semantic
    # step gradients are boundaries, not huge slopes painted across garments.
    local=cv2.GaussianBlur(local,(0,0),4)
    gx=cv2.Sobel(local,cv2.CV_32F,1,0,ksize=3)/8
    gy=cv2.Sobel(local,cv2.CV_32F,0,1,ksize=3)/8
    n=np.stack((-gx*190,-gy*190,np.ones_like(gx)),axis=2)
    n/=np.linalg.norm(n,axis=2,keepdims=True)
    light=np.array([-.55,-.42,.72],np.float32);light/=np.linalg.norm(light)
    response=np.clip(1+(n@light-light[2])*.57,.84,1.10)
    # Two true painted overlaps receive a short soft contact crease. We do
    # not follow all partition pixels, only selected visible robe boundaries.
    crease=np.zeros((H,W),np.uint8)
    cv2.polylines(crease,[np.array([(465,390),(450,415),(439,455),(431,503),(416,575),(405,632)],np.int32)],False,255,10,cv2.LINE_AA)
    cv2.polylines(crease,[np.array([(601,398),(590,420),(577,462),(565,505),(555,552)],np.int32)],False,255,10,cv2.LINE_AA)
    crease=cv2.GaussianBlur(crease,(0,0),6).astype(np.float32)/255
    response*=1-crease*.125
    out=SOURCE.astype(np.float32).copy()
    inside=outer>0
    out[inside]=SOURCE[inside]*response[inside,None]
    nv=np.full_like(SOURCE,(128,128,255))
    nv[inside]=np.uint8(np.clip((n[inside]+1)*127.5,0,255))
    colors=np.zeros_like(SOURCE)
    for info,m in zip(LAYER,masks):colors[m>0]=info['color']
    return np.uint8(np.clip(out,0,255)),nv,z*outer,colors,masks

def side45(depth):
    # Rasterize a connected textured triangle grid in 45° debug view.
    # Adjacent triangles share sample positions, so this is a surface rather
    # than three overlapping photograph cards.
    x0,y0,x1,y1=CROP
    scale=1.35;co=np.cos(np.pi/4)
    width=int((x1-x0)*scale*co+300)
    height=int((y1-y0)*scale+130)
    canvas=np.full((height,width,3),31,np.uint8)
    base=cv2.resize(SOURCE[y0:y1,x0:x1],(int((x1-x0)*scale),int((y1-y0)*scale)))
    srcmask=cv2.resize(OUTER[y0:y1,x0:x1],(base.shape[1],base.shape[0]))
    mat=np.float32([[co,0,60],[0,1,50]])
    bg=cv2.warpAffine(np.uint8(base*.48),mat,(width,height))
    bm=cv2.warpAffine(np.ones(base.shape[:2],np.uint8)*255,mat,(width,height))
    canvas[bm>0]=bg[bm>0]
    # One triangle at a time keeps alpha clipping on the painted silhouette.
    # Texture coordinates are exactly the master photograph coordinates.
    step=14
    for y in range(y0,y1,step):
        for x in range(x0,x1,step):
            corners=[(x,y),(min(x+step,x1-1),y),(min(x+step,x1-1),min(y+step,y1-1)),(x,min(y+step,y1-1))]
            for inds in [(0,1,2),(0,2,3)]:
                pts=[corners[i] for i in inds]
                if not any(OUTER[py,px]>127 for px,py in pts):continue
                srcpts=np.array([[(px-x0)*scale,(py-y0)*scale] for px,py in pts],np.float32)
                dstpts=np.array([[(px-x0)*scale*co+60+depth[py,px]*145,
                                  (py-y0)*scale+50-depth[py,px]*37] for px,py in pts],np.float32)
                sx0,sy0=np.floor(srcpts.min(axis=0)).astype(int);sx1,sy1=np.ceil(srcpts.max(axis=0)).astype(int)+2
                dx0,dy0=np.floor(dstpts.min(axis=0)).astype(int);dx1,dy1=np.ceil(dstpts.max(axis=0)).astype(int)+2
                sx0=max(sx0,0);sy0=max(sy0,0);dx0=max(dx0,0);dy0=max(dy0,0)
                sx1=min(sx1,base.shape[1]);sy1=min(sy1,base.shape[0]);dx1=min(dx1,width);dy1=min(dy1,height)
                if sx1<=sx0 or sy1<=sy0 or dx1<=dx0 or dy1<=dy0:continue
                affine=cv2.getAffineTransform(srcpts-np.array([sx0,sy0],np.float32),dstpts-np.array([dx0,dy0],np.float32))
                shape=(dx1-dx0,dy1-dy0)
                patch=cv2.warpAffine(base[sy0:sy1,sx0:sx1],affine,shape)
                alpha=cv2.warpAffine(srcmask[sy0:sy1,sx0:sx1],affine,shape).astype(np.float32)/255
                tri=np.zeros((shape[1],shape[0]),np.uint8)
                cv2.fillConvexPoly(tri,np.int32(np.round(dstpts-np.array([dx0,dy0]))),255)
                alpha*=tri.astype(np.float32)/255
                dest=canvas[dy0:dy1,dx0:dx1]
                canvas[dy0:dy1,dx0:dx1]=np.uint8(np.clip(dest*(1-alpha[:,:,None])+patch*alpha[:,:,None],0,255))
    return Image.fromarray(canvas)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    front,normals,depth,colors,masks=render()
    crop2(SOURCE).save(OUT/'figures_original.png')
    crop2(colors).save(OUT/'figures_masks.png')
    crop2(front).save(OUT/'figures_front.png')
    crop2(normals).save(OUT/'figures_normals.png')
    crop2(np.uint8(np.clip(depth/.36*255,0,255))).save(OUT/'figures_height.png')
    side45(depth).save(OUT/'figures_side45.png')
    for info,m in zip(LAYER,masks):Image.fromarray(m).save(OUT/f"{info['id']}_mask.png")
    print('continuous three-witness relief')

if __name__=='__main__':main()
