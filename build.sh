#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# ---- Config ----
CRATE_NAME="mobile"
IOS_DIR="$ROOT/uniffi-test"
XCODE_SWIFT_DEST="$IOS_DIR/Mobile.swift"
XCODE_XCFRAMEWORK_DEST="$IOS_DIR/Mobile.xcframework"

BINDINGS_DIR="$ROOT/bindings"
HEADERS_DIR="$ROOT/ios-headers"

# ---- 1) Build a macOS dylib for bindgen introspection ----
cargo build

DYLIB_PATH="$ROOT/target/debug/lib${CRATE_NAME}.dylib"
if [[ ! -f "$DYLIB_PATH" ]]; then
  echo "Expected dylib not found: $DYLIB_PATH"
  echo "Check your Cargo.toml crate-type includes cdylib and that you're on macOS."
  exit 1
fi

# ---- 2) Generate fresh bindings ----
rm -rf "$BINDINGS_DIR"
mkdir -p "$BINDINGS_DIR"

cargo run --features uniffi/cli --bin uniffi-bindgen -- \
  generate --library "$DYLIB_PATH" --language swift --out-dir "$BINDINGS_DIR"

# ---- 3) Prepare a clean headers dir for XCFramework ----
rm -rf "$HEADERS_DIR"
mkdir -p "$HEADERS_DIR"

# UniFFI outputs "mobileFFI.modulemap" but Xcode wants "module.modulemap"
cp "$BINDINGS_DIR/mobileFFI.h" "$HEADERS_DIR/mobileFFI.h"
cp "$BINDINGS_DIR/mobileFFI.modulemap" "$HEADERS_DIR/module.modulemap"

# ---- 4) Build iOS static libs (device + simulator) ----
for TARGET in aarch64-apple-ios aarch64-apple-ios-sim; do
  rustup target add "$TARGET"
  cargo build --release --target="$TARGET"
done

IOS_LIB_SIM="$ROOT/target/aarch64-apple-ios-sim/release/lib${CRATE_NAME}.a"
IOS_LIB_DEV="$ROOT/target/aarch64-apple-ios/release/lib${CRATE_NAME}.a"

if [[ ! -f "$IOS_LIB_SIM" || ! -f "$IOS_LIB_DEV" ]]; then
  echo "Missing iOS static libs:"
  echo "  $IOS_LIB_SIM"
  echo "  $IOS_LIB_DEV"
  exit 1
fi

# ---- 5) Replace Swift bindings file in Xcode project ----
mkdir -p "$(dirname "$XCODE_SWIFT_DEST")"
cp "$BINDINGS_DIR/mobile.swift" "$XCODE_SWIFT_DEST"

# ---- 6) Recreate XCFramework ----
rm -rf "$XCODE_XCFRAMEWORK_DEST"

xcodebuild -create-xcframework \
  -library "$IOS_LIB_SIM" -headers "$HEADERS_DIR" \
  -library "$IOS_LIB_DEV" -headers "$HEADERS_DIR" \
  -output "$XCODE_XCFRAMEWORK_DEST"

echo "✅ Done."
echo "   Updated: $XCODE_SWIFT_DEST"
echo "   Updated: $XCODE_XCFRAMEWORK_DEST"
