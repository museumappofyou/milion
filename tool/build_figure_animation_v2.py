"""Large articulated gestures with rigid facial handles and ARAP cloth motion.

Build separate v2 assets; never overwrite photographs or v1 animation assets.
python3.11 tool/build_figure_animation_v2.py
"""
import json
from pathlib import Path
import cv2
import numpy as np
from scipy import sparse
from scipy.ndimage import distance_transform_edt, map_coordinates
from scipy.sparse.linalg import factorized
from build_figure_animation import author, part_mask, shape_mask

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'figure_animation/v2'
FRAMES=48


def area_ratio(x,y,w,h):
    rows,cols=x.shape
    ax,ay=x[:-1,1:]-x[:-1,:-1],y[:-1,1:]-y[:-1,:-1]
    bx,by=x[1:,:-1]-x[:-1,:-1],y[1:,:-1]-y[:-1,:-1]
    cx,cy=x[1:,1:]-x[:-1,1:],y[1:,1:]-y[:-1,1:]
    ex,ey=x[1:,:-1]-x[:-1,1:],y[1:,:-1]-y[:-1,1:]
    area=w/(cols-1)*h/(rows-1)
    return min(float(np.min((ax*by-ay*bx)/area)),float(np.min((cx*ey-cy*ex)/area)))


def joints(name):
    # Centers and motion in original pixels for Anastasis; review pixels for Judgment.
    # The small rigid handle regions preserve hands, elbows and robe intersections.
    if name=='anastasis':
        return [
            ('Christ left shoulder',(945,497),19,(0,0),(1,0)),
            ('Christ left elbow',(904,552),20,(-5,-30),(1,0)),
            ('Christ and Adam joined hands',(833,609),20,(-10,-50),(1,0)),
            ('Adam elbow',(750,635),12,(5,-37),(1,0)),
            ('Adam rises',(611,714),30,(-3,-27),(1,0)),
            ('Adam feet',(414,793),19,(0,0),(1,0)),
            ('Christ right shoulder',(1054,480),19,(0,0),(1,0)),
            ('Christ right elbow',(1100,509),15,(10,-12),(1,0)),
            ('Christ and Eve joined hands',(1137,556),20,(10,-27),(1,0)),
            ('Eve bends',(1325,653),24,(-8,-9),(1,-.15)),
            ('Eve knees',(1270,737),24,(0,0),(1,0)),
            ('Christ chest',(999,530),27,(0,0),(1,0)),
            ('Christ robe',(1085,724),28,(16,-2),(.3,.7)),
            ('Christ feet',(1005,815),24,(0,0),(1,0)),
        ]
    return [
        ('Christ left hand',(705,642),7,(-3,-11),(1,0)),
        ('Christ right hand',(790,647),7,(6,-12),(1,0)),
        ('Christ body',(751,661),13,(0,0),(1,0)),
        ('Angel left wing',(657,391),11,(-8,-32),(.75,.3)),
        ('Angel right wing',(875,448),11,(12,-32),(.75,.3)),
        ('Angel left shoulder',(738,376),12,(0,0),(1,0)),
        ('Angel right shoulder',(817,399),10,(0,0),(1,0)),
        ('Angel robe',(790,333),16,(9,-8),(.3,.6)),
    ]


