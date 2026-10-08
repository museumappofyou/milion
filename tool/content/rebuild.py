"""Usage: python3 tool/content/rebuild.py — regenerate P02–P06 authored content.

Run the seed, register, daily-detail and dig builders in dependency order.
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
    subprocess.run([sys.executable, str(ROOT / 'tool/plate/build_manifests.py')],
                   cwd=ROOT, check=True)


if __name__ == '__main__':
    main()
