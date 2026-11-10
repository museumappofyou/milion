"""Usage: python3.11 tool/atlas/fetch_osm.py [name ...]

Downloads the pinned Overpass queries (tool/atlas/osm_queries.py) into
studio/cache/atlas/raw/<name>.json, one at a time with a pause between them
(the public server rate-limits). With no names, fetches every query that has
no raw file yet. build_atlas.py records each file's osm_base and SHA-256.
"""
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from osm_queries import ENDPOINTS, QUERIES, USER_AGENT  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'studio/cache/atlas/raw'


def fetch(name, endpoint):
    RAW.mkdir(parents=True, exist_ok=True)
    body = urllib.parse.urlencode({'data': QUERIES[name]}).encode()
    request = urllib.request.Request(endpoint, body, headers={'User-Agent': USER_AGENT})
    started = time.time()
    with urllib.request.urlopen(request, timeout=900) as response:
        data = response.read()
    if b'"elements"' not in data[:4000] and b'runtime error' in data:
        raise SystemExit(f'{name}: Overpass error: {data[:400]!r}')
    tmp = RAW / f'{name}.json.part'
    tmp.write_bytes(data)
    tmp.rename(RAW / f'{name}.json')
    (RAW / f'{name}.endpoint').write_text(endpoint + '\n')
    print(f'{name}: {len(data):,} bytes in {time.time() - started:.0f} s from {endpoint}', flush=True)


def main(names, attempts=8):
    todo = names or [n for n in QUERIES if not (RAW / f'{n}.json').exists()]
    failed = []
    for i, name in enumerate(todo):
        if i:
            time.sleep(20)
        for attempt in range(attempts):
            try:
                fetch(name, ENDPOINTS[attempt % len(ENDPOINTS)])
                break
            except Exception as e:  # network or 429/502/504: wait and retry
                print(f'{name}: attempt {attempt + 1} failed: {e}', flush=True)
                time.sleep(min(60 * (attempt + 1), 300))
        else:
            print(f'{name}: giving up after {attempts} attempts', flush=True)
            failed.append(name)
    if failed:
        raise SystemExit(f'not fetched: {" ".join(failed)}')


if __name__ == '__main__':
    main(sys.argv[1:])
