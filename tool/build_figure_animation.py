"""Author local figure poses from the existing v5 masks; never alter textures.

Run: python3.11 tool/build_figure_animation.py
Two cyclic displacement bases, with rigid head/halo regions, hinged gestures,
anchored feet and a narrow silhouette transition. Mesh remains connected.
"""
import json
from pathlib import Path
import cv2
import numpy as np
from scipy.ndimage import distance_transform_edt, map_coordinates
from build_anastasis_v5 import part_mask
from build_last_judgment_v5 import shape_mask

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'figure_animation'


def control(name, parts, center, radius, pivot, angle=0, shift=(0, 0), timing=(1, 0), head=False):
    return dict(name=name, parts=parts.split(), center=center, radius=radius,
                pivot=pivot, degrees=angle, shift=shift, timing=timing, head=head)


def author():
    # Coordinates on the original photographs, except Judgment's review grid.
    a = [
        control('Christ inclines his head', 'christ christ_halo', (970,410),(90,110),(975,476), -4, (1,-2), (1,.12), True),
        control('Christ left shoulder reaches', 'christ', (936,533),(122,110),(1002,496), 3, (0,-3)),
        control('Joined hands lift Adam', 'christ adam', (833,609),(130,98),(910,549), 0, (7,-16)),
        control('Adam rises from the tomb', 'adam', (638,688),(208,165),(460,806), 1.5, (3,-9)),
        control('Adam looks toward Christ', 'adam', (693,621),(61,83),(693,682), 4,(1,-3),(1,.1),True),
        control('Christ right elbow opens', 'christ', (1101,518),(88,85),(1035,471), -4,(1,-2)),
        control('Joined hands draw Eve forward', 'christ eve', (1137,556),(105,80),(1180,580), 0,(-8,-10)),
        control('Eve bows toward Christ', 'eve', (1252,565),(79,79),(1288,618), -5,(-2,-1),(1,-.15),True),
        control('Eve bends at the waist', 'eve', (1320,648),(150,115),(1405,758), -2,(-2,-4)),
        control('Christ robe folds settle', 'christ', (1080,738),(160,118),(1020,633), 1,(5,0),(.35,.65)),
        control('Eve trailing robe sways', 'eve', (1423,736),(92,61),(1360,710), -2,(2,-2),(.25,-.6)),
    ]
    for name,parts,xy,angle,timing in [
        ('David','l_david',(469,359),2.4,(.45,.45)),
        ('Solomon','l_solomon',(562,395),-3,(.75,-.2)),
        ('John','l_john',(685,376),3,(.65,.3)),
        ('Abel','r_abel',(1369,388),-3,(.8,-.3)),
        ('Right elder','r_ochre',(1545,226),2,(.35,.5)),
    ]:
        a.append(control(name+' turns his head',parts,xy,(70,89),(xy[0],xy[1]+53),angle,(0,-1),timing,True))
    j = [
        control('Christ nods', 'christ', (751,600),(35,42),(752,629),-4,(0,-1),(1,.15),True),
        control('Christ left hand opens', 'christ', (711,640),(44,40),(743,634),4,(-1,-3)),
        control('Christ right hand opens', 'christ', (788,646),(39,34),(761,636),-4,(1,-3)),
        control('Mary bows', 'mary', (669,598),(40,52),(655,649),-4,(-1,0),(.8,.2),True),
        control('Mary raises her hands', 'mary', (672,638),(40,40),(651,631),-4,(1,-3)),
        control('John bows', 'john', (823,582),(40,49),(835,633),4,(-1,1),(.7,-.25),True),
        control('John gestures toward Christ', 'john', (815,617),(40,42),(836,610),4,(-1,-3)),
        control('Angel left wing extends', 'rolling_angel', (693,393),(70,39),(751,381),-5,(-1,-4),(.75,.3)),
        control('Angel right wing extends', 'rolling_angel', (851,424),(56,62),(816,392),6,(2,-3),(.75,.3)),
        control('Angel head inclines', 'rolling_angel', (790,398),(32,37),(782,376),-4,(0,-1),(.7,-.3),True),
        control('Angel trailing garments move', 'rolling_angel', (795,326),(99,46),(751,352),2,(2,-3),(.3,.6)),
        control('Left kneeling figure bows', 'left_kneeling', (710,864),(41,44),(682,904),-4,(0,2),(.75,.2),True),
        control('Right kneeling figure bows', 'right_kneeling', (822,859),(40,40),(849,895),4,(0,2),(.6,-.2),True),
    ]
    heads=[('l1',365,525),('l2',420,543),('l3',467,550),('l4',510,574),('l5',552,592),('l6',589,612),
           ('r1',906,596),('r2',953,587),('r3',987,580),('r4',1041,578),('r5',1084,558),('r6',1136,555)]
    for i,(name,x,y) in enumerate(heads):
        j.append(control(name+' head and halo',name+' '+name+'_halo',(x,y),(36,45),(x,y+29),
                         (2.5 if i<6 else -2.5),(0,-.8),(.45+(i%3)*.15, .24*(-1)**i),True))
    return {'anastasis':dict(size=[2048,1091],grid=[2048,1091],controls=a),
            'last_judgment':dict(size=[1600,1067],grid=[1500,1000],controls=j)}


def smooth(x):
    x=np.clip(x,0,1)
    return x*x*(3-2*x)


