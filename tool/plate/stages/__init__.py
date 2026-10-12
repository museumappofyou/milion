"""P07 plate production stages: ingest, segment, depth, popup, mesh, export.

Each stage is a pure function of its inputs (paths and arrays in, arrays and
files out) so `tool/plate/build.py` can run them in order from one plate.yaml,
with no scene-specific code. Heavy model outputs are cached under
studio/cache/plates/ keyed by input hashes and pinned model revisions.
"""
