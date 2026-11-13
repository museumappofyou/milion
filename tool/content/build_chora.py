"""Usage: python3.11 tool/content/build_chora.py

P11, Chora complete. Builds Chora's chapter from the authored inputs in
studio/chora/:

  artworks/*.json   the 103 artworks completed room by room (EN+TR titles,
                    three look-fors, story, inscriptions where known,
                    condition, sources, and the evidence behind them)
  guide.json        the plan (rooms, domes and vaults in metres), where each
                    artwork sits on it, and the guided cycles
  hunt.json         the Chora hunt: eight things to find in the building
  building.json     the building campaigns and dimensions (Milestone VI)
  review.json       Chora's review: entrance, status and current function

into:

  assets/content/artworks/chora.json   every id kept, completed in place
  assets/content/guides/chora.json     the plan and cycles
  assets/content/hunts.json            the hunt (for P21) and its route
  assets/content/routes.json
  assets/content/sources/chora.json    the sources the above add
  assets/content/places/istanbul.json  Chora promoted to reviewed
  assets/content/milestones/register.json  Milestone VI linked to its study

Evidence (quotes and locators) stays in studio/chora/; it is not shipped.
Run after build_dig.py (tool/content/rebuild.py does).
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import chora_plan  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
STUDIO = ROOT / 'studio/chora'

# Fields a draft replaces; place, kind, folder and media stay as recorded.
REPLACED = ['title', 'room', 'surface', 'position', 'summary', 'cues']
ADDED = ['lookFor', 'story', 'inscriptions', 'condition']


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def merge_sources(groups):
    merged = {}
    for origin, records in groups:
        for s in records:
            old = merged.get(s['id'])
            if old is not None and old[1] != s:
                # The same id from two drafts must describe the same thing.
                if (old[1]['url'], old[1]['title']['en']) != (s['url'], s['title']['en']):
                    raise SystemExit(f'source {s["id"]} differs between {old[0]} and {origin}')
                continue
            merged[s['id']] = (origin, s)
    return [s for _, s in merged.values()]


def artworks(existing_sources):
    path = CONTENT / 'artworks/chora.json'
    doc = read(path)
    by_id = {r['id']: r for r in doc['records']}
    seen, groups = {}, []
    for draft_path in sorted((STUDIO / 'artworks').glob('*.json')):
        draft = read(draft_path)
        groups.append((draft_path.name, draft.get('sources', [])))
        for r in draft['records']:
            if r['id'] not in by_id:
                raise SystemExit(f'{draft_path.name}: unknown artwork {r["id"]}')
            if r['id'] in seen:
                raise SystemExit(f'{r["id"]} in both {seen[r["id"]]} and {draft_path.name}')
            seen[r['id']] = draft_path.name
            record = by_id[r['id']]
            for k in REPLACED + ADDED:
                record[k] = r[k]
            record['sources'] = list(dict.fromkeys(r['sources']))
    missing = sorted(set(by_id) - set(seen))
    if missing:
        raise SystemExit(f'artworks without a draft: {missing}')
    # Keep the record's key order stable: the original fields, then P11's.
    order = ['id', 'place', 'title', 'room', 'surface', 'position', 'kind', 'summary', 'cues',
             'lookFor', 'story', 'inscriptions', 'condition', 'folder', 'sources', 'media']
    doc['records'] = [{k: r[k] for k in order if k in r} for r in doc['records']]
    write(path, doc)
    return groups, len(seen)


def main():
    existing = set()
    for f in [CONTENT / 'sources.json', *(CONTENT / 'sources').glob('*.json')]:
        if f.name != 'chora.json':
            existing |= {r['id'] for r in read(f)['records']}

    groups, count = artworks(existing)

    authored = read(STUDIO / 'guide.json')
    groups.append(('guide.json', authored.get('newSources', [])))
    guide = dict(
        id=authored['id'], place=authored['place'], axisDeg=chora_plan.AXIS_DEG,
        rooms=[dict(id=r['id'], name=r['name'], outline=[list(p) for p in r['outline']],
                    label=list(r['label'])) for r in chora_plan.rooms()],
        vaults=chora_plan.vaults(),
        anchors=authored['anchors'], cycles=authored['cycles'], sources=authored['sources'])
    write(CONTENT / 'guides/chora.json', dict(schemaVersion=1, kind='guides', records=[guide]))

    hunt = read(STUDIO / 'hunt.json')
    groups.append(('hunt.json', hunt.get('sources', [])))
    record = dict(
        id='chora-hunt', title=hunt['title'], route='chora-visit',
        clues=[item['clue'] for item in hunt['items']],
        artworks=sorted({a for item in hunt['items'] for a in item.get('artworkIds', [])}),
        sources=sorted({s for item in hunt['items'] for s in item['sources']}),
        items=[dict(id=item['id'], room=item['room'], title=item['title'], clue=item['clue'],
                    answer=item['answer'], artworks=item.get('artworkIds', []),
                    sources=item['sources']) for item in hunt['items']],
    )
    write(CONTENT / 'hunts.json', dict(schemaVersion=1, kind='hunts', records=[record]))
    write(CONTENT / 'routes.json', dict(schemaVersion=1, kind='routes', records=[hunt['route']]))

    building = STUDIO / 'building.json'
    if building.exists():
        groups.append(('building.json', read(building).get('sources', [])))

    review = read(STUDIO / 'review.json')
    groups.append(('review.json', review.pop('newSources', [])))

    sources = [s for s in merge_sources(groups) if s['id'] not in existing]
    write(CONTENT / 'sources/chora.json', dict(schemaVersion=1, kind='sources', records=sources))

    places = read(CONTENT / 'places/istanbul.json')
    chora = next(r for r in places['records'] if r['id'] == 'chora')
    for k in ('entrance', 'status', 'currentFunction', 'review'):
        chora[k] = review[k]
    chora['tags'] = list(dict.fromkeys([t for t in chora['tags'] if t != 'entrance-unverified'] + review['tags']))
    chora['sources'] = list(dict.fromkeys(chora['sources'] + review['sources']))
    write(CONTENT / 'places/istanbul.json', places)

    # Milestone VI plays the kit study of Chora through time (P11).
    register_path = CONTENT / 'milestones/register.json'
    register = read(register_path)
    vi = next(m for m in register['records'] if m['id'] == 'milestone-vi')
    vi.update(status='prototype', manifestPath='assets/space/kariye-camii/study.json',
              honesty=['ORIGINAL', 'RECONSTRUCTION'])
    vi['sources'] = list(dict.fromkeys(vi['sources'] + ['van-millingen-1912', 'ousterhout-introduction',
                                                         'wp-the-chora-1381788152']))
    write(register_path, register)

    index_path = CONTENT / 'index.json'
    index = read(index_path)
    rel = 'assets/content/sources/chora.json'
    if rel not in index['files']['sources']:
        index['files']['sources'].append(rel)
    write(index_path, index)
    print(f'chora: {count} artworks, {len(guide["cycles"])} cycles, '
          f'{len(hunt["items"])} hunt items, {len(sources)} new sources')


if __name__ == '__main__':
    main()
