"""Fetch public Wikidata evidence: python3 tool/content/fetch_wikidata.py.

Search candidates are saved for human selection, never silently accepted.
Use seed_selection.json to pin reviewed QIDs; fetches are cached and resumable.
"""
import csv
import json
import pathlib
import urllib.parse
import urllib.request
import urllib.error
import time
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = pathlib.Path(__file__).resolve().parents[2]
CACHE = ROOT / 'tool/content/evidence'
CACHE.mkdir(exist_ok=True)
ROWS = list(csv.DictReader((ROOT / 'tool/content/seed_places.tsv').open(), delimiter='\t'))


def fetch(url, path):
    if path.exists():
        return json.loads(path.read_text())
    request = urllib.request.Request(url, headers={'User-Agent': 'MilionContentAudit/1.0 (private Istanbul heritage registry)'})
    for attempt in range(6):
        time.sleep(2)
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                data = json.load(response)
            break
        except urllib.error.HTTPError as error:
            if error.code not in (429, 502, 503) or attempt == 5:
                raise
            time.sleep(min(10 * 2 ** attempt, 60))
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    return data


def search(row):
    query = urllib.parse.urlencode(dict(action='wbsearchentities', search=row['query'], language='en', format='json', limit=5))
    try:
        data = fetch('https://www.wikidata.org/w/api.php?' + query, CACHE / (row['id'] + '-search.json'))
        print(row['id'], [(x['id'], x.get('label'), x.get('description')) for x in data['search']], flush=True)
    except Exception as e:
        print(row['id'], 'ERROR', str(e), flush=True)


if __name__ == '__main__':
    selection = ROOT / 'tool/content/seed_selection.json'
    if not selection.exists() or '--search' in sys.argv:
        with ThreadPoolExecutor(max_workers=1) as pool:
            list(pool.map(search, ROWS))
    else:
        selected = json.loads(selection.read_text())
        missing = [qid for qid in selected.values() if not (CACHE / (qid + '.json')).exists()]
        if '--direct' in sys.argv:
            for qid in missing:
                data = fetch(f'https://www.wikidata.org/wiki/Special:EntityData/{qid}.json', CACHE / (qid + '-export.json'))
                (CACHE / (qid + '.json')).write_text(json.dumps(data['entities'][qid], ensure_ascii=False, indent=2) + '\n')
                (CACHE / (qid + '-export.json')).unlink()
                print('Fetched', qid, flush=True)
            missing = []
        for start in range(0, len(missing), 40):
            qids = missing[start:start + 40]
            query = urllib.parse.urlencode(dict(action='wbgetentities', ids='|'.join(qids), languages='en|tr|el', props='labels|descriptions|claims|info', format='json'))
            batch_path = CACHE / ('batch-' + qids[0] + '.json')
            data = fetch('https://www.wikidata.org/w/api.php?' + query, batch_path)
            for qid, record in data['entities'].items():
                (CACHE / (qid + '.json')).write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
            batch_path.unlink()
        for key, qid in selected.items():
            record = json.loads((CACHE / (qid + '.json')).read_text())
            claims = record.get('claims', {})
            def values(prop):
                return [c['mainsnak'].get('datavalue', {}).get('value') for c in claims.get(prop, [])]
            print(key, qid, record.get('labels', {}).get('en'), 'coordinate=', values('P625'), 'admin=', values('P131'), 'type=', values('P31'), flush=True)
