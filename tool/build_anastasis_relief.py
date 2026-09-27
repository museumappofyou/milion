"""Build editable semantic masks and texture-preserving relief layers.

Usage: python3.11 tool/build_anastasis_relief.py
Requires Python 3.11 with Pillow, OpenCV and NumPy. Source photos are read only.
The capture corpus comes from MILION_CAPTURES, defaulting to ../chora-ar/captures
next to the repository. The polygon list is deliberately plain data so
boundaries can be corrected by moving points without training or downloading a
model.
"""
from pathlib import Path
import csv
import json
import os

import cv2
import numpy as np
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def captures_root() -> Path:
    """Capture corpus root from MILION_CAPTURES or ../chora-ar/captures."""
    return Path(os.environ.get('MILION_CAPTURES', ROOT.parent / 'chora-ar' / 'captures'))


SOURCE = captures_root() / 'chora-scenes/5-PAREKKLESION/C__F02__Anastasis__dome__REF-8'
MASTER = ROOT / 'assets/anastasis/conch_reference.jpg'
OUT = ROOT / 'assets/anastasis/relief'
DOC = ROOT / 'studio/anastasis_25d'

# Pixel coordinates in the 2048 x 1091 prepared master. Boundaries follow
# visible paint, including Christ's outstretched arm and both raised wrists.
# Uncertain edges are kept slightly inside the painted figure.
SHAPES = {
 'mountain_left': [(0,489),(60,337),(152,251),(281,165),(361,150),(448,183),(527,162),(582,196),(675,199),(776,224),(795,267),(735,294),(732,397),(789,494),(803,573),(761,621),(668,601),(600,632),(521,624),(430,707),(306,735),(181,691),(95,603)],
 'mountain_right': [(1171,249),(1230,183),(1352,150),(1391,180),(1496,162),(1613,180),(1772,227),(1918,339),(2040,484),(2001,558),(1898,626),(1811,679),(1620,725),(1513,662),(1440,579),(1362,553),(1302,500),(1246,527),(1194,428),(1245,331)],
 'figures_left_rear': [(41,458),(104,346),(170,274),(249,240),(287,222),(331,250),(365,216),(430,190),(477,209),(504,282),(538,277),(578,306),(626,286),(670,322),(709,299),(747,343),(716,421),(763,484),(734,554),(669,543),(635,597),(577,586),(519,660),(427,670),(362,662),(274,641),(205,680),(149,641),(77,558)],
 'figures_right_rear': [(1305,355),(1340,309),(1389,284),(1433,262),(1484,243),(1531,206),(1616,199),(1727,252),(1848,312),(1944,396),(1943,509),(1881,570),(1795,630),(1769,700),(1696,707),(1645,636),(1602,666),(1539,618),(1480,674),(1419,615),(1369,554),(1325,496)],
 'mandorla': [(807,595),(810,513),(837,418),(885,334),(941,301),(986,311),(1050,343),(1110,403),(1168,482),(1213,571),(1195,632),(1194,724),(1149,786),(1055,822),(946,830),(858,784),(826,699)],
 'adam': [(164,778),(258,742),(330,682),(380,638),(421,612),(482,594),(526,576),(593,575),(636,591),(687,586),(732,588),(777,582),(808,585),(835,602),(860,616),(845,630),(821,624),(796,619),(757,631),(724,651),(713,680),(692,711),(663,735),(611,762),(568,790),(510,816),(443,839),(353,838),(284,824),(214,808)],
 'eve': [(1107,545),(1155,544),(1199,526),(1238,527),(1279,548),(1328,565),(1373,593),(1402,630),(1434,683),(1489,714),(1514,742),(1492,763),(1453,759),(1402,738),(1374,746),(1338,774),(1295,777),(1268,810),(1237,802),(1232,776),(1245,734),(1233,694),(1215,658),(1180,610),(1138,581),(1108,565)],
 'christ': [(916,839),(923,803),(915,748),(919,694),(918,659),(902,645),(865,641),(840,628),(826,627),(826,613),(843,601),(879,587),(907,567),(932,546),(936,512),(931,486),(944,456),(952,442),(954,413),(951,396),(962,377),(980,371),(998,378),(1010,394),(1012,417),(1005,445),(1032,433),(1061,441),(1085,451),(1103,471),(1120,491),(1133,509),(1139,540),(1149,552),(1161,555),(1165,568),(1156,581),(1138,584),(1124,571),(1120,555),(1108,565),(1124,593),(1151,624),(1184,658),(1199,680),(1184,690),(1167,677),(1157,714),(1161,754),(1171,777),(1189,805),(1196,831),(1179,840),(1154,817),(1129,811),(1101,830),(1074,834),(1049,829),(1027,835),(1000,830),(975,839),(957,825),(940,847)],
 'tomb_left': [(338,805),(395,789),(477,815),(578,807),(650,794),(694,807),(713,866),(641,901),(555,936),(466,924),(391,902),(347,864)],
 'tomb_right': [(1247,806),(1321,788),(1395,774),(1495,766),(1583,731),(1629,724),(1635,840),(1547,887),(1414,917),(1280,941)],
 'lower_gates': [(652,884),(754,857),(854,848),(934,842),(1014,849),(1097,850),(1184,831),(1256,821),(1265,937),(1176,970),(1070,990),(927,984),(827,956),(740,932)],
}

