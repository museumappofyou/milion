#!/bin/sh
# Local Android builds: per-ABI APKs for device installs, AAB as the release artifact.
set -e
cd "$(dirname "$0")/.."
flutter build apk --release --split-per-abi "$@"
flutter build appbundle --release "$@"
