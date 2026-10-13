"""Usage: python3.11 tool/content/rebuild.py — regenerate P02–P08 authored content.

Run the seed, register, daily-detail and dig builders in dependency order, then
the P07 plate pipeline for every studio/plates/*/plate.yaml (without previews;
`tool/plate/build.py <yaml>` renders those). The plate step must follow the
register, because each plate owns its Milestone's path, status and honesty.
The P08 study "How a dome stands" follows (model, manifest and its sources).
The migrated Chora catalogue and source photographs are kept untouched.
Validate afterwards with `dart run tool/content/validate.dart`.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    for name in ['build_seed.py', 'build_register.py', 'build_details.py', 'build_dig.py']:
        subprocess.run([sys.executable, str(ROOT / 'tool/content' / name)],
                       cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'tool/plate/build.py'), '--all', '--no-preview'],
                   cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'tool/space/how_a_dome_stands.py')],
                   cwd=ROOT, check=True)


if __name__ == '__main__':
    main()
