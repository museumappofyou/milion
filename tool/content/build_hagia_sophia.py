"""Usage: python3.11 tool/content/build_hagia_sophia.py

P12, Hagia Sophia. Builds the chapter from the authored inputs in
studio/hagia-sophia/:

  sources.json     the sources P12 cites (dig, artworks, Milestones, study)
  layers.json      the dig: dated strata, newest first, each sourced
  artworks.json    the things to look at closely (EN+TR, three look-fors,
                   story, inscriptions, condition, sources)
  media.json       the photographs (Wikimedia Commons; licence, author and
                   the hashes of the bytes fetched and of the master kept)
  details.json     the Detail-of-the-day pool's entries for VII, VIII and X,
                   placed on their plates' master photographs
  milestones.json  VII–X: artworks and sources; IX's study path, status and
                   honesty (the plates own VII, VIII and X's)
  review.json      the review: entrance, status, current function, visit card

into:

  assets/content/sources/hagia-sophia.json
  assets/content/places/istanbul.json      Hagia Sophia's strata, visit, review
  assets/content/artworks/hagia-sophia.json
  assets/content/details/hagia-sophia.json
  assets/content/media.json                the photographs added, by id
  assets/content/milestones/register.json  VII–X completed
  assets/content/index.json                the new documents registered

Run after build_dig.py and before the plates and the kit
(tool/content/rebuild.py does): the plates read the details, and the kit's
Hagia Sophia study cites these sources.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
STUDIO = ROOT / 'studio/hagia-sophia'
PLACE = 'hagia-sophia'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def authored(name, default=None):
    path = STUDIO / name
    return read(path) if path.exists() else default


def register(kind, rel):
    index_path = CONTENT / 'index.json'
    index = read(index_path)
    files = index['files'][kind]
    if rel not in files:
        files.append(rel)
        write(index_path, index)


def document(kind, records):
    return dict(schemaVersion=1, kind=kind, records=records)


def sources():
    records = authored('sources.json')['records']
    ids = [r['id'] for r in records]
    if len(ids) != len(set(ids)):
        raise SystemExit('sources.json repeats an id')
    write(CONTENT / 'sources/hagia-sophia.json', document('sources', records))
    register('sources', 'assets/content/sources/hagia-sophia.json')
    return set(ids)


def media():
    added = authored('media.json', {'records': []})['records']
    path = CONTENT / 'media.json'
    doc = read(path)
    by_id = {m['id']: m for m in doc['records']}
    for m in added:
        record = {k: m[k] for k in ['id', 'path', 'kind', 'credit', 'source', 'era', 'historicalPhoto']}
        by_id[m['id']] = record
    doc['records'] = list(by_id.values())
    write(path, doc)


def artworks():
    draft = authored('artworks.json')
    if draft is None:
        return
    for r in draft['records']:
        if r['place'] != PLACE:
            raise SystemExit(f'{r["id"]}: not a Hagia Sophia artwork')
    write(CONTENT / 'artworks/hagia-sophia.json', document('artworks', draft['records']))
    register('artworks', 'assets/content/artworks/hagia-sophia.json')


def interleave(records):
    """Round-robin by artwork, so consecutive days change plate (P04's rule)."""
    groups = {}
    for r in records:
        groups.setdefault(r['artwork'], []).append(r)
    out = []
    while any(groups.values()):
        for queue in groups.values():
            if queue:
                out.append(queue.pop(0))
    for a, b in zip(out, out[1:]):
        if a['artwork'] == b['artwork']:
            raise SystemExit(f'{b["id"]}: two details of one artwork in a row')
    return out


def details():
    draft = authored('details.json')
    if draft is None:
        return
    write(CONTENT / 'details/hagia-sophia.json', document('details', interleave(draft['records'])))
    register('details', 'assets/content/details/hagia-sophia.json')


def milestones():
    draft = authored('milestones.json')
    if draft is None:
        return
    path = CONTENT / 'milestones/register.json'
    doc = read(path)
    by_id = {r['id']: r for r in doc['records']}
    for patch in draft['records']:
        record = by_id.get(patch['id'])
        if record is None:
            raise SystemExit(f'{patch["id"]}: not in the register')
        for key in ['artworks', 'places', 'sources', 'techniques']:
            if key in patch:
                record[key] = patch[key]
        # IX is a study, not a plate, so this chapter owns its path, status
        # and honesty (the plates own theirs, as for Chora's VI).
        if 'manifestPath' in patch:
            if patch['id'] != 'milestone-ix':
                raise SystemExit(f'{patch["id"]}: a plate owns this path')
            record['manifestPath'] = patch['manifestPath']
            record['honesty'] = patch['honesty']
            if record['status'] == 'planned':
                record['status'] = patch['status']
    write(path, doc)


def place():
    layers = authored('layers.json')
    review = authored('review.json')
    path = CONTENT / 'places/istanbul.json'
    doc = read(path)
    record = next(r for r in doc['records'] if r['id'] == PLACE)
    if layers is not None:
        record['strata'] = layers['records']
    if review is not None:
        for key in ['review', 'entrance', 'status', 'currentFunction', 'hook', 'visit']:
            if key in review:
                record[key] = review[key]
        record['tags'] = [t for t in record['tags'] if t != 'entrance-unverified'] + [
            t for t in review.get('tags', []) if t not in record['tags']]
        record['sources'] = list(dict.fromkeys(record['sources'] + review.get('sources', [])))
    write(path, doc)


def main():
    sources()
    media()
    artworks()
    details()
    milestones()
    place()


if __name__ == '__main__':
    main()
