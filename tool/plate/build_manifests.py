"""Build P06's two plate manifests from the P04 detail pool, offline.

Usage: python3 tool/plate/build_manifests.py
The image grid, detail windows, anchors, sentences and sources are preserved.
The existing figure rig supplies one gentle, spatially limited story beat.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/plates'


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def rect(left=0, top=0, right=1, bottom=1):
    return dict(left=left, top=top, right=right, bottom=bottom)


def build():
    details = json.loads((ROOT / 'assets/content/details/chora.json').read_text())['records']
    by_id = {d['id']: d for d in details}
    sources = {}
    for path in (ROOT / 'assets/content').rglob('*.json'):
        doc = json.loads(path.read_text())
        if doc.get('kind') == 'sources':
            sources.update({s['id']: s for s in doc['records']})
    for folder, artwork, title, size, original, relief, restored, geometry, figures, beats in [
        ('anastasis', 'F02', dict(en='Anastasis', tr='Anastasis'), [2048, 1091],
         'assets/anastasis/conch_reference.jpg',
         'assets/anastasis/relief_v5/relief_front.jpg',
         'assets/restoration/anastasis_restored_4k_v2.jpg',
         'assets/explorer/anastasis_geometry.json',
         'assets/explorer/anastasis_figures_v2.json',
         [('detail-mandorla-stars', 7, 'gilded'),
          ('detail-adam-wrist', 8, 'none'),
          ('detail-eve-wrist', 7, 'none'),
          ('detail-gates-of-hell', 5, 'raking'),
          ('detail-anastasis-title', 5, 'gilded')]),
        ('judgment', 'F05', dict(en='The Last Judgment', tr='Son Yargı'), [1600, 1067],
         'assets/last_judgment/vault_reference.jpg',
         'assets/last_judgment/relief_v5/relief_front.jpg',
         'assets/restoration/last_judgment_restored_4k_v2.jpg',
         'assets/explorer/last_judgment_geometry.json',
         'assets/explorer/last_judgment_figures_v2.json',
         [('detail-deesis', 8, 'gilded'),
          ('detail-scroll-of-heaven', 8, 'none'),
          ('detail-river-of-fire', 8, 'none'),
          ('detail-prepared-throne', 8, 'raking')]),
    ]:
        milestone = 'milestone-i' if artwork == 'F02' else 'milestone-ii'
        base = f'assets/plates/{folder}'
        path = base + '/manifest.json'
        script = []
        cursor = 0
        for detail_id, duration, light in beats:
            d = by_id[detail_id]
            gesture = None
            if detail_id == 'detail-adam-wrist':
                gesture = dict(start=cursor + 3, duration=1.2, strength=.25,
                               windows=[rect(.29, .48, .46, .70), rect(.55, .48, .67, .70)])
            window = rect(.25, .28, .77, .87) if gesture else d['window']
            script.append(dict(id=f'{folder}-beat-{len(script)+1}', start=cursor,
                               duration=duration, detail=detail_id, window=window,
                               caption=d['sentence'], sources=d['sources'], light=light,
                               flow=detail_id == 'detail-river-of-fire',
                               spiral=detail_id == 'detail-scroll-of-heaven',
                               gesture=gesture))
            cursor += duration
        credit = (dict(en='The source page of this photograph was not recorded.',
                       tr='Bu fotoğrafın kaynak sayfası kaydedilmemiş.')
                  if artwork == 'F02' else
                  dict(en='Caner Cangül / Kültür Envanteri', tr='Caner Cangül / Kültür Envanteri'))
        manifest = dict(schemaVersion=1, kind='plate', id='plate-' + folder,
                        milestone=milestone, artwork=artwork, title=title,
                        size=size, manifestPath=path,
                        layers=[dict(id='original', asset=original, honesty='ORIGINAL', mask=None),
                                dict(id='depth', asset=relief, honesty='DEPTH', mask=None),
                                dict(id='reconstruction', asset=restored,
                                     honesty='RECONSTRUCTION', mask=base + '/damaged.png')],
                        maps=dict(surface=base + '/surface.png', gold=base + '/gold.png',
                                  flow=base + '/river.png' if artwork == 'F05' else None,
                                  scroll=base + '/scroll.png' if artwork == 'F05' else None),
                        mesh=dict(geometry=geometry, figures=figures, maxVertices=60000),
                        details=[d for d in details if d['milestone'] == milestone],
                        beats=script, revealSeconds=10, storySeconds=cursor,
                        reveal=dict(id=folder+'-reveal', start=0, duration=10,
                                    detail=beats[0][0], window=by_id[beats[0][0]]['window'],
                                    caption=by_id[beats[0][0]]['sentence'],
                                    sources=by_id[beats[0][0]]['sources'], light='gilded',
                                    flow=artwork=='F05', spiral=artwork=='F05', gesture=None),
                        credit=credit, sources=['chora-guide-parekklesion', 'ousterhout-2002'],
                        originalSourceUrl=None if artwork == 'F02' else
                        'https://cdn.kulturenvanteri.com/wp-content/uploads/2024/05/Mahser.jpg',
                        scrollCenter=[.508, .395])
        refs = set(manifest['sources'])
        for d in manifest['details']:
            refs.update(d['sources'])
        manifest['citations'] = [sources[id] for id in sorted(refs)]
        write(ROOT / path, manifest)
    seed = ROOT / 'assets/content/milestones/chora.json'
    document = json.loads(seed.read_text())
    for m in document['records']:
        folder = {'milestone-i': 'anastasis', 'milestone-ii': 'judgment'}.get(m['id'])
        if folder:
            m['manifestPath'] = f'assets/plates/{folder}/manifest.json'
        # Updating paths must preserve review status and later Milestones.
    write(seed, document)
    print('P06: two manifest-driven prototypes; 17 detail anchors preserved; 32 s stories.')


if __name__ == '__main__':
    build()
