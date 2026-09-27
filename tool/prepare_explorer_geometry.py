"""Export compact sampled v5 geometry for optional in-app depth motion.

Usage: python3.11 tool/prepare_explorer_geometry.py
Reads height data only; never edits original or restored images.
"""
from pathlib import Path
import json
import cv2
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
for name,source in [('anastasis','studio/anastasis_25d/v5/build/height16.png'),('last_judgment','studio/last_judgment_25d/v5/height16.png')]:
    data=cv2.imread(str(ROOT/source),cv2.IMREAD_UNCHANGED)
    if data is None or data.dtype!=np.uint16: raise ValueError(source)
    h,w=data.shape
    cols=145;rows=round((cols-1)*h/w)+1
    xs=np.round(np.linspace(0,w-1,cols)).astype(int)
    ys=np.round(np.linspace(0,h-1,rows)).astype(int)
    heights=data[np.ix_(ys,xs)].astype(float)/256/w
    out=dict(cols=cols,rows=rows,size=[w,h],height=heights.round(6).flatten().tolist(),
        source=source,units='depth divided by master width')
    (ROOT/f'assets/explorer/{name}_geometry.json').write_text(json.dumps(out,separators=(',',':')))
    print(name,cols,rows,'vertices',cols*rows)
