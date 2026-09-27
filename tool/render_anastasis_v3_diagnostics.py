"""Reproducible, source-aligned still diagnostics for the v3 relief assets.

The mobile and side-angle screenshots are captured by Flutter tests. This
script makes full-resolution mask, comparison, and section review sheets.
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'anastasis_25d/v3'
ASSETS = ROOT / 'assets/anastasis/relief_v3'
MANIFEST = json.loads((ASSETS / 'manifest.json').read_text())
SOURCE = np.asarray(Image.open(ROOT / MANIFEST['master']).convert('RGB'))
OLD = np.asarray(Image.open(ROOT / 'anastasis_25d/mobile_v2/center_full.png').convert('RGB'))


def font(size: int):
    p = '/System/Library/Fonts/Supplemental/Arial.ttf'
    return ImageFont.truetype(p, size) if Path(p).exists() else ImageFont.load_default()


def composite(light_angle: float = -20):
    """Straight-alpha full-resolution approximation of the Flutter photo view."""
    target = SOURCE.astype(np.float32).copy()
    angle = np.deg2rad(light_angle)
    for layer in MANIFEST['layers']:
        x, y, w, h = layer['crop']
        crop = target[y:y+h, x:x+w]
        texture = np.asarray(Image.open(ROOT / layer['litTexture']).convert('RGBA')).astype(np.float32)
        normal = np.asarray(Image.open(ROOT / layer['normal']).convert('RGBA')).astype(np.float32)[:, :, :3] / 127.5 - 1
        shadow = np.asarray(Image.open(ROOT / layer['contactShadow']).convert('RGBA')).astype(np.float32)
        s = shadow[:, :, 3:4] / 255
        crop[:] = crop * (1-s) + shadow[:, :, :3] * s
        nx, ny, nz = normal.transpose(2, 0, 1)
        dot = (nx*np.sin(angle)*.53-ny*np.cos(angle)*.53+nz*.75)/.987
        delta = dot-.75/.987
        name = layer['id']
        if layer['kind'] == 'mountain':
            base = .87 if name.endswith('_back') else .955 if name.endswith('_mid') else 1.02
            mult = np.clip(base+delta*.35, .83, 1)
        else:
            base = .91 if name.endswith('_rear_group') else .96 if name.endswith('_mid_group') else 1
            factor = .16 if name in {'christ','adam','eve'} or name.endswith('_front_group') else .08
            mult = np.clip(base+delta*factor, .90, 1)
        alpha = texture[:, :, 3:4]/255
        crop[:] = crop*(1-alpha)+texture[:, :, :3]*mult[:, :, None]*alpha
        ao = np.asarray(Image.open(ROOT / layer['aoOverlay']).convert('RGBA')).astype(np.float32)
        aa = ao[:, :, 3:4]/255
        crop[:] = crop*(1-aa)+ao[:, :, :3]*aa
    return Image.fromarray(np.clip(target, 0, 255).astype(np.uint8))


def mobile_image(arr: Image.Image):
    frame = Image.new('RGB', (390, 844), (25, 23, 22))
    small = arr.resize((390, 208), Image.Resampling.LANCZOS)
    frame.paste(small, (0, 318))
    return frame


def comparison(title: str, rect: tuple[int, int, int, int], image: Image.Image, filename: str):
    sources = [Image.fromarray(SOURCE), Image.fromarray(OLD), image]
    labels = ['ORIGINAL PHOTO', 'V2 RELIEF', 'V3 PAINTED RELIEF']
    crops = [s.crop(rect) for s in sources]
    tile_w = 500
    tile_h = round(crops[0].height*tile_w/crops[0].width)
    sheet = Image.new('RGB', (tile_w*3+32, tile_h+104), '#24201d')
    draw = ImageDraw.Draw(sheet)
    draw.text((16, 11), title, fill='#f0e5d0', font=font(27))
    for i, (crop, label) in enumerate(zip(crops, labels)):
        x = 8+i*(tile_w+8)
        sheet.paste(crop.resize((tile_w, tile_h), Image.Resampling.LANCZOS), (x, 56))
        draw.text((x+8, 65+tile_h), label, fill='#d9ccb8', font=font(18))
    sheet.save(OUT / filename)


def cross_section():
    mountain = [l for l in MANIFEST['layers'] if 'mountain' in l['id']]
    human = [l for l in MANIFEST['layers'] if 'group' in l['id']]
    chosen = mountain + human + [l for l in MANIFEST['layers'] if l['id'] in {'adam','eve','mandorla','christ'}]
    chosen.sort(key=lambda l: l['depth'])
    width, row = 1220, 34
    sheet = Image.new('RGB', (width, 110+row*len(chosen)), '#201e1c')
    draw = ImageDraw.Draw(sheet)
    draw.text((25, 18), 'ANASTASIS / PHYSICAL DEPTH SECTION', fill='#f1e5d3', font=font(24))
    draw.text((25, 54), 'CAMERA  ←   closer to viewer as Z increases', fill='#bfb09c', font=font(16))
    for i, layer in enumerate(reversed(chosen)):
        yy = 100+i*row
        z = layer['depth']
        x = round(650-z*850)
        color = layer['color']
        draw.rectangle((x,yy,x+12,yy+24), fill=color)
        draw.line((x+13,yy+12,750,yy+12),fill='#655e55',width=1)
        draw.text((765, yy+2), f"{layer['id']}  Z {z:.3f}  + {layer['reliefStrength']:.3f}", fill='#eee4d7',font=font(14))
    sheet.save(OUT/'16_cross_section_debug.png')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    relief = composite()
    relief.save(OUT/'static_full_resolution.png')
    mask = Image.open(OUT/'02_segmentation_masks_full.png').convert('RGB')
    mobile_image(mask).save(OUT/'02_segmentation_masks.png')
    original = Image.open(OUT/'original_390x844.png').convert('RGB')
    actual = Image.open(OUT/'08_static_relief_mobile.png').convert('RGB')
    side = Image.new('RGB', (780,844), '#211e1b')
    side.paste(original,(0,0));side.paste(actual,(390,0))
    side.save(OUT/'09_original_vs_relief.png')
    comparisons = [
        ('LEFT PAINTED ROCK PLANES',(160,125,810,410),'10_left_mountain_closeup.png'),
        ('RIGHT PAINTED ROCK PLANES',(1140,125,1940,410),'11_right_mountain_closeup.png'),
        ('ADAM / LEFT FIGURE BANDS',(155,255,955,850),'12_figures_left_closeup.png'),
        ('EVE / RIGHT FIGURE BANDS',(1120,250,1990,875),'13_figures_right_closeup.png'),
        ('CHRIST / ADAM / EVE',(550,280,1480,890),'14_christ_adam_eve_closeup.png'),
    ]
    for title, rect, name in comparisons:
        comparison(title,rect,relief,name)
    cross_section()
    # Compare the same physically authored mountain maps under opposed lights.
    left = np.asarray(composite(-70)).astype(np.int16)
    right = np.asarray(composite(70)).astype(np.int16)
    rock = np.zeros(SOURCE.shape[:2],np.uint8)
    for layer in MANIFEST['layers']:
        if layer['kind'] != 'mountain': continue
        m=cv2.imread(str(ROOT/layer['mask']),0)
        rock=np.maximum(rock,m)
    difference=np.abs(left-right).mean(axis=2)[rock>127]
    stats={'raking_rock_mean_rgb_difference':float(difference.mean()),
           'raking_rock_p90_rgb_difference':float(np.quantile(difference,.9)),
           'source_to_v3_mean_rgb_difference':float(np.abs(SOURCE.astype(np.int16)-np.asarray(relief).astype(np.int16)).mean()),
           'notes':'Full-resolution diagnostic renderer; on-phone screenshots are produced by Flutter tests.'}
    (OUT/'pixel_metrics.json').write_text(json.dumps(stats,indent=2))
    print(stats)


if __name__ == '__main__': main()
