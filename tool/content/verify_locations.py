"""Verify districts where Wikidata only says Istanbul: python3 tool/content/verify_locations.py.

Nominatim requests are serial and throttled; public responses remain cached.
"""
import csv
import json
import urllib.parse
from fetch_wikidata import CACHE, ROOT, fetch
from build_seed import values

DISTRICTS = {
    'fatih': 'Q732923', 'beyoglu': 'Q217411', 'besiktas': 'Q459495',
    'uskudar': 'Q326339', 'eyupsultan': 'Q673073', 'kadikoy': 'Q932886',
    'sariyer': 'Q857107', 'beykoz': 'Q794351', 'adalar': 'Q1020668',
    'kagithane': 'Q284489', 'maltepe': 'Q739547', 'catalca': 'Q272681',
    'buyukcekmece': 'Q840258', 'kucukcekmece': 'Q639240', 'silivri': 'Q732028',
    'sile': 'Q241631', 'kartal': 'Q639014', 'pendik': 'Q857056', 'tuzla': 'Q938548',
    'sisli': 'Q326095', 'zeytinburnu': 'Q197095', 'avcilar': 'Q340917',
}
selected = json.loads((ROOT / 'tool/content/seed_selection.json').read_text())
overrides = json.loads((ROOT / 'tool/content/seed_overrides.json').read_text())
for row in csv.DictReader((ROOT / 'tool/content/seed_places.tsv').open(), delimiter='\t'):
    key = row['id']
    if key not in selected:
        continue
    path = CACHE / (selected[key] + '.json')
    if not path.exists():
        continue
    entity = json.loads(path.read_text())
    district = overrides.get(key, {}).get('district', row['district'])
    if district == '-':
        continue
    admins = [v.get('id') for v in values(entity, 'P131')]
    if DISTRICTS.get(district) in admins or selected[key] == DISTRICTS.get(district):
        continue
    coords = values(entity, 'P625')
    coords.sort(key=lambda c: c.get('precision') or 1)
    p = overrides.get(key, {}).get('coordinates')
    if p is None and coords:
        p = dict(lat=coords[0]['latitude'], lng=coords[0]['longitude'])
    if p is None:
        print(key, 'MISSING COORDINATE', flush=True)
        continue
    query = urllib.parse.urlencode(dict(lat=p['lat'], lon=p['lng'], format='json', zoom=10, addressdetails=1))
    try:
        data = fetch('https://nominatim.openstreetmap.org/reverse?' + query, CACHE / (key + '-district.json'))
        print(key, district, data.get('display_name'), data.get('address'), flush=True)
    except Exception as error:
        print(key, error, flush=True)
