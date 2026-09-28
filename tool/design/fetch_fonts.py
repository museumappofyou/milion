"""Fetch official OFL font specimens: python3 tool/design/fetch_fonts.py.

Candidate files stay in studio/design/fonts; selected families are bundled later.
"""
import hashlib
import json
import urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'studio/design/fonts'
FAMILIES = ['cinzel', 'forum', 'marcellus', 'gfsneohellenic', 'notoserifdisplay',
            'literata', 'sourceserif4', 'alegreya', 'notoserif', 'notosans', 'ibmplexsans']

def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'MilionDesign/1.0'}), timeout=60).read()

def fetch(family):
    listing = json.loads(get('https://api.github.com/repos/google/fonts/contents/ofl/' + family))
    fonts = [x for x in listing if x['name'].endswith('.ttf') and 'Italic' not in x['name'] and 'Bold' not in x['name']]
    chosen = next((x for x in fonts if 'Regular' in x['name']), fonts[0])
    licence = next(x for x in listing if x['name'] == 'OFL.txt')
    records=[]
    for item, filename in [(chosen, family+'.ttf'), (licence, family+'-OFL.txt')]:
        data=get(item['download_url']); (OUT/filename).write_bytes(data)
        records.append(dict(path='studio/design/fonts/'+filename, url=item['download_url'], gitBlob=item['sha'], sha256=hashlib.sha256(data).hexdigest()))
    print(family, chosen['name'], flush=True)
    return dict(family=family, files=records)

OUT.mkdir(parents=True,exist_ok=True)
with ThreadPoolExecutor(max_workers=3) as pool:
    records=list(pool.map(fetch,FAMILIES))
(OUT/'sources.json').write_text(json.dumps(dict(accessedAt='2026-09-27',families=records),indent=2)+'\n')
