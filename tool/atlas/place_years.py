"""Usage: python3.11 tool/atlas/place_years.py [--fetch]

When each registry place first stood, for the Atlas time slider (P10).
--fetch asks Wikidata's SPARQL endpoint for P571 (inception) of every place's
QID and keeps the response in studio/atlas/wikidata_inception.json (with the
query and its date). Without --fetch it rebuilds from that file.

Output: assets/atlas/place_years.json, {"schemaVersion": 1, "kind":
"atlas-place-years", "source": "wikidata-inception", "places": {id: year}}.
A place with several inception statements takes the earliest; years are
proleptic (negative for BC); precision coarser than a century is dropped.
Places without a usable P571 are absent and the app falls back to their eras.
"""
import json
import sys
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLACES = ROOT / 'assets/content/places/istanbul.json'
RAW = ROOT / 'studio/atlas/wikidata_inception.json'
OVERRIDES = ROOT / 'studio/atlas/place_years_overrides.json'
OUT = ROOT / 'assets/atlas/place_years.json'
ENDPOINT = 'https://query.wikidata.org/sparql'
USER_AGENT = 'milion-build/1.0 (private development)'


def qids():
    data = json.loads(PLACES.read_text(encoding='utf-8'))
    return {r['qid']: r['id'] for r in data['records']}


def fetch():
    values = ' '.join(f'wd:{q}' for q in sorted(qids()))
    query = (
        'SELECT ?item ?time ?precision WHERE { VALUES ?item { %s } '
        '?item p:P571 ?st . ?st psv:P571 ?v . ?v wikibase:timeValue ?time ; '
        'wikibase:timePrecision ?precision . '
        'FILTER NOT EXISTS { ?st wikibase:rank wikibase:DeprecatedRank } }' % values)
    url = ENDPOINT + '?' + urllib.parse.urlencode({'query': query, 'format': 'json'})
    request = urllib.request.Request(url, headers={'User-Agent': USER_AGENT,
                                                   'Accept': 'application/sparql-results+json'})
    with urllib.request.urlopen(request, timeout=120) as response:
        result = json.loads(response.read())
    RAW.parent.mkdir(parents=True, exist_ok=True)
    RAW.write_text(json.dumps({'endpoint': ENDPOINT, 'query': query,
                               'fetchedAt': date.today().isoformat(),
                               'licence': 'CC0 1.0 (Wikidata)',
                               'result': result}, ensure_ascii=False, indent=1) + '\n',
                   encoding='utf-8')


def year_of(time):
    # "+0537-01-01T00:00:00Z" or "-0667-..." (Wikidata uses astronomical years
    # for BC in timeValue: -0667 is 668 BC; keep the value as stored).
    sign = -1 if time.startswith('-') else 1
    return sign * int(time.lstrip('+-').split('-')[0])


def build():
    raw = json.loads(RAW.read_text(encoding='utf-8'))
    by_qid = qids()
    years = {}
    for b in raw['result']['results']['bindings']:
        qid = b['item']['value'].rsplit('/', 1)[1]
        precision = int(b['precision']['value'])
        if precision < 7:  # 7 = century, 8 = decade, 9 = year
            continue
        y = year_of(b['time']['value'])
        if precision == 7:
            # "the 6th century" is stored as 0600 or 0501; use its start
            y = (y - 1) // 100 * 100 + 1 if y % 100 else y - 99
        pid = by_qid.get(qid)
        if pid is not None:
            years[pid] = min(years.get(pid, y), y)
    # Where Wikidata dates the making elsewhere, the year it stood here.
    sources = {}
    overrides = json.loads(OVERRIDES.read_text(encoding='utf-8'))
    for o in overrides['overrides']:
        if o['place'] not in by_qid.values():
            raise SystemExit(f'override for unknown place {o["place"]}')
        years[o['place']] = o['year']
        sources[o['place']] = o['source']
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({'schemaVersion': 1, 'kind': 'atlas-place-years',
                               'source': 'wikidata-inception',
                               'places': dict(sorted(years.items())),
                               'overrides': dict(sorted(sources.items()))},
                              ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'{len(years)} of {len(by_qid)} places have an inception year')


if __name__ == '__main__':
    if '--fetch' in sys.argv:
        fetch()
    build()
