"""Matching connected rock-mesh prototype for the exposed right mountain.

Usage: python3.11 tool/connected_right_proto.py
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np

import connected_relief_proto as mesh

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'studio/anastasis_25d/v4'

TOP=[
 (1172,250,.145),(1230,184,.165),(1352,151,.135),
 (1390,180,.162),(1495,162,.125),(1594,183,.105),(1669,218,.085),
]
RIDGE=[
 (1175,282,.185),(1248,245,.205),(1350,211,.178),
 (1392,218,.182),(1493,217,.151),(1570,245,.124),(1645,267,.096),
]
BASE=[
 (1193,318,.155),(1263,307,.182),(1335,279,.164),
 (1415,285,.153),(1494,291,.126),(1575,305,.104),(1645,291,.083),
]


def main():
    mesh.CROP=(1125,125,1700,350)
    mesh.NODES={f'u{i}':p for i,p in enumerate(TOP)}|{f'v{i}':p for i,p in enumerate(RIDGE)}|{f'w{i}':p for i,p in enumerate(BASE)}
    mesh.QUADS=[]
    mesh.CREASE_EDGES=[('u1','v1'),('u2','v2'),('u4','v4')]
    mesh.CROWN_EDGES=[('u2','u3'),('u3','u4')]
    for i in range(6):
        mesh.QUADS.append((f'u{i}',f'u{i+1}',f'v{i+1}',f'v{i}'))
        mesh.QUADS.append((f'v{i}',f'v{i+1}',f'w{i+1}',f'w{i}'))
    def triangles():
        result=[]
        for a,b,c,d in mesh.QUADS:result.extend([(a,b,c),(a,c,d)])
        return result
    mesh.triangles=triangles
    mountain=np.zeros((mesh.H,mesh.W),np.uint8)
    for name in ('right_mountain_back','right_mountain_mid','right_mountain_front'):
        mountain=cv2.max(mountain,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{name}_mask.png'),0))
    people=np.zeros_like(mountain)
    for name in ('right_rear_group','right_mid_group','right_front_group','eve'):
        people=cv2.max(people,cv2.imread(str(ROOT/f'assets/anastasis/relief_v3/{name}_mask.png'),0))
    mesh.top_mask_cache=(mountain.astype(np.float32)/255)*(1-people.astype(np.float32)/255)
    front,normals,labels,depth,masks=mesh.render_front()
    debug,*_=mesh.render_front(True)
    mesh.crop2(mesh.SOURCE).save(OUT/'right_rock_original.png')
    mesh.crop2(front).save(OUT/'right_rock_front.png')
    mesh.crop2(debug).save(OUT/'right_rock_raking_light.png')
    mesh.crop2(normals).save(OUT/'right_rock_normals.png')
    mesh.crop2(labels).save(OUT/'right_rock_geometry.png')
    mesh.render_side(masks).save(OUT/'right_rock_side45.png')
    cv2.imwrite(str(OUT/'right_rock_depth.png'),np.clip(depth/.25*255,0,255).astype(np.uint8))
    (OUT/'right_rock_mesh.json').write_text(json.dumps({'vertices':mesh.NODES,'triangles':mesh.triangles()},indent=2))
    print('right',len(mesh.triangles()),'shared-facet triangles')

if __name__=='__main__':main()
