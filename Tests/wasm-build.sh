#!/usr/bin/env bash
#
# WASM-build smoke test for OpenImageIO.
#
# OpenImageIO is a pure-Swift codec library. This script is the compile-only
# WASM gate; the separate Tests/e2e suite exercises the compiled codecs in a
# browser and validates their output with Chromium's image decoders.
#
# Run with: bash Tests/wasm-build.sh
# Exits 0 on success, nonzero on any compile failure.

set -euo pipefail

# Resolve package root (parent of this tests/ dir) regardless of CWD.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$HERE/.." && pwd)"

SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"
if command -v swiftly >/dev/null 2>&1; then
    SWIFT_COMMAND=(swiftly run swift)
else
    SWIFT_COMMAND=(swift)
fi

echo "==> WASM-build smoke: OpenImageIO"
echo "    package: $PACKAGE_ROOT"
echo "    sdk:     $SDK"
cd "$PACKAGE_ROOT"

if ! "${SWIFT_COMMAND[@]}" sdk list 2>/dev/null | grep -q "^${SDK}$"; then
    echo "!! Swift WASM SDK '${SDK}' is not installed." >&2
    echo "   Install it with:" >&2
    echo "   swift sdk install https://download.swift.org/swift-6.3.1-release/wasm-sdk/swift-6.3.1-RELEASE/swift-6.3.1-RELEASE_wasm.artifactbundle.tar.gz" >&2
    exit 2
fi

"${SWIFT_COMMAND[@]}" build --swift-sdk "$SDK"
echo "==> OK: OpenImageIO compiles for wasm32-unknown-wasip1"
