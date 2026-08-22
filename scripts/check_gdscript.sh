#!/usr/bin/env bash
# GDScript format + lint check for Brew & Justice (issue #41).
#
# Usage:
#   bash scripts/check_gdscript.sh          # check only (CI mode)
#   bash scripts/check_gdscript.sh --fix    # reformat in place, then lint
#
# Requires gdtoolkit 4.x (gdformat + gdlint):
#   pip install "gdtoolkit==4.*"
# If gdformat/gdlint are on PATH they are used directly; otherwise set
# GDTOOLKIT_BIN to a directory containing them.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/vertical-slice/godot"

FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

# Locate tools: PATH first, then GDTOOLKIT_BIN, then a local venv.
if command -v gdformat >/dev/null 2>&1; then
    GDFORMAT=gdformat
    GDLINT=gdlint
elif [ -n "${GDTOOLKIT_BIN:-}" ] && [ -x "$GDTOOLKIT_BIN/gdformat.exe" ]; then
    GDFORMAT="$GDTOOLKIT_BIN/gdformat.exe"
    GDLINT="$GDTOOLKIT_BIN/gdlint.exe"
elif [ -x "$HOME/tools/gdvenv/Scripts/gdformat.exe" ]; then
    GDFORMAT="$HOME/tools/gdvenv/Scripts/gdformat.exe"
    GDLINT="$HOME/tools/gdvenv/Scripts/gdlint.exe"
elif [ -x "$HOME/tools/gdvenv/bin/gdformat" ]; then
    GDFORMAT="$HOME/tools/gdvenv/bin/gdformat"
    GDLINT="$HOME/tools/gdvenv/bin/gdlint"
else
    echo "error: gdformat/gdlint not found. Install with: pip install 'gdtoolkit==4.*'" >&2
    exit 2
fi

cd "$PROJECT"

if [ "$FIX" -eq 1 ]; then
    echo "== gdformat (fixing) =="
    "$GDFORMAT" scripts autoloads resources test
else
    echo "== gdformat (check) =="
    "$GDFORMAT" --check scripts autoloads resources test
fi
FMT=$?

echo "== gdlint =="
"$GDLINT" scripts/*.gd autoloads/*.gd resources/*.gd
LINT=$?

echo ""
if [ $FMT -ne 0 ] || [ $LINT -ne 0 ]; then
    echo "CHECK FAILED (format=$FMT lint=$LINT)"
    [ "$FIX" -eq 0 ] && echo "Run with --fix to auto-format."
    exit 1
fi
echo "GDSCRIPT CHECK PASS"