def build(name, spec):
    w,h=spec['size']; scale=np.array([w/spec['grid'][0],h/spec['grid'][1]])
    base=ROOT / ('anastasis_25d' if name=='anastasis' else 'last_judgment_25d') / 'v5/authoring'
    cfg=json.loads((base/'layers.json').read_text())
    parts={p['id']:p for p in (sum([l['parts'] for l in cfg['layers']],[]) if 'layers' in cfg else cfg['parts'])}
    cols=257; rows=round((cols-1)*h/w)+1
    yy,xx=np.meshgrid(np.linspace(0,h,rows),np.linspace(0,w,cols),indexing='ij')
    coordinates=np.array([yy.clip(0,h-1),xx.clip(0,w-1)])
    fields=np.zeros((rows,cols,4),np.float64)
    masks={}
    for c in spec['controls']:
        mask=np.zeros((h,w),bool)
        for pid in c['parts']:
            if pid not in masks:
                masks[pid]=part_mask((h,w),parts[pid]) if name=='anastasis' else shape_mask((h,w),parts[pid],scale)
            mask |= masks[pid]
        center=np.array(c['center'])*scale; radius=np.array(c['radius'])*scale
        pivot=np.array(c['pivot'])*scale; shift=np.array(c['shift'])*scale
        if c['head']:
            # A face and its halo rotate together, including tiny pigment holes.
            cv2.ellipse(mask.view(np.uint8),tuple(np.round(center).astype(int)),
                        tuple(np.round(radius*.61).astype(int)),0,0,360,1,-1)
        # One continuous surface: a smooth, bounded seam outside each figure.
        exterior=distance_transform_edt(~mask)
        support=smooth(1-exterior/(32*scale.mean()))
        influence=map_coordinates(support,coordinates,order=1,mode='nearest')
        r=np.sqrt(((xx-center[0])/radius[0])**2+((yy-center[1])/radius[1])**2)
        influence*=smooth((1-r)/.38)
        theta=np.deg2rad(c['degrees'])
        # Tangential joint displacement preserves a rigid face to first order.
        dx=-(yy-pivot[1])*theta+shift[0]
        dy=(xx-pivot[0])*theta+shift[1]
        for k,t in enumerate(c['timing']):
            fields[:,:,2*k] += dx*influence*t
            fields[:,:,2*k+1] += dy*influence*t
    if name=='last_judgment':
        loss=np.zeros((h,w),bool)
        for p in cfg['losses']: loss |= shape_mask((h,w),p,scale)
        # Missing plaster, and an 8px easing edge beside it, remain stationary.
        distance=distance_transform_edt(~loss)
        keep=map_coordinates(smooth(distance/8),coordinates,order=1,mode='nearest')
        fields*=keep[:,:,None]
    fields[[0,-1],:]=0; fields[:,[0,-1]]=0
    def check(factor):
        lowest=1.; maximum=0.
        for t in np.linspace(0,1,97):
            dx=(fields[:,:,0]*np.sin(2*np.pi*t)+fields[:,:,2]*np.sin(4*np.pi*t))*factor
            dy=(fields[:,:,1]*np.sin(2*np.pi*t)+fields[:,:,3]*np.sin(4*np.pi*t))*factor
            px,py=xx+dx,yy+dy
            ax,ay=px[:-1,1:]-px[:-1,:-1],py[:-1,1:]-py[:-1,:-1]
            bx,by=px[1:,:-1]-px[:-1,:-1],py[1:,:-1]-py[:-1,:-1]
            cx,cy=px[1:,1:]-px[:-1,1:],py[1:,1:]-py[:-1,1:]
            ex,ey=px[1:,:-1]-px[:-1,1:],py[1:,:-1]-py[:-1,1:]
            area=(w/(cols-1))*(h/(rows-1))
            lowest=min(lowest,float(np.min((ax*by-ay*bx)/area)),float(np.min((cx*ey-cy*ex)/area)))
            maximum=max(maximum,float(np.max(np.hypot(dx,dy))))
        return lowest,maximum
    factor=1.
    while check(factor)[0]<.30: factor*=.95
    fields*=factor
    smallest,maximum=check(1.)
    # Compact sparse displacement channels, normalized for any viewport/texture.
    fields[:,:,[0,2]]/=w; fields[:,:,[1,3]]/=h
    flat=np.round(fields.reshape(-1,4),7)
    ids=np.flatnonzero(np.any(flat!=0,axis=1))
    asset=dict(version=1,cols=cols,rows=rows,vertices=ids.tolist(),offsets=flat[ids].reshape(-1).tolist(),
               gestures=[c['name'] for c in spec['controls']])
    path=ROOT/'assets/explorer'/f'{name}_figures.json'
    path.write_text(json.dumps(asset,separators=(',',':'))+'\n')
    report=dict(vertices=cols*rows,animated_vertices=len(ids),gestures=len(spec['controls']),
                amplitude_scale=factor,max_displacement_source_pixels=maximum,
                minimum_triangle_area_ratio=smallest,checked_poses=97,
                texture_files_modified=0,asset_bytes=path.stat().st_size)
    print(name,json.dumps(report))
    return report

if __name__=='__main__':
    reports={}
    for name,spec in author().items():
        (OUT/'authoring'/f'{name}_joints.json').write_text(json.dumps(spec,indent=2)+'\n')
        reports[name]=build(name,spec)
    (OUT/'build_report.json').write_text(json.dumps(reports,indent=2)+'\n')