LAYER_INFO = [
 ('mountain_left', .055, .008, '#b7a977'),
 ('mountain_right', .055, .008, '#c6a579'),
 ('figures_left_rear', .105, .012, '#748bab'),
 ('figures_right_rear', .110, .012, '#9a7298'),
 ('tomb_left', .140, .005, '#817866'),
 ('tomb_right', .145, .005, '#7d786c'),
 ('lower_gates', .160, .005, '#585b66'),
 ('mandorla', .205, .009, '#c9ba98'),
 ('adam', .275, .022, '#8bacc6'),
 ('eve', .290, .022, '#aa6260'),
 ('christ', .365, .034, '#f2df99'),
]

# Coverage is recorded explicitly; "partial" never implies missing painted
# material has been reconstructed from another photograph.
COVERAGE = {
 '17.17.28': ('Christ and mandorla','yes','no','no','no'),
 '17.17.34': ('Christ with both extended arms','partial','partial','partial','no'),
 '17.17.36': ('Adam and Christ wrist','no','partial','partial','no'),
 '17.17.39': ('left figure group and Adam','no','partial','partial','partial'),
 '17.17.42': ('left group and Adam','no','partial','partial','partial'),
 '17.17.49': ('Eve and right group','no','partial','partial','partial'),
 '17.17.51': ('Eve and right group','no','partial','partial','partial'),
 '17.17.53': ('whole conch at a distance','yes','yes','yes','yes'),
 '17.17.58': ('lower gates and infernal elements','no','no','no','no'),
 '17.18.16': ('whole conch','yes','yes','yes','yes'),
 '17.18.24': ('right group with Eve','partial','partial','partial','partial'),
 '17.18.35': ('left group with Adam','partial','partial','partial','partial'),
 '17.18.48': ('whole conch','yes','yes','yes','yes'),
}

def mask_for(poly, w, h):
    big = np.zeros((h*2,w*2), np.uint8)
    cv2.fillPoly(big, [np.array(poly, np.int32)*2], 255)
    small = cv2.resize(big, (w,h), interpolation=cv2.INTER_AREA)
    # Keep the uncertain polygon just inside the painted edge. A short alpha
    # falloff hides hard polygon corners without painting any new content.
    small=cv2.erode(small,np.ones((3,3),np.uint8))
    return cv2.GaussianBlur(small,(0,0),2.0)

def edge_refine(image,poly):
    """Constrained GrabCut for high-contrast focal figures only.

    The polygon remains a hard outer limit, so the model cannot claim paint
    outside the hand-traced silhouette. Adam is excluded because his pale robe
    and the pale terrain do not separate reliably under this color model.
    """
    h,w=image.shape[:2]
    outer=np.zeros((h,w),np.uint8)
    cv2.fillPoly(outer,[np.array(poly,np.int32)],255)
    support=cv2.dilate(outer,np.ones((19,19),np.uint8))
    core=cv2.erode(outer,np.ones((25,25),np.uint8))
    labels=np.zeros((h,w),np.uint8)
    labels[support>0]=cv2.GC_PR_BGD
    labels[outer>0]=cv2.GC_PR_FGD
    labels[core>0]=cv2.GC_FGD
    bg=np.zeros((1,65),np.float64);fg=np.zeros((1,65),np.float64)
    cv2.grabCut(image,labels,None,bg,fg,5,cv2.GC_INIT_WITH_MASK)
    selected=np.where((labels==cv2.GC_FGD)|(labels==cv2.GC_PR_FGD),255,0).astype(np.uint8)
    selected=cv2.bitwise_and(selected,outer)
    selected=cv2.erode(selected,np.ones((3,3),np.uint8))
    return cv2.GaussianBlur(selected,(0,0),2.0)

