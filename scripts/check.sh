#!/usr/bin/env bash
# Static check of the mod's Lua against the Umbrella typings (see .luarc.json).
# Needs lua-language-server on PATH and Umbrella in ~/.local/share/umbrella.
# Exits non-zero when it finds problems.
set -euo pipefail
cd "$(dirname "$0")/.."
log=$(mktemp -d)
trap 'rm -rf "$log"' EXIT
NO_COLOR=1 lua-language-server --check=. --checklevel=Warning --logpath="$log"
