#!/usr/bin/env bash
# Builds the Workshop item into build/Workshop/BZQuickSlots, laid out the way
# Project Zomboid reads it from ~/Zomboid/Workshop (Build 42: only the 42/ folder).
set -euo pipefail
cd "$(dirname "$0")/.."
item=build/Workshop/BZQuickSlots
mod=$item/Contents/mods/pzhotbar42/42

rm -rf "$item"
mkdir -p "$mod"
cp -r src/. "$mod/"
cp LICENSE "$mod/LICENSE.txt"
cp assets/workshop/preview.png "$item/"

# workshop.txt: fixed keys, then one description= line per line of the description
{
    cat assets/workshop/workshop.txt
    while IFS= read -r line || [ -n "$line" ]; do
        printf 'description=%s\n' "$line"
    done < assets/workshop/description.txt
} > "$item/workshop.txt"

if grep -vnE '^(version|id|title|description|tags|visibility)=' "$item/workshop.txt"; then
    echo "workshop.txt has lines the game would not read (above)" >&2
    exit 1
fi
echo "built $item"