def audit_and_contact():
    if not SOURCE.is_dir():
        raise SystemExit(
            f'Capture corpus not found: {SOURCE}\n'
            'Set MILION_CAPTURES to the corpus root (default: '
            '../chora-ar/captures next to the repository).')
    DOC.mkdir(exist_ok=True)
    files = sorted(p for p in SOURCE.iterdir() if p.suffix.lower() in {'.png','.jpg','.jpeg'})
    sheet = Image.new('RGB',(1200,((len(files)+3)//4)*245),'#ddd')
    rows=[]
    for i,p in enumerate(files):
        im=Image.open(p).convert('RGB')
        gray=cv2.cvtColor(np.asarray(im.resize((600,300))),cv2.COLOR_RGB2GRAY)
        sharp=round(float(cv2.Laplacian(gray,cv2.CV_64F).var()),1)
        thumb=ImageOps.contain(im,(286,190))
        x=(i%4)*300+(300-thumb.width)//2; y=(i//4)*245+5
        sheet.paste(thumb,(x,y))
        d=ImageDraw.Draw(sheet); d.text(((i%4)*300+6,y+194),p.name[:36],fill='black')
        d.text(((i%4)*300+6,y+211),f'{im.width}x{im.height}',fill='black')
        name=p.name
        if '17.18.48' in name:
            crop='full conch'; role='MASTER_TEXTURE, GEOMETRY_REFERENCE'; coverage='yes'; quality='frontal; bright lower edge; no obstruction in painted field'
        elif '17.18.16' in name or '17.17.53' in name:
            crop='full conch'; role='GEOMETRY_REFERENCE'; coverage='yes'; quality='perspective differs; lower edge bright; viewer frame/thumbnail'
        elif 'web-ke-01' in name:
            crop='full conch'; role='COLOR_REFERENCE, GEOMETRY_REFERENCE'; coverage='yes'; quality='higher contrast; watermark; oblique viewpoint'
        elif '1998' in name:
            crop='full conch'; role='COLOR_REFERENCE'; coverage='yes'; quality='historical exposure/color differ; low resolution'
        elif '2014_' in name:
            crop='apse plus conch'; role='GEOMETRY_REFERENCE'; coverage='partial'; quality='strong perspective; window glare; context only'
        elif 'F02-' in name or 'a3-f02' in name:
            crop='wide or lower detail'; role='DETAIL_REFERENCE' if '02' in name else 'REJECT'; coverage='partial'; quality='small guide image; photographer and tonal processing vary'
        else:
            crop='detail of figures or gates'; role='DETAIL_REFERENCE'; coverage='partial'; quality='viewer screenshot; some contain picture-in-picture; viewpoint varies'
        matched=next((v for k,v in COVERAGE.items() if k in name),None)
        portion,christ,adam,left_right,mountains=matched or (crop,coverage,coverage,coverage,coverage)
        rows.append(dict(filename=name,resolution=f'{im.width}x{im.height}',crop_coverage=crop,sharpness_laplacian=sharp,perspective_distortion=quality.split(';')[0],exposure='bright' if '17.18' in name else 'varies',color_quality=quality,obstructions='viewer bars/thumbnail possible' if 'Screenshot' in name else ('watermark' if 'web-ke' in name else 'none obvious'),visible_portion=portion,christ_complete=christ,adam_eve_complete=adam,left_right_groups_complete=left_right,mountains_background_visible=mountains,uses=role))
    with (DOC/'source_audit.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=rows[0].keys());writer.writeheader();writer.writerows(rows)
    sheet.save(DOC/'source_contact_sheet.jpg',quality=88)

def registration():
    out=DOC/'registration';out.mkdir(exist_ok=True)
    ref=cv2.imread(str(MASTER))
    orb=cv2.ORB_create(4500)
    kp1,des1=orb.detectAndCompute(cv2.cvtColor(ref,cv2.COLOR_BGR2GRAY),None)
    results=[]
    for file in ['conch_reference_alt.jpg','flat_reference.jpg']:
        other=cv2.imread(str(ROOT/'assets/anastasis'/file))
        kp2,des2=orb.detectAndCompute(cv2.cvtColor(other,cv2.COLOR_BGR2GRAY),None)
        matches=cv2.BFMatcher(cv2.NORM_HAMMING).knnMatch(des2,des1,k=2)
        good=[m for m,n in matches if m.distance < .72*n.distance]
        data={'file':file,'matches':len(good)}
        if len(good)>=20:
            src=np.float32([kp2[m.queryIdx].pt for m in good]);dst=np.float32([kp1[m.trainIdx].pt for m in good])
            H,inliers=cv2.findHomography(src,dst,cv2.RANSAC,4.0)
            data['inliers']=int(inliers.sum()) if inliers is not None else 0
            if H is not None:
                warped=cv2.warpPerspective(other,H,(ref.shape[1],ref.shape[0]))
                blend=cv2.addWeighted(ref,.5,warped,.5,0)
                cv2.imwrite(str(out/(file+'.overlay.jpg')),blend)
                cv2.imwrite(str(out/(file+'.aligned.jpg')),warped)
                data['homography']=H.tolist()
        results.append(data)
    (out/'diagnostics.json').write_text(json.dumps(results,indent=2))

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    rgb=cv2.cvtColor(cv2.imread(str(MASTER)),cv2.COLOR_BGR2RGB)
    h,w=rgb.shape[:2]
    assert (w,h)==(2048,1091),(w,h)
    layers=[]; preview=np.zeros((h,w,3),np.uint8)
    for order,(name,depth,relief,color) in enumerate(LAYER_INFO):
        mask=edge_refine(cv2.cvtColor(rgb,cv2.COLOR_RGB2BGR),SHAPES[name]) \
            if name in {'christ','eve'} else mask_for(SHAPES[name],w,h)
        cv2.imwrite(str(OUT/(name+'_mask.png')),mask)
        # Tight crop with 24-pixel guard for short second-pass contact shadows.
        ys,xs=np.where(mask>1)
        x0=max(0,int(xs.min())-24);x1=min(w,int(xs.max())+25)
        y0=max(0,int(ys.min())-24);y1=min(h,int(ys.max())+25)
        rgba=np.dstack((rgb[y0:y1,x0:x1],mask[y0:y1,x0:x1]))
        Image.fromarray(rgba).save(OUT/(name+'.png'),optimize=True)
        boundary=cv2.morphologyEx(mask,cv2.MORPH_GRADIENT,np.ones((5,5),np.uint8))
        edge=np.zeros((y1-y0,x1-x0,4),np.uint8)
        edge[:,:,:3]=(255,55,35)
        edge[:,:,3]=boundary[y0:y1,x0:x1]
        Image.fromarray(edge).save(OUT/(name+'_edge.png'),optimize=True)
        # Low-frequency lightness is a weak local shape cue; distance from the
        # silhouette brings the interior forward without modeling anatomy.
        light=cv2.cvtColor(rgb,cv2.COLOR_RGB2LAB)[:,:,0].astype(np.float32)/255
        low=cv2.GaussianBlur(light,(0,0),22)
        binary=(mask>127).astype(np.uint8)
        dist=cv2.distanceTransform(binary,cv2.DIST_L2,5)
        dist=np.minimum(dist/42,1)
        local=np.clip(.58*dist+.42*(low-.5),0,1)
        local=cv2.GaussianBlur(local,(0,0),3)
        local*=mask.astype(np.float32)/255
        cv2.imwrite(str(OUT/(name+'_height.png')),(local[y0:y1,x0:x1]*255).astype(np.uint8))
        c=tuple(int(color[i:i+2],16) for i in (1,3,5))
        preview[mask>127]=c
        layers.append(dict(id=name,depth=depth,reliefStrength=relief,priority=order,texture=f'assets/anastasis/relief/{name}.png',edge=f'assets/anastasis/relief/{name}_edge.png',mask=f'assets/anastasis/relief/{name}_mask.png',height=f'assets/anastasis/relief/{name}_height.png',crop=[x0,y0,x1-x0,y1-y0],color=color,visible=True,opacity=1.0))
    cv2.imwrite(str(DOC/'layer_colors.png'),cv2.cvtColor(preview,cv2.COLOR_RGB2BGR))
    manifest=dict(master='assets/anastasis/conch_reference.jpg',size=[w,h],coordinateConvention='master pixels from upper left; depth positive toward viewer in conch radii',layers=layers)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    (DOC/'layer_manifest.json').write_text(json.dumps(manifest,indent=2))

if __name__=='__main__':
    audit_and_contact();registration();build()
