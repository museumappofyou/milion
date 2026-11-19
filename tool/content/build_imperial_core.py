"""Usage: python3.11 tool/content/build_imperial_core.py

P13, the imperial core: the Hippodrome, the Great Palace, the Column of
Constantine, the Boukoleon and the Milion. Builds the chapter from the
authored inputs in studio/imperial-core/ (the same shapes as P12's
studio/hagia-sophia/, but for several places):

  sources.json     the sources P13 cites (dig, artworks, Milestones, studies)
  places.json      per place: the dig's dated strata (newest first, each
                   sourced) and the review (entrance, status, function,
                   hook, visit card, tags, sources)
  artworks.json    the things to look at closely (EN+TR, three look-fors,
                   story, inscriptions, condition, sources)
  media.json       the photographs (Wikimedia Commons; licence, author and
                   the hashes of the bytes fetched and of the master kept)
  details.json     the Detail-of-the-day pool's entries for XIII and XV,
                   placed on their plates' master photographs
  milestones.json  0 and XII–XV: places, artworks and sources; the studies'
                   path, status and honesty (0, XII, XIV; the plates own
                   XIII's and XV's)

into:

  assets/content/sources/imperial-core.json
  assets/content/places/istanbul.json      the places' strata, visit, review
  assets/content/artworks/imperial-core.json
  assets/content/details/imperial-core.json
  assets/content/media.json                the photographs added, by id
  assets/content/milestones/register.json  0 and XII–XV completed
  assets/content/index.json                the new documents registered

Run after build_dig.py and before the plates and the kit
(tool/content/rebuild.py does): the plates read the details, and the kit's
studies of the Milion, the Hippodrome and the Serpent Column cite these
sources.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
STUDIO = ROOT / 'studio/imperial-core'
CHAPTER = 'imperial-core'
PLACES = {'hippodrome', 'great-palace-mosaic-museum', 'column-of-constantine', 'milion',
          'boukoleon', 'obelisk-of-theodosius', 'serpent-column', 'walled-obelisk', 'great-palace'}
# The Milestones whose manifest is a kit study, which this chapter owns (the
# plates own XIII's and XV's path, status and honesty).
STUDIES = {'milestone-0', 'milestone-xii', 'milestone-xiv'}


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
    rel = f'assets/content/sources/{CHAPTER}.json'
    # A source another document already registers is cited, not repeated.
    for other in read(CONTENT / 'index.json')['files']['sources']:
        if other != rel and (ROOT / other).exists():
            taken = {r['id'] for r in read(ROOT / other)['records']} & set(ids)
            if taken:
                raise SystemExit(f'{sorted(taken)} already in {other}; cite them instead')
    write(ROOT / rel, document('sources', records))
    register('sources', rel)
    return set(ids)


def media():
    added = authored('media.json', {'records': []})['records']
    path = CONTENT / 'media.json'
    doc = read(path)
    by_id = {m['id']: m for m in doc['records']}
    for m in added:
        by_id[m['id']] = {k: m[k] for k in ['id', 'path', 'kind', 'credit', 'source', 'era',
                                            'historicalPhoto']}
    doc['records'] = list(by_id.values())
    write(path, doc)


def artworks():
    draft = authored('artworks.json')
    if draft is None:
        return
    for r in draft['records']:
        if r['place'] not in PLACES:
            raise SystemExit(f'{r["id"]}: not a place of this chapter')
    rel = f'assets/content/artworks/{CHAPTER}.json'
    write(ROOT / rel, document('artworks', draft['records']))
    register('artworks', rel)


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
    rel = f'assets/content/details/{CHAPTER}.json'
    write(ROOT / rel, document('details', interleave(draft['records'])))
    register('details', rel)


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
        if 'manifestPath' in patch:
            if patch['id'] not in STUDIES:
                raise SystemExit(f'{patch["id"]}: a plate owns this path')
            record['manifestPath'] = patch['manifestPath']
            record['honesty'] = patch['honesty']
            if record['status'] == 'planned':
                record['status'] = patch['status']
    write(path, doc)


def places():
    draft = authored('places.json')
    if draft is None:
        return
    path = CONTENT / 'places/istanbul.json'
    doc = read(path)
    by_id = {r['id']: r for r in doc['records']}
    for entry in draft['records']:
        if entry['id'] not in PLACES:
            raise SystemExit(f'{entry["id"]}: not a place of this chapter')
        record = by_id[entry['id']]
        if 'strata' in entry:
            record['strata'] = entry['strata']
        review = entry.get('review')
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
    places()


if __name__ == '__main__':
    main()
