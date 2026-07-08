#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-wrap-input}"
OUTPUT="${2:-/tmp/slopad-debug-${SCENARIO}.png}"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$PWD/.build/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

if [[ "${SLOPAD_DEBUG_BUILD:-0}" == "1" || ! -x .build/debug/SlopadDebugApp ]]; then
  swift build --product SlopadDebugApp
fi

if [[ ! -x .build/debug/SlopadDebugApp ]]; then
  printf 'SlopadDebugApp is not built. Run `swift build --product SlopadDebugApp` first.\n' >&2
  exit 1
fi

.build/debug/SlopadDebugApp \
  --scenario "$SCENARIO" \
  --screenshot "$OUTPUT" \
  --auto-exit

printf '%s\n' "$OUTPUT"
