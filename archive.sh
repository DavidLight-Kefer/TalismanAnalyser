#!/usr/bin/env sh

set -e

start_dir="$(pwd)"

[ $# -lt 1 ] && echo "Usage: ./archive.sh <version>" >&2 && exit 1

# go to repo dir
cd "$(dirname "$0")"

VERSION="$1"
FOLDER_NAME="talisman_analyser_v$VERSION"

# Generate single .lua file
cd src
lua compiler.lua
cd ..

[ ! -d artefacts ] && mkdir artefacts

cd artefacts

mkdir -p tmp/reframework/autorun
mv ../src/output.lua tmp/reframework/autorun/talisman_analyser.lua

cat > tmp/modinfo.ini <<EOF
name=Talisman Analyser
version=$VERSION
description=Analyse your Appraised Talismans to find Duplicates and Obsoletes.
screenshot=screenshot.png
author=DavidLight
EOF

# Shrink image if possible
if command -v magick >/dev/null 2>&1; then
  magick ../images/screenshot.png -resize 25% tmp/screenshot.png
else
  cp ../images/screenshot.png tmp/
fi

mv tmp "$FOLDER_NAME"
[ -e "talisman_analyser.zip" ] && rm talisman_analyser.zip
zip -r talisman_analyser.zip "$FOLDER_NAME"
rm -rf "$FOLDER_NAME"

cd "$start_dir"
