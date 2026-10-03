#!/usr/bin/env bash
# Build dist/systemglance-<version>.plasmoid from package/: the file people
# install with "Install Widget From Local File…" or kpackagetool6.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for tool in jq zip unzip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "$tool not found." >&2
        exit 1
    fi
done

VERSION="$(jq -r '.KPlugin.Version' "$ROOT/package/metadata.json")"
OUT="$ROOT/dist/systemglance-$VERSION.plasmoid"

# Stage a copy with fixed permissions and timestamps, so the same sources
# always produce the same archive.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$ROOT/package/." "$STAGE/"
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f -exec chmod 644 {} +
find "$STAGE" -exec touch -d '2026-01-01T00:00:00Z' {} +

mkdir -p "$ROOT/dist"
rm -f "$OUT"
(cd "$STAGE" && find . -type f | LC_ALL=C sort | TZ=UTC zip -X -D -q "$OUT" -@)

echo "dist/$(basename "$OUT"): $(unzip -Z1 "$OUT" | wc -l) files, $(du -k "$OUT" | cut -f1) KB"
