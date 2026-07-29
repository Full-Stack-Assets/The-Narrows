#!/usr/bin/env bash
# Single local/CI verification gate: harness, import, tests, and Web export.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
VERIFY_TMP="$(mktemp -d "${TMPDIR:-/tmp}/the-narrows-verify.XXXXXX")"
trap 'rm -r -- "$VERIFY_TMP"' EXIT

if ! "$GODOT_BIN" --version | grep -F "4.6"; then
  echo "Godot 4.6 is required; received: $("$GODOT_BIN" --version 2>&1)" >&2
  exit 1
fi

run_godot() {
  local label="$1"
  shift
  local log_file="$VERIFY_TMP/${label}.log"
  local command_status

  set +e
  "$GODOT_BIN" "$@" 2>&1 | tee "$log_file"
  command_status=${PIPESTATUS[0]}
  set -e

  if [ "$command_status" -ne 0 ]; then
    echo "Godot ${label} failed with exit code ${command_status}." >&2
    exit "$command_status"
  fi

  if grep -E "SCRIPT ERROR|Parse Error|Failed to load" "$log_file"; then
    echo "Godot ${label} reported a script, parse, or resource-load error." >&2
    exit 1
  fi
}

cd "$PROJECT_ROOT"
python3 -m unittest tests/test_build_scripts.py

if [ -d "$PROJECT_ROOT/build/web" ]; then
  rm -r -- "$PROJECT_ROOT/build/web"
fi

echo "Importing project..."
run_godot import --headless --quiet --path "$PROJECT_ROOT" --import

echo "Running Godot smoke tests..."
run_godot tests --headless --path "$PROJECT_ROOT" --script res://tests/test_runner.gd

mkdir -p "$PROJECT_ROOT/build/web"
echo "Exporting Web build..."
run_godot export --headless --quiet --path "$PROJECT_ROOT" \
  --export-release "Web" "build/web/index.html"

echo "Exporting deferred content pack..."
run_godot deferred-export --headless --quiet --path "$PROJECT_ROOT" \
  --export-pack "Deferred Content" "build/web/deferred_content.pck"

python3 scripts/check_asset_budget.py --export-dir build/web
