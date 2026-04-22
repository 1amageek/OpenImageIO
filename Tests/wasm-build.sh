#!/usr/bin/env bash
#
# WASM-build smoke test for OpenImageIO.
#
# OpenImageIO has no browser runtime to exercise — the library is pure-Swift
# image codecs (PNG/JPEG/GIF/BMP/TIFF/WebP) with no JavaScriptKit / WebGPU
# dependency. The only thing that can break per-platform is that the WASM
# toolchain fails to compile the sources. This script catches exactly that:
# it is a compile-only tier-3 smoke test that matches the "WASM-build smoke"
# tier described in the workspace CLAUDE.md.
#
# Run with: bash OpenImageIO/tests/wasm-build.sh
# Exits 0 on success, nonzero on any compile failure.

set -euo pipefail

# Resolve package root (parent of this tests/ dir) regardless of CWD.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$HERE/.." && pwd)"

SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"

echo "==> WASM-build smoke: OpenImageIO"
echo "    package: $PACKAGE_ROOT"
echo "    sdk:     $SDK"
cd "$PACKAGE_ROOT"

if ! swift sdk list 2>/dev/null | grep -q "^${SDK}$"; then
    echo "!! Swift WASM SDK '${SDK}' is not installed." >&2
    echo "   Install it with:" >&2
    echo "   swift sdk install https://download.swift.org/swift-6.3.1-release/wasm-sdk/swift-6.3.1-RELEASE/swift-6.3.1-RELEASE_wasm.artifactbundle.tar.gz" >&2
    exit 2
fi

swift build --swift-sdk "$SDK"
echo "==> OK: OpenImageIO compiles for wasm32-unknown-wasip1"
