#!/usr/bin/env bash
#
# Builds web/sqlite3.wasm with FTS3/FTS4 enabled.
#
# package:sqlite3 ships a wasm build compiled with FTS5 only, so the Lafzi
# database (which uses an FTS4 table) cannot be opened with the stock file.
# This script compiles the same SQLite bridge with SQLITE_ENABLE_FTS3.
#
# Requirements:
#   - cmake and binaryen (wasm-opt, wasm-ctor-eval)
#   - the WASI SDK (downloaded automatically on first run, ~180 MB)
#
# On macOS: brew install cmake binaryen
#
# Usage:
#   tool/build_sqlite3_wasm.sh
#
# Optional overrides:
#   WASI_SDK_PATH=/path/to/wasi-sdk
#   SQLITE3_VERSION=3.5.2   (keep in sync with pubspec.yaml)
#
# The sqlite3 package is pinned in pubspec.yaml; bump both together and
# re-test the web build after rebuilding.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQLITE3_VERSION="${SQLITE3_VERSION:-3.5.2}"
WASI_SDK_VERSION="${WASI_SDK_VERSION:-34}"
WORK_DIR="${WORK_DIR:-$ROOT/.dart_tool/sqlite3_wasm_build}"
SRC_DIR="$WORK_DIR/sqlite3.dart"
BUILD_DIR="$WORK_DIR/build"
OUTPUT="$ROOT/web/sqlite3.wasm"

BINARYEN_PREFIX="${BINARYEN_PREFIX:-$(brew --prefix binaryen 2>/dev/null || echo /opt/homebrew/opt/binaryen)}"

for tool in cmake "$BINARYEN_PREFIX/bin/wasm-opt" \
  "$BINARYEN_PREFIX/bin/wasm-ctor-eval"; do
  if [[ ! -x "$(command -v "$tool" || true)" && ! -x "$tool" ]]; then
    echo "error: missing $tool" >&2
    echo "install the toolchain: brew install cmake binaryen" >&2
    exit 1
  fi
done

find_wasi_sdk() {
  if [[ -n "${WASI_SDK_PATH:-}" && -x "$WASI_SDK_PATH/bin/clang" ]]; then
    echo "$WASI_SDK_PATH"
    return
  fi
  if [[ -x "$WORK_DIR/wasi-sdk/bin/clang" ]]; then
    echo "$WORK_DIR/wasi-sdk"
    return
  fi
  local candidate
  for candidate in "$ROOT"/.dart_tool/wasi-sdk-*/bin/clang; do
    if [[ -x "$candidate" ]]; then
      echo "$(dirname "$(dirname "$candidate")")"
      return
    fi
  done
}

wasi_sdk_triple() {
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) echo "arm64-macos" ;;
    Darwin-x86_64) echo "x86_64-macos" ;;
    Linux-aarch64) echo "arm64-linux" ;;
    Linux-x86_64) echo "x86_64-linux" ;;
    *)
      echo "error: unsupported host $(uname -s)-$(uname -m)" >&2
      return 1
      ;;
  esac
}

WASI_SDK="$(find_wasi_sdk || true)"
if [[ -z "$WASI_SDK" ]]; then
  mkdir -p "$WORK_DIR"
  archive="$WORK_DIR/wasi-sdk.tar.gz"
  triple="$(wasi_sdk_triple)"
  url="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION}/wasi-sdk-${WASI_SDK_VERSION}.0-${triple}.tar.gz"
  echo "==> Downloading WASI SDK ${WASI_SDK_VERSION} (${triple})"
  curl -L --fail --retry 2 -o "$archive" "$url"
  tar -xzf "$archive" -C "$WORK_DIR"
  rm -rf "$WORK_DIR/wasi-sdk"
  mv "$WORK_DIR"/wasi-sdk-"${WASI_SDK_VERSION}".0-"${triple}" "$WORK_DIR/wasi-sdk"
  WASI_SDK="$WORK_DIR/wasi-sdk"
fi

CLANG="$WASI_SDK/bin/clang"
WASI_SYSROOT="$WASI_SDK/share/wasi-sysroot"
# Do not put the WASI SDK first on PATH: `dart run` (used by the CMake
# required-symbols step) invokes native build hooks and must keep using the
# host compiler. clang finds wasm-ld next to itself, so the absolute path is
# enough for the wasm build.
export PATH="$BINARYEN_PREFIX/bin:$PATH"

for tool in "$CLANG" "$WASI_SDK/bin/wasm-ld" \
  "$WASI_SYSROOT/lib/wasm32-wasip1/libc.a"; do
  if [[ ! -e "$tool" ]]; then
    echo "error: incomplete WASI SDK, missing $tool" >&2
    exit 1
  fi
done

if [[ ! -d "$SRC_DIR/.git" ]]; then
  echo "==> Cloning sqlite3.dart $SQLITE3_VERSION"
  git clone --depth 1 --branch "sqlite3-$SQLITE3_VERSION" \
    https://github.com/simolus3/sqlite3.dart.git "$SRC_DIR"
fi

# sqlite3.dart 3.5.2 still targets the pre-WASI-preview-1 triple name, which
# the current WASI SDK no longer accepts when resolving sysroot headers.
CMAKE_LISTS="$SRC_DIR/sqlite3_wasm_build/src/CMakeLists.txt"
if grep -q "wasm32-unknown-wasi" "$CMAKE_LISTS"; then
  echo "==> Targeting wasm32-wasip1"
  sed -i.bak 's/wasm32-unknown-wasi/wasm32-wasip1/' "$CMAKE_LISTS"
  rm -f "$CMAKE_LISTS.bak"
fi

# LTO pulls in libc's WASI `random_get` import, which the Dart wasm
# loader does not provide (it only supplies the `dart` bridge imports). The
# non-LTO build keeps the module import-free and is only a few KB larger.
if grep -q -- '-flto' "$CMAKE_LISTS"; then
  echo "==> Dropping -flto to avoid WASI imports"
  sed -i.bak 's/ "-flto"//' "$CMAKE_LISTS"
  rm -f "$CMAKE_LISTS.bak"
fi

CFG="$SRC_DIR/sqlite3_wasm_build/src/sqlite_cfg.h"
if ! grep -q "SQLITE_ENABLE_FTS3" "$CFG"; then
  echo "==> Enabling FTS3/FTS4 in $CFG"
  cat >>"$CFG" <<'EOF'

// Lafzi: the bundled database uses an FTS4 virtual table.
#define SQLITE_ENABLE_FTS3 1
#define SQLITE_ENABLE_FTS4 1
EOF
fi

echo "==> Configuring"
rm -rf "$BUILD_DIR"
cmake -S "$SRC_DIR/sqlite3_wasm_build/src" -B "$BUILD_DIR" \
  -Dwasi_sysroot="$WASI_SYSROOT" \
  -Dclang="$CLANG"

echo "==> Building sqlite3_opt.wasm (this compiles SQLite from source)"
cmake --build "$BUILD_DIR" --target sqlite3_opt -j "$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

cp "$BUILD_DIR/sqlite3_opt.wasm" "$OUTPUT"

echo "==> Wrote $OUTPUT ($(wc -c <"$OUTPUT" | tr -d ' ') bytes)"
echo "Verify in a browser: open the bundled database and run"
echo "  SELECT docid FROM quran_text WHERE text_reverse MATCH 'هللا*';"
echo "(PRAGMA compile_options is intentionally omitted by sqlite_cfg.h.)"
