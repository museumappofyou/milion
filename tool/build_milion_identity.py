"""Rebuild the code-authored Milion mark and Android/web launcher assets.

The mark is an inscriptional M standing on nothing but its own name: the
letter of Milion with the gilded zero of the Milion stone held in its
vertex. M + 0, the zero-mile point of Constantinople, in porphyry, marble
and tessera gold.

Run with python3.11 tool/build_milion_identity.py (Pillow required).
Geometry matches MilionMark in lib/theme/milion_theme.dart (64-unit grid).
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'

PORPHYRY = '#4E1B2B'
MARBLE = '#EEE7DB'
GOLD = '#C9A04C'

# Inscriptional M: flared legs 12..52 on the baseline 51, vertex at 31.
# The gold ring (outer r 6.9, inner r 3.45, centre 32,35) is tucked under
# the vertex, so the letter holds the zero.
M_PATH = ('M12,51 L18.4,51 L22.8,17 L32,31 L41.2,17 L45.6,51 L52,51 '
          'L45.6,12 L41.2,12 L32,27 L22.8,12 L18.4,12 Z')
RING_CX, RING_CY, RING_R, RING_W = 32, 35, 5.175, 3.45


def circle(cx, cy, r):
    return (f'M{cx},{cy - r} A{r},{r} 0 1 1 {cx},{cy + r} '
            f'A{r},{r} 0 1 1 {cx},{cy - r} Z')


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text + '\n')


def vector(monochrome=False):
    # 108dp adaptive canvas; 0.9 scale keeps the M inside the 66dp safe
    # circle of every launcher mask.
    ink = '#FFFFFF' if monochrome else MARBLE
    ring = '#FFFFFF' if monochrome else GOLD
    body = (
        f'    <path android:fillColor="#00000000" android:strokeColor="{ring}"'
        f' android:strokeWidth="{RING_W}"'
        f' android:pathData="{circle(RING_CX, RING_CY, RING_R)}"/>\n'
        f'    <path android:fillColor="{ink}" android:pathData="{M_PATH}"/>\n'
    )
    return ('<vector xmlns:android="http://schemas.android.com/apk/res/android" '
            'android:width="108dp" android:height="108dp" '
            'android:viewportWidth="108" android:viewportHeight="108">\n'
            '  <group android:translateX="25.2" android:translateY="25.2" '
            'android:scaleX="0.9" android:scaleY="0.9">\n'
            + body + '  </group>\n</vector>')


def raster(path, size, full_bleed=True):
    # Supersampled. The ring is painted in two discs; the M is painted over
    # its top, which also matches the stroked ring in the vector.
    k = 4
    image = Image.new('RGB', (size * k, size * k), PORPHYRY)
    draw = ImageDraw.Draw(image)
    # Launcher PNGs mimic the adaptive layout; brand PNG fills more of the frame.
    grid = 108 if full_bleed else 72
    scale = size * k / grid * (0.9 if full_bleed else 1)
    offset_x = (size * k - 64 * scale) / 2
    offset_y = (size * k - 64 * scale) / 2

    def xy(x, y):
        return offset_x + x * scale, offset_y + y * scale

    def disc(cx, cy, r, fill):
        draw.ellipse([*xy(cx - r, cy - r), *xy(cx + r, cy + r)], fill=fill)

    def poly(points, fill):
        draw.polygon([xy(x, y) for x, y in points], fill=fill)

    disc(RING_CX, RING_CY, RING_R + RING_W / 2, GOLD)
    disc(RING_CX, RING_CY, RING_R - RING_W / 2, PORPHYRY)
    m_points = []
    for pair in M_PATH.removeprefix('M').removesuffix('Z').split(' L'):
        x, y = pair.split(',')
        m_points.append((float(x), float(y)))
    poly(m_points, MARBLE)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)


svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">\n'
       f'  <rect width="64" height="64" rx="10" fill="{PORPHYRY}"/>\n'
       f'  <circle cx="{RING_CX}" cy="{RING_CY}" r="{RING_R}" fill="none" '
       f'stroke="{GOLD}" stroke-width="{RING_W}"/>\n'
       f'  <path fill="{MARBLE}" d="{M_PATH}"/>\n'
       '</svg>')
write(ROOT / 'assets/brand/milion-mark.svg', svg)
write(ROOT / 'web/milion-mark.svg', svg)
write(RES / 'drawable/milion_foreground.xml', vector())
write(RES / 'drawable/milion_monochrome.xml', vector(True))
write(RES / 'values/milion_colors.xml',
      f'<resources><color name="milion_porphyry">{PORPHYRY}</color></resources>')
for version in ['v26', 'v33']:
    write(RES / f'mipmap-anydpi-{version}/ic_launcher.xml',
          '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '  <background android:drawable="@color/milion_porphyry"/>\n'
          '  <foreground android:drawable="@drawable/milion_foreground"/>\n'
          + ('  <monochrome android:drawable="@drawable/milion_monochrome"/>\n' if version == 'v33' else '')
          + '</adaptive-icon>')
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    raster(RES / f'mipmap-{density}/ic_launcher.png', size)
for name, size in [('Icon-192', 192), ('Icon-512', 512), ('Icon-maskable-192', 192), ('Icon-maskable-512', 512)]:
    raster(ROOT / f'web/icons/{name}.png', size)
raster(ROOT / 'web/favicon.png', 32, full_bleed=False)
raster(ROOT / 'assets/brand/milion-icon.png', 512)
for folder, parent in [('values-v31', 'Theme.Light.NoTitleBar'), ('values-night-v31', 'Theme.Black.NoTitleBar')]:
    write(RES / folder / 'styles.xml',
          '<resources>\n'
          f'  <style name="LaunchTheme" parent="@android:style/{parent}">\n'
          '    <item name="android:windowSplashScreenBackground">@color/milion_porphyry</item>\n'
          '    <item name="android:windowSplashScreenAnimatedIcon">@drawable/milion_foreground</item>\n'
          '    <item name="android:windowBackground">@drawable/launch_background</item>\n'
          '  </style>\n</resources>')
for folder in ['drawable', 'drawable-v21']:
    write(RES / folder / 'launch_background.xml',
          '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '  <item android:drawable="@color/milion_porphyry"/>\n'
          '  <item android:gravity="center" android:drawable="@drawable/milion_foreground"/>\n'
          '</layer-list>')
print('Milion M mark, launcher densities, adaptive/themed icons and splash assets rebuilt.')
