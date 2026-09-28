"""Inspect offline glyph coverage: python3 tool/design/audit_fonts.py.

Install tool/design/requirements.txt in a virtual environment first.
"""
import json
import hashlib
from pathlib import Path
from fontTools.ttLib import TTFont
ROOT=Path(__file__).resolve().parents[2]
TEXT='İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil'
# The fetched specimens and shipped copies must match recorded official files.
manifest=json.loads((ROOT/'studio/design/fonts/sources.json').read_text())
for family in manifest['families']:
    for asset in family['files']:
        assert hashlib.sha256((ROOT/asset['path']).read_bytes()).hexdigest()==asset['sha256'], asset['path']
for source,bundled in [('cinzel','Cinzel'),('notosans','NotoSans'),('notoserifdisplay','NotoSerifDisplay')]:
    for src,dst in [(source+'.ttf',bundled+'.ttf'),(source+'-OFL.txt','OFL-'+bundled+'.txt')]:
        assert (ROOT/'studio/design/fonts'/src).read_bytes()==(ROOT/'assets/fonts'/dst).read_bytes(), dst
coverage={}
for p in (ROOT/'studio/design/fonts').glob('*.ttf'):
    font=TTFont(p); points=set(font.getBestCmap()); coverage[p.stem]=dict(missing=''.join(sorted(set(TEXT)-{chr(c) for c in points})))
for family in ['notosans','notoserifdisplay']:
    assert not coverage[family]['missing'], family
out=ROOT/'studio/captures/P03/font-coverage.json'
out.write_text(json.dumps({'specimen':TEXT,'families':coverage,'selected':{'display':'Cinzel with Noto Serif Display for Greek','body':'Noto Sans','numerals':'Noto Sans tabular figures'}},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(coverage,ensure_ascii=False))
