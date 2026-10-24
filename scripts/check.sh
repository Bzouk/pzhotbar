#!/usr/bin/env bash
# Static check of the mod's Lua against the Umbrella typings (see .luarc.json).
# Needs lua-language-server on PATH and Umbrella in ~/.local/share/umbrella.
set -euo pipefail
cd "$(dirname "$0")/.."
log=$(mktemp -d)
trap 'rm -rf "$log"' EXIT
lua-language-server --check=. --checklevel=Warning --check_format=json \
    --check_out_path="$log/check.json" --logpath="$log" >/dev/null || true  # exits non-zero when it finds problems
python3 - "$log/check.json" <<'PY'
import json, os, sys
path = sys.argv[1]
data = json.load(open(path)) if os.path.getsize(path) else {}
problems = sorted(
    (uri.split("/src/", 1)[-1], d["range"]["start"]["line"] + 1, d["code"], d["message"].splitlines()[0])
    for uri, diags in data.items() for d in diags
)
for file, line, code, msg in problems:
    print(f"src/{file}:{line}: {code}: {msg}")
print(f"{len(problems)} problems")
sys.exit(1 if problems else 0)
PY