def build(name,spec):
    w,h=spec['size']; scale=np.array([w/spec['grid'][0],h/spec['grid'][1]])
    cols=321 if name=='anastasis' else 305; rows=round((cols-1)*h/w)+1
    n=rows*cols; assert n<65536
    yy,xx=np.meshgrid(np.linspace(0,h,rows),np.linspace(0,w,cols),indexing='ij')
    P=np.stack([xx.ravel(),yy.ravel()],axis=-1)
    base=ROOT/('anastasis_25d' if name=='anastasis' else 'last_judgment_25d')/'v5/authoring'
    cfg=json.loads((base/'layers.json').read_text())
    parts={p['id']:p for p in (sum([l['parts'] for l in cfg['layers']],[]) if 'layers' in cfg else cfg['parts'])}
    masks={}; active=np.zeros((h,w),np.uint8)
    handles=[]
    for c in spec['controls']:
        mask=np.zeros((h,w),bool)
        for pid in c['parts']:
            if pid not in masks:
                masks[pid]=part_mask((h,w),parts[pid]) if name=='anastasis' else shape_mask((h,w),parts[pid],scale)
            mask|=masks[pid]
        center=np.array(c['center'])*scale; radius=np.array(c['radius'])*scale
        zone=np.zeros((h,w),np.uint8)
        cv2.ellipse(zone,tuple(np.round(center).astype(int)),tuple(np.round(radius*1.1).astype(int)),0,0,360,1,-1)
        active|=(mask & (zone>0)).astype(np.uint8)
        if c['head']:
            # Exact rigid face + halo transform. A neighboring torso/arm cannot
            # squeeze the eyes, jaw or halo when the gesture grows larger.
            radius*=.44 if name=='last_judgment' and 'halo' in c['name'] else .57
            inside=((P[:,0]-center[0])/radius[0])**2+((P[:,1]-center[1])/radius[1])**2<=1
            shift=np.array(c['shift'])*scale*1.8
            degrees=c['degrees']*2.2
            if name=='anastasis' and c['name'].startswith('Adam'):
                shift+=np.array([-8,-34]); degrees=6
            if name=='anastasis' and c['name'].startswith('Eve'):
                shift+=np.array([-5,-10]); degrees=-9
            if name=='last_judgment' and c['name'] in ['Mary bows','John bows']:
                hand=np.array((674,630) if c['name']=='Mary bows' else (815,613))*scale
                inside |= np.linalg.norm(P-hand,axis=1)<=8*scale.mean()
            handles.append(dict(name=c['name'],indices=np.flatnonzero(inside),center=center,
                                pivot=np.array(c['pivot'])*scale,shift=shift,degrees=degrees,timing=c['timing']))
    # Wide seams absorb cloth/ground displacement while faces and hand regions
    # remain rigid. Inscriptions and scene border outside this support stay fixed.
    exterior=distance_transform_edt(active==0)
    support=map_coordinates((exterior<110*scale.mean()).astype(float),[yy.clip(0,h-1),xx.clip(0,w-1)],order=0)>0
    if name=='last_judgment':
        loss=np.zeros((h,w),bool)
        for p in cfg['losses']: loss|=shape_mask((h,w),p,scale)
        loss_at=map_coordinates((distance_transform_edt(loss)>35*scale.mean()).astype(float),[yy.clip(0,h-1),xx.clip(0,w-1)],order=0)>0
        support &= ~loss_at
    for label,xy,r,shift,timing in joints(name):
        center=np.array(xy)*scale; radius=r*scale.mean()
        inside=np.linalg.norm(P-center,axis=1)<=radius
        handles.append(dict(name=label,indices=np.flatnonzero(inside),center=center,pivot=center,
                            shift=np.array(shift)*scale,degrees=0,timing=timing))
    support[[0,-1],:]=False; support[:,[0,-1]]=False
    constrained=~support.ravel()
    # Only eligible nodes are controlled; deep loss interiors stay fixed.
    for item in handles:
        item['indices']=item['indices'][support.ravel()[item['indices']]]
        constrained[item['indices']]=True
    free=np.flatnonzero(~constrained); fixed=np.flatnonzero(constrained)
    grid=np.arange(n).reshape(rows,cols)
    froms=[];tos=[];weights=[]
    for dy,dx,weight in [(0,1,1),(1,0,1),(1,1,.5),(1,-1,.5)]:
        ys=slice(0,rows-dy);yt=slice(dy,rows)
        xs=slice(max(0,-dx),cols-max(0,dx));xt=slice(max(0,dx),cols-max(0,-dx))
        a=grid[ys,xs].ravel();b=grid[yt,xt].ravel()
        froms.extend([a,b]);tos.extend([b,a]);weights.extend([np.full(len(a),weight),np.full(len(a),weight)])
    src=np.concatenate(froms);dst=np.concatenate(tos);weight=np.concatenate(weights)
    adjacency=sparse.csr_matrix((weight,(src,dst)),shape=(n,n))
    degree=np.asarray(adjacency.sum(axis=1)).ravel()
    L=sparse.diags(degree)-adjacency
    L=L.tocsr();coupling=L[free,:][:,fixed]
    solve=factorized(L[free,:][:,free].tocsc())
    edges=P[src]-P[dst]
    poses=[];minimum=1
    for frame in range(FRAMES):
        t=frame/FRAMES;reach=np.sin(t*2*np.pi);follow=np.sin(t*4*np.pi)
        Q=P.copy()
        # Handle constraints are authored in paint order. Neck/head handles are
        # applied last so intersecting shoulder controls never deform a face.
        ordered=[i for i in handles if i['degrees']==0]+[i for i in handles if i['degrees']!=0]
        for item in ordered:
            ids=item['indices'];phase=item['timing'][0]*reach+item['timing'][1]*follow
            theta=np.deg2rad(item['degrees'])*phase
            rotation=np.array([[np.cos(theta),-np.sin(theta)],[np.sin(theta),np.cos(theta)]])
            Q[ids]=(P[ids]-item['pivot'])@rotation.T+item['pivot']+item['shift']*phase
        fixed_term=coupling@Q[fixed]
        # Harmonic initialization then local/global ARAP iterations.
        Q[free]=P[free]+solve(-coupling@(Q[fixed]-P[fixed]))
        for _ in range(35):
            warped=Q[src]-Q[dst]
            dot=np.bincount(src,weight*np.sum(edges*warped,axis=1),minlength=n)
            cross=np.bincount(src,weight*(edges[:,0]*warped[:,1]-edges[:,1]*warped[:,0]),minlength=n)
            angles=np.arctan2(cross,dot);co=np.cos(angles);si=np.sin(angles)
            c=(co[src]+co[dst])*.5;s=(si[src]+si[dst])*.5
            bx=np.bincount(src,weight*(c*edges[:,0]-s*edges[:,1]),minlength=n)
            by=np.bincount(src,weight*(s*edges[:,0]+c*edges[:,1]),minlength=n)
            Q[free]=solve(np.stack([bx[free],by[free]],axis=-1)-fixed_term)
        poses.append(((Q-P)/[w,h]).reshape(rows,cols,2))
    poses=np.array(poses,dtype=np.float32);poses[0]=0
    maximum=0
    for frame in range(FRAMES):
        for tween in [0,.25,.5,.75]:
            p=poses[frame]*(1-tween)+poses[(frame+1)%FRAMES]*tween
            for intensity in [.25,.5,.75,1]:
                dx,dy=p[:,:,0]*w*intensity,p[:,:,1]*h*intensity
                minimum=min(minimum,area_ratio(xx+dx,yy+dy,w,h))
                maximum=max(maximum,float(np.max(np.hypot(dx,dy))))
    print(name,'pose check',minimum,maximum,flush=True)
    if minimum<.06: raise ValueError(f'{name}: adjust handles; mesh area {minimum}')
    ids=np.flatnonzero(np.max(np.abs(poses.reshape(FRAMES,-1,2)),axis=(0,2))>1e-7)
    binary=poses.reshape(FRAMES,-1,2)[:,ids,:].astype('<f4').tobytes()
    binary_name=f'{name}_poses_v2.bin'
    (ROOT/'assets/explorer'/binary_name).write_bytes(binary)
    metadata=dict(version=2,cols=cols,rows=rows,frames=FRAMES,vertices=ids.tolist(),poses=f'assets/explorer/{binary_name}',durationSeconds=6,gestures=[i['name'] for i in handles])
    (ROOT/'assets/explorer'/f'{name}_figures_v2.json').write_text(json.dumps(metadata,separators=(',',':'))+'\n')
    previous=json.loads((ROOT/'figure_animation/build_report.json').read_text())[name]
    report=dict(method='rigid face/hand handles, ARAP cloth and local seam',vertices=n,animated_vertices=len(ids),frames=FRAMES,seconds=6,minimum_triangle_area_ratio=minimum,max_displacement_source_pixels=maximum,previous_max_displacement=previous['max_displacement_source_pixels'],travel_increase=maximum/previous['max_displacement_source_pixels'],checked_interpolated_poses=FRAMES*4,checked_intensities=[.25,.5,.75,1],pose_bytes=len(binary),textures_modified=0)
    authored=[{k:(v.tolist() if isinstance(v,np.ndarray) else v) for k,v in i.items() if k!='indices'} for i in handles]
    (OUT/'authoring'/f'{name}_joints.json').write_text(json.dumps(authored,indent=2)+'\n')
    print(name,json.dumps(report),flush=True)
    return report

if __name__=='__main__':
    import sys
    report_file=OUT/'build_report.json'
    reports=json.loads(report_file.read_text()) if report_file.exists() else {}
    for name,spec in author().items():
        if len(sys.argv)>1 and name not in sys.argv[1:]: continue
        reports[name]=build(name,spec)
        report_file.write_text(json.dumps(reports,indent=2)+'\n')
