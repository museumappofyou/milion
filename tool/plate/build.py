"""Usage: python3.11 tool/plate/build.py studio/plates/<id>/plate.yaml [...]
       python3.11 tool/plate/build.py --all [--no-preview]

The P07 plate production line: one photograph and one plate.yaml in, a
validated PlatePlayer manifest out. Stages, each documented in its module:

  (a) stages/ingest.py   sRGB master <= 4096 px, EXIF stripped, hashes
  (b) stages/segment.py  SAM 2.1 prompts from the yaml; manual masks override
  (c) stages/depth.py    monocular depth + per-segment priors, normals, gold
  (d) stages/popup.py    optional pop-up split with inpainting
  (e) stages/mesh.py     adaptive mesh <= 60k vertices, flip/tear validated
  (f) stages/export.py   WebP maps, manifest, Milestone record, report;
                         the 6 s preview MP4 comes from a headless Flutter
                         test (tool/captures/plate_preview_test.dart)

There is no scene-specific code: Milestones I and II rebuild from their
yaml files with P06's authored maps as provided inputs. The build exits
non-zero when any validation fails. Run `dart run tool/content/validate.dart`
afterwards for the registry-wide checks.
"""
import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from stages import depth, export, ingest, mesh, popup, segment, spec as specs  # noqa: E402
from stages.spec import ROOT  # noqa: E402


def preview(m, out):
    """Six seconds of the reveal, rendered by the real PlatePlayer."""
    frames = Path(tempfile.mkdtemp(prefix='milion-preview-'))
    cmd = ['flutter', 'test', 'tool/captures/plate_preview_test.dart',
           f'--dart-define=PLATE={m["manifestPath"]}', f'--dart-define=FRAMES={frames}']
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if result.returncode:
        raise SystemExit(f'preview failed:\n{result.stdout[-2000:]}{result.stderr[-2000:]}')
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '24', '-i',
                    str(frames / '%04d.png'), '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
                    '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2', str(out)], check=True)
    count = len(list(frames.glob('*.png')))
    shutil.rmtree(frames)
    return dict(path=str(out.relative_to(ROOT)), frames=count, seconds=round(count / 24, 3))


def build(path, with_preview=True):
    t0 = time.perf_counter()
    spec = specs.load(path)
    report = dict(plate=spec.id, spec=str(spec.path.relative_to(ROOT)),
                  manualMinutes=spec.manualMinutes, stages={})
    master, master_bytes, rec = ingest.ingest(spec)
    report['stages']['ingest'] = rec
    if rec['method'] != 'kept in place':
        spec.out.mkdir(parents=True, exist_ok=True)
        (ROOT / rec['master']).write_bytes(master_bytes)
    master_sha = rec['masterSha256']
    masks, rec = segment.segment(spec, master, master_sha)
    report['stages']['segment'] = rec or 'no segments'
    height, normals, gold, rec = depth.run(spec, master, master_sha, masks)
    report['stages']['depth'] = rec
    background, layers, rec = popup.split(master, masks, spec.get('popup', []))
    if layers:
        out = spec.build / 'popup'
        export.webp(out / 'background.webp', background)
        for name, _, rgba in layers:
            export.webp(out / f'{name}.webp', rgba)
    report['stages']['popup'] = rec or 'not used'
    vertices, tri, rec = mesh.build(height, spec.get('mesh', {}).get('maxVertices', 60000))
    spec.build.mkdir(parents=True, exist_ok=True)
    (spec.build / 'mesh.bin').write_bytes(vertices.astype('<f4').tobytes() + tri.astype('<u4').tobytes())
    report['stages']['mesh'] = rec
    provided = spec.get('depth', {}).get('provided')
    maps = dict(size=[master.shape[1], master.shape[0]])
    if provided:
        maps['surface'] = provided
    else:
        maps['surface'] = spec.asset('surface.webp')
        export.webp(ROOT / maps['surface'], export.surface_rgba(height, normals))
    if spec.get('gold', {}).get('provided'):
        maps['gold'] = spec.gold['provided']
    else:
        maps['gold'] = spec.asset('gold.webp')
        export.webp(ROOT / maps['gold'], export.gray_rgb(gold))
    lookup = spec.get('lookUp')
    if lookup:
        lookup = {k: lookup[k] for k in ['center', 'rimCenter', 'rimRadii', 'rimElevation']}
        export.lookup_overlay(master, lookup, spec.build / 'lookup-overlay.jpg')
    m = export.manifest(spec, report['stages']['ingest']['master'], maps, lookup)
    export.write_json(ROOT / m['manifestPath'], m)
    export.update_milestone(m)
    images = {l['asset'] for l in m['layers']} | {l['mask'] for l in m['layers'] if l['mask']}
    images |= {m['maps']['surface'], m['maps']['gold']}
    images |= {x['mask'] for x in [m['flow'], m['spiral']] if x}
    budget = export.texture_bytes(sorted(images))
    report['budgets'] = dict(decodedTextureBytes=budget, textureBudget=export.TEXTURE_BUDGET,
                             meshVertices=report['stages']['mesh']['vertices'], meshBudget=60000)
    report['outputs'] = dict(manifest=m['manifestPath'], maps=m['maps'],
                             details=len(m['details']), beats=len(m['beats']),
                             storySeconds=m['storySeconds'], revealMoment=m['revealMoment'],
                             lookUp=m['lookUp'])
    problems = list(report['stages']['mesh']['problems'])
    if budget > export.TEXTURE_BUDGET:
        problems.append('texture budget exceeded')
    if len(m['details']) < 5:
        problems.append('fewer than five leader-line details')
    if with_preview:
        report['preview'] = preview(m, spec.build / 'preview.mp4')
    report['valid'] = not problems
    report['problems'] = problems
    report['buildSeconds'] = round(time.perf_counter() - t0, 1)
    export.write_json(spec.build / 'report.json', report)
    status = 'VALID' if not problems else 'INVALID: ' + '; '.join(problems)
    print(f'{spec.id}: {status} · {len(m["details"])} details · {len(m["beats"])} beats · '
          f'{m["storySeconds"]} s · mesh {report["stages"]["mesh"]["vertices"]} v · '
          f'textures {budget:,} B')
    return not problems


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('specs', nargs='*')
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--no-preview', action='store_true')
    args = ap.parse_args()
    paths = sorted((ROOT / 'studio/plates').glob('*/plate.yaml')) if args.all else args.specs
    if not paths:
        ap.error('give plate.yaml paths or --all')
    ok = all([build(p, not args.no_preview) for p in paths])
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
