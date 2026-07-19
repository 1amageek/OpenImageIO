# OpenImageIO Quality Checklist

This checklist separates API presence from codec correctness. A format may be
advertised only when its pixel decoder and encoder are validated independently
of OpenImageIO.

## Release Gates

| Gate | Required evidence |
|---|---|
| Native behavior | Focused `xcodebuild test` completes within the configured process timeout |
| WASM compilation | `bash Tests/wasm-build.sh` succeeds with `swift-6.3.1-RELEASE_wasm` |
| Browser execution | `Tests/e2e` loads and executes the WASM module in Chromium |
| Decode conformance | Fixtures produced by external encoders decode to the expected dimensions and pixels |
| Encode conformance | Apple ImageIO accepts produced files and reports the expected format and dimensions |
| Round trip | Encode and decode preserve pixels within the format's loss model |
| Metadata | XMP parsing/serialization is behavior-tested and accepted by Apple ImageIO |
| Failure behavior | Truncated, malformed, unsupported, and oversized inputs fail safely |

## Advertised Pixel Codecs

| Format | Decode | Encode | External validation | Notes |
|---|---:|---:|---:|---|
| PNG | Yes | Yes | Apple ImageIO | Lossless |
| JPEG | Yes | Yes | Apple ImageIO | Baseline lossy path |
| GIF | Yes | Yes | Apple ImageIO | Palette and animation paths |
| BMP | Yes | Yes | Apple ImageIO | 24-bit and 32-bit paths |
| TIFF | Yes | Yes | Apple ImageIO | Alpha semantics include `ExtraSamples` |

## Unsupported Pixel Codecs

| Format | Policy |
|---|---|
| WebP | Do not return its UTI from supported source/destination lists until VP8/VP8L pixel conformance exists |
| HEIF/HEIC | Keep property constants separate from codec support |
| AVIF | Do not advertise without a conforming AV1 implementation |
| Camera RAW | Do not advertise format-specific metadata as pixel decoding support |

## Current Verified Baseline

| Layer | Result |
|---|---|
| Native package | 288 tests in 49 suites passed through the complete `xcodebuild test` gate |
| External compatibility | Apple ImageIO and OpenImageIO decode each other's advertised PNG/JPEG/GIF/BMP/TIFF output |
| WASM | Package build passed |
| Browser | Swift PNG pixel roundtrip and Chromium decode of PNG/JPEG/GIF/BMP passed |

Passing this checklist validates the exercised paths only; it does not imply
complete parity with every ImageIO API or every legal bitstream variant.
