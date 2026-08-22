#!/usr/bin/env bash
# Export preset validation + build for Brew & Justice (issue #43).
#
# Usage:
#   bash scripts/check_export.sh            # validate presets + templates only
#   bash scripts/check_export.sh --build win [web]   # validate, then export
#
# Environment: GODOT_BIN (default: godot on PATH), EXPORT_TEMPLATES_DIR
# (default per-OS Godot user dir).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/vertical-slice/godot"
DIST="$ROOT/dist"

# Locate Godot.
if [ -n "${GODOT_BIN:-}" ]; then
    GODOT="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
    GODOT=godot
else
    echo "error: godot not found. Set GODOT_BIN." >&2
    exit 2
fi

# Locate export templates (platform-specific user dir).
if [ -n "${EXPORT_TEMPLATES_DIR:-}" ]; then
    TPL_BASE="$EXPORT_TEMPLATES_DIR"
elif [ -n "${APPDATA:-}" ] && [ -d "$APPDATA/Godot/export_templates" ]; then
    TPL_BASE="$APPDATA/Godot/export_templates"
elif [ -d "$HOME/.local/share/godot/export_templates" ]; then
    TPL_BASE="$HOME/.local/share/godot/export_templates"
else
    TPL_BASE=""
fi

VERSION=$("$GODOT" --version | tail -1 | sed 's/\.official.*//')   # e.g. 4.4.stable
TPL_DIR="$TPL_BASE/$VERSION"

fails=0
ok()   { echo "  PASS  $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails+1)); }

echo "== Export preset validation =="

# 1. Preset file exists and parses as ini with at least one preset.
if [ -f "$PROJECT/export_presets.cfg" ]; then
    ok "export_presets.cfg exists"
else
    bad "export_presets.cfg missing"
fi
PRESETS=$(grep -c '^\[preset\.' "$PROJECT/export_presets.cfg" 2>/dev/null || echo 0)
[ "$PRESETS" -ge 1 ] && ok "$PRESETS preset(s) defined" || bad "no presets defined"

# 2. Templates installed for this exact editor version.
if [ -d "$TPL_DIR" ]; then
    ok "export templates present for $VERSION"
else
    bad "export templates missing at $TPL_DIR"
    echo "        install: download Godot_v${VERSION%%.*}* export_templates.tpz and"
    echo "                 unpack into $TPL_BASE/$VERSION/"
fi

# 3. Every preset's platform has a template binary available.
while IFS= read -r plat; do
    case "$plat" in
        "Windows Desktop") tpl="windows_release_x86_64.exe";;
        "Web")             tpl="web_release.zip";;
        "Linux")           tpl="linux_release.x86_64";;
        "macOS")           tpl="macos.zip";;
        *) tpl="";;
    esac
    if [ -z "$tpl" ]; then
        bad "unknown platform in presets: $plat"
    elif [ -n "$TPL_DIR" ] && ls "$TPL_DIR"/"$tpl" >/dev/null 2>&1; then
        ok "template available for $plat ($tpl)"
    elif [ -n "$TPL_DIR" ]; then
        bad "template $tpl missing for $plat"
    else
        echo "  SKIP  template check for $plat (templates dir absent)"
    fi
done

# 4. Project still loads headlessly with the preset file present.
if "$GODOT" --headless --path "$PROJECT" --quit >/dev/null 2>&1; then
    ok "project loads headlessly with presets installed"
else
    bad "project failed headless load with presets present"
fi

BUILD_TARGETS=()
[ "${1:-}" = "--build" ] && BUILD_TARGETS=("${@:2}")

for target in "${BUILD_TARGETS[@]}"; do
    echo "== Exporting: $target =="
    mkdir -p "$DIST"
    case "$target" in
        win) preset="Windows Desktop"; out="brew-justice.exe";;
        web) preset="Web";             out="brew-justice.html";;
        *) echo "unknown target '$target' (win|web)"; fails=$((fails+1)); continue;;
    esac
    # Native (non-MSYS) paths for Godot; MSYS /c/... gets double-prefixed.
    case "$PROJECT" in
        /c/*) PROJ_NATIVE="C:${PROJECT#/c}" ;;
        *)    PROJ_NATIVE="$PROJECT" ;;
    esac
    OUT_NATIVE="$DIST/$out"
    case "$OUT_NATIVE" in
        /c/*) OUT_NATIVE="C:${OUT_NATIVE#/c}" ;;
    esac
    # Note: parse *warnings* about test-only base classes (e.g. GutTest) are
    # expected — tests are excluded from runtime behavior. The rcedit error
    # (icon/version stamping) is non-fatal: the exe is still produced and
    # runs; it just keeps Godot's default version metadata.
    "$GODOT" --headless --path "$PROJ_NATIVE" \
        --export-release "$preset" "$OUT_NATIVE" > "$DIST/export-$target.log" 2>&1
    if grep -qE "^ERROR|Export failed" "$DIST/export-$target.log" \
        && ! grep -q "Could not create child process: rcedit" "$DIST/export-$target.log"; then \
        bad "export reported errors (see dist/export-$target.log)"
    fi
    if [ -f "$DIST/$out" ]; then
        size=$(du -h "$DIST/$out" | cut -f1)
        ok "exported $DIST/$out ($size)"
    else
        bad "expected output $DIST/$out not produced"
    fi
done

echo ""
if [ $fails -ne 0 ]; then
    echo "EXPORT CHECK FAILED ($fails failure(s))"
    exit 1
fi
echo "EXPORT CHECK PASS"
