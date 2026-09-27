"""Reviewable, stationary phone-size comparisons for fourth-pass experiments."""
from pathlib import Path
import json
import shutil

import numpy as np
from PIL import Image,ImageDraw,ImageFont
from figure_cluster_proto import partitions

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'anastasis_25d/v4'
SOURCE=Image.open(ROOT/'assets/anastasis/conch_reference.jpg').convert('RGBA')
MANIFEST=json.loads((ROOT/'assets/anastasis/relief_v3/manifest.json').read_text())
ROCKS={
 'left':((255,135,815,350),'connected_left'),
 'right':((1125,125,1700,350),'right_rock'),
}

def v3_rock(side):
    base=SOURCE.copy()
    for row in MANIFEST['layers']:
        if not row['id'].startswith(side+'_mountain'):continue
        overlay=Image.open(ROOT/row['litTexture']).convert('RGBA')
        x,y,_,_=row['crop']
        base.alpha_composite(overlay,(x,y))
    return base.convert('RGB')

def tile(im,width=390):
    return im.resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS)

def sheet(title,images,labels):
    width=390;gap=10;head=42
    things=[tile(i,width) for i in images]
    height=max(t.height for t in things)+head+gap*2
    out=Image.new('RGB',(len(things)*(width+gap)+gap,height),'#25211d')
    d=ImageDraw.Draw(out)
    d.text((gap,8),title,fill='#f5e9d8')
    for i,(im,label) in enumerate(zip(things,labels)):
        x=gap+i*(width+gap)
        out.paste(im,(x,head))
        d.text((x,head+im.height+3),label,fill='#f5e9d8')
    return out

def main():
    OUT.mkdir(exist_ok=True,parents=True)
    for old,new in [
        ('connected_left_original.png','left_rock_original.png'),
        ('connected_left_geometry.png','left_rock_geometry.png'),
        ('connected_left_normals.png','left_rock_normals.png'),
        ('connected_left_front.png','left_rock_front.png'),
        ('connected_left_raking.png','left_rock_raking_light.png'),
        ('connected_left_side45.png','left_rock_side45.png'),
        ('connected_left_depth.png','left_rock_depth.png'),
        ('connected_left_mesh.json','left_rock_mesh.json'),
    ]:
        shutil.copyfile(OUT/old,OUT/new)
    for side,(box,stem) in ROCKS.items():
        original=SOURCE.crop(box).convert('RGB')
        current=v3_rock(side).crop(box)
        candidate=Image.open(OUT/f'{stem}_front.png').convert('RGB')
        # Offline candidate was saved at 2x crop resolution; compare the
        # same source extent at 390 CSS px, without movement or animation.
        sheet(f'{side.upper()} ROCK • fixed front view',
              [original,current,candidate],
              ['Original','Current v3 asset composite','V4 authored facets'])\
             .save(OUT/f'{side}_mobile_comparison.png')
        tile(candidate).save(OUT/f'{side}_rock_390_static.png')
    sheet('LEFT WITNESSES • fixed front view',
          [Image.open(OUT/'figures_original.png'),Image.open(OUT/'figures_front.png')],
          ['Original','V4 continuous figure experiment']).save(OUT/'figures_mobile_comparison.png')
    sheet('CHRIST / MANDORLA • fixed front view',
          [Image.open(OUT/'christ_original.png'),Image.open(OUT/'christ_relief.png')],
          ['Original','V4 current experiment']).save(OUT/'christ_mobile_comparison.png')
    semantic=np.full((SOURCE.height,SOURCE.width,3),(26,28,34),np.uint8)
    legend=[]
    for row in MANIFEST['layers']:
        ident=row['id']
        if ident=='left_front_group':continue
        if 'mountain' in ident:
            col={'back':(105,85,28),'mid':(170,132,44),'front':(229,192,77)}[ident.rsplit('_',1)[-1]]
        elif ident=='christ':col=(225,62,58)
        elif ident=='mandorla':col=(73,182,201)
        elif ident in ('adam','eve'):col=(237,135,61)
        elif 'rear_group' in ident:col=(126,83,166)
        elif 'mid_group' in ident:col=(69,132,188)
        elif 'front_group' in ident:col=(76,164,112)
        else:col=(103,105,108)
        mask=np.array(Image.open(ROOT/row['mask']).convert('L'))>127
        semantic[mask]=col
        legend.append((ident,col))
    for mask,ident,col in zip(partitions(),
                              ['left_witness_rear','left_witness_middle','left_witness_front'],
                              [(139,103,163),(57,137,171),(97,174,99)]):
        semantic[mask>0]=col
        legend.append((ident,col))
    # Principal figures and mandorla must remain above the subdivided crowd.
    for row in MANIFEST['layers']:
        if row['id'] not in ('adam','eve','mandorla','christ'):continue
        col=dict(legend)[row['id']]
        mask=np.array(Image.open(ROOT/row['mask']).convert('L'))>127
        semantic[mask]=col
    Image.fromarray(semantic).save(OUT/'semantic_layers.png')
    tile(Image.fromarray(semantic)).save(OUT/'semantic_layers_390.png')
    (OUT/'semantic_colors.json').write_text(json.dumps({k:'#%02x%02x%02x'%v for k,v in legend},indent=2))
    print('static phone-size comparison sheets')

if __name__=='__main__':main()
