#!/usr/bin/env sh

set -e

[ -f '.env' ] && source '.env'

cd src
lua compiler.lua
mv output.lua "$WILDS_DIR/reframework/autorun/talisman_analyser_dev.lua"
cd -

TARGET_DIR="$WILDS_DIR/reframework/images/talisman_analyser"
[ ! -d "$TARGET_DIR" ] && mkdir "$TARGET_DIR"
cp -r ./assets/images/* "$TARGET_DIR"
