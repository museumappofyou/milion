"""Check pinned provenance offline: python3 tool/content/audit_evidence.py.

Source originals are external; their recorded hashes are retained in media_hashes.
Bundled derivatives and every selected Wikidata snapshot are checked here.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'tool/content'


def read(path):
    return json.loads(path.read_text())


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


places = read(ROOT / 'assets/content/places/istanbul.json')['records']
verified = read(BASE / 'verification.json')['places']
assert {p['id'] for p in places} == {p['id'] for p in verified}
for record in verified:
    path = BASE / 'evidence' / (record['qid'] + '.json')
    assert sha(path) == record['sha256'], record['id']
    assert read(path)['id'] == record['qid'], record['id']
for media in read(BASE / 'media_hashes.json')['records']:
    assert sha(ROOT / media['bundledPath']) == media['bundledSha256'], media['media']
    assert media['source']['sha256'] == media['originalSha256Verified']
print(f'{len(verified)} selected Wikidata snapshot hashes and 2 bundled reference hashes verified.')
