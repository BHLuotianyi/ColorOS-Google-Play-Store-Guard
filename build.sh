#!/bin/sh
set -eu
cd "$(dirname "$0")"

NAME=ColorOS-Google-Play-Store-Guard
VER=$(sed -n 's/^version=//p' module.prop)
OUT="dist/${NAME}-v${VER}.zip"

mkdir -p dist
rm -f "$OUT"
zip -qr "$OUT" . \
    -x 'dist/*' \
    -x '.git/*' \
    -x '.github/*' \
    -x 'build.sh' \
    -x 'module.yaml'

echo "$OUT"
sha256sum "$OUT" 2>/dev/null || true
