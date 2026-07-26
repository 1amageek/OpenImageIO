# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenImageIO is a Swift library that provides **ImageIO-compatible APIs** for WebAssembly (WASM) environments.

### Design Philosophy

- **WASM-first**: This library is designed specifically for WASM environments where Apple's ImageIO is not available
- **Swift-native types**: Uses Swift types (`Data`, `URL`, `[String: Any]?`) instead of CoreFoundation types (`CFData`, `CFURL`, `CFDictionary?`) because CF types don't work in WASM
- **Functional compatibility**: Provides the same functionality as ImageIO with similar function names, but adapted for WASM constraints

### Usage Pattern

```swift
// WASM environment - use OpenImageIO with Swift types
import OpenImageIO

let source = CGImageSourceCreateWithData(data, nil)  // Data type
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)

// Darwin environment - use native ImageIO with CF types
import ImageIO

let source = CGImageSourceCreateWithData(data as CFData, nil)  // CFData type
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
```

**Note**: This is NOT a drop-in replacement for ImageIO. Platform-specific code is expected.

### API Signatures (Swift types for WASM)

```swift
// CGImageSource
public func CGImageSourceCreateWithData(_ data: Data, _ options: [String: Any]?) -> CGImageSource?
public func CGImageSourceCreateWithURL(_ url: URL, _ options: [String: Any]?) -> CGImageSource?
public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> CGImage?
public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> [String: Any]?

// CGImageDestination
public func CGImageDestinationCreateWithData(_ data: inout Data, _ type: String, _ count: Int, _ options: [String: Any]?) -> CGImageDestination?
public func CGImageDestinationAddImage(_ idst: CGImageDestination, _ image: CGImage, _ properties: [String: Any]?)
public func CGImageDestinationFinalize(_ idst: CGImageDestination) -> Bool
```

## Build Commands

```bash
# Build the package
swift build

# Run a focused test target with a process timeout
perl -e 'alarm 30; exec @ARGV' -- \
  xcodebuild test -scheme OpenImageIO -destination 'platform=macOS' \
  -only-testing:OpenImageIOTests

# Build for WASM with the fixed Swift 6.4 snapshot and matching SDK
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm
```

## Architecture

### Dependencies

- **OpenCoreGraphics**: For `CGImage`, `CGDataProvider`, `CGDataConsumer`, `CGColorSpace`, etc.
- **Foundation**: For basic types (`Data`, `URL`, etc.)

### Import Pattern

```swift
@preconcurrency import Foundation
import OpenCoreGraphics
```

### API Design

All public APIs use Swift-native types:

```swift
// Public API - Swift types for WASM compatibility
public func CGImageSourceCreateWithData(_ data: Data, _ options: [String: Any]?) -> CGImageSource?
public func CGImageSourceCopyProperties(_ isrc: CGImageSource, _ options: [String: Any]?) -> [String: Any]?
```

### String Constants

Property key constants use `String` type:

```swift
public let kCGImagePropertyPixelWidth: String = "PixelWidth"
public let kCGImagePropertyPixelHeight: String = "PixelHeight"
```

### Type Categories

1. **Image Sources**: `CGImageSource` - Read and decode image data
2. **Image Destinations**: `CGImageDestination` - Encode and write image data
3. **Image Metadata**: `CGImageMetadata`, `CGImageMetadataTag` - XMP metadata handling
4. **Property Keys**: All `kCGImageProperty*` constants

### Supported Image Formats

Only formats that pass package tests and external Apple ImageIO conformance
are advertised as pixel codecs:

| Format | Decode | Encode | Notes |
|--------|--------|--------|-------|
| PNG | ✅ Full | ✅ Full | DEFLATE compression, all color types |
| JPEG | ✅ Full | ✅ Full | Baseline DCT, Huffman coding, quality control |
| GIF | ✅ Full | ✅ Full | LZW compression, Median Cut quantization, animation |
| BMP | ✅ Full | ✅ Full | 24-bit BGR, 32-bit BGRA with alpha support |
| TIFF | ✅ Full | ✅ Full | Uncompressed RGB/RGBA, multi-page support |

#### Unsupported Formats

| Format | Status | Reason |
|--------|--------|--------|
| WebP | ❌ Not supported | No externally conforming VP8/VP8L pixel codec; container recognition alone is insufficient |
| HEIF/HEIC | ❌ Not supported | Requires HEVC (H.265) codec which involves complex implementation and patent licensing |
| AVIF | ❌ Not supported | Requires AV1 codec |
| RAW formats | ❌ Not supported | Camera-specific formats (CR2, NEF, ARW, etc.) |

**HEIF/HEIC Note**: HEIF is based on the ISO Base Media File Format (ISOBMFF) and uses HEVC for image compression. Pure Swift implementation would require thousands of lines of code for the HEVC decoder. For WASM environments requiring HEIF support, consider using `libheif` compiled to WebAssembly via Emscripten.

#### Implementation Details

- **PNG**: Full DEFLATE/zlib compression with Adler-32 checksums
- **JPEG**: Complete baseline DCT encoder with:
  - Forward DCT transform (8x8 blocks)
  - Quantization with quality scaling
  - Huffman coding (standard tables)
  - YCbCr color space conversion
- **GIF**: LZW compression with variable code sizes, multi-frame animation
- **BMP**: Standard Windows bitmap format with:
  - 24-bit BGR (BITMAPINFOHEADER)
  - 32-bit BGRA with alpha channel (BITMAPV4HEADER)
- **TIFF**: Little-endian format with:
  - Uncompressed RGB/RGBA data
  - Multi-page (multi-IFD) support
  - Resolution metadata
- **GIF**: Advanced color quantization:
  - Median Cut algorithm for optimal palette selection
  - Floyd-Steinberg dithering (available via ColorQuantizer)

### Implementation Policy

- **Do NOT implement deprecated APIs** - Only implement current, non-deprecated ImageIO APIs
- **Do NOT implement CoreFoundation-dependent APIs** - CF runtime is not available in WASM
- Focus on APIs that are meaningful for WASM environments
- Prioritize common image formats (PNG, JPEG, GIF) over specialized ones

### Unsupported APIs

The following ImageIO APIs are intentionally NOT provided:

| API | Reason |
|-----|--------|
| `CGImageSourceGetTypeID()` | Requires CoreFoundation runtime (`CFTypeID`). Use Swift's `is`/`as?` instead. |
| `CGImageDestinationGetTypeID()` | Same as above |
| `CGImageMetadataGetTypeID()` | Same as above |
| `CGImageMetadataTagGetTypeID()` | Same as above |

**Note**: These CF-dependent APIs are legacy even on Darwin. Modern Swift code should use native type checking (`is`, `as?`) instead of `CFGetTypeID()`.

### Explicitly Unsupported Data

| API | Status |
|-----|--------|
| `CGImageSourceCopyAuxiliaryDataInfoAtIndex()` | Returns `nil`; no auxiliary payload is advertised without container extraction and pixel conformance. |
| `CGImageSourceGetPrimaryImageIndex()` | Returns 0 (correct for non-HEIF formats per Apple spec). HEIF not supported. |

Auxiliary encoding also fails finalization. It must not report success until
the selected container embeds the payload and an independent decoder reads it
back with equivalent metadata and pixels.

## Project Structure

```
Sources/OpenImageIO/
├── CGImageSource.swift          # Image decoding API
├── CGImageDestination.swift     # Image encoding API
├── CGImageMetadata.swift        # XMP metadata handling
├── CGImageMetadataTag.swift     # Metadata tag operations
├── ImageProperties.swift        # Property key constants
├── FormatProperties.swift       # Format-specific properties
│
├── Encoders/
│   ├── PNGEncoder.swift         # PNG with DEFLATE compression
│   ├── JPEGEncoder.swift        # JPEG with DCT, Huffman coding
│   ├── GIFEncoder.swift         # GIF with LZW, Median Cut quantization
│   ├── BMPEncoder.swift         # BMP 24-bit/32-bit support
│   ├── TIFFEncoder.swift        # TIFF with multi-page support
│   └── ColorQuantizer.swift     # Median Cut, Floyd-Steinberg dithering
│
├── Decoders/
│   ├── PNGDecoder.swift         # PNG decoding
│   ├── JPEGDecoder.swift        # JPEG decoding with YCbCr→RGB
│   ├── GIFDecoder.swift         # GIF with animation support
│   ├── BMPDecoder.swift         # BMP decoding
│   └── TIFFDecoder.swift        # TIFF with multi-page support
│
└── Compression/
    ├── Deflate.swift            # DEFLATE compression for PNG
    └── LZW.swift                # LZW compression for GIF/TIFF
```

## Testing

Uses Swift Testing framework (not XCTest):

```swift
import Testing
@testable import OpenImageIO

@Test func testImageSourceFromPNG() {
    let pngData = createTestPNGData()
    let source = CGImageSourceCreateWithData(pngData, nil)
    #expect(source != nil)
    #expect(CGImageSourceGetCount(source!) == 1)
}
```

### Test Coverage

**Verified baseline: 292 native tests**, plus external Apple ImageIO
conformance and browser checks for the five advertised pixel formats.

Do not maintain hand-counted per-suite totals here; use the current test runner
result and external-conformance report as the source of truth.

## Encoding Examples

### PNG Encoding

```swift
var data = Data()
let destination = CGImageDestinationCreateWithData(&data, "public.png", 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
if CGImageDestinationFinalize(destination) {
    let encoded = CGImageDestinationCopyData(destination)
}
```

### JPEG Encoding with Quality

```swift
let destination = CGImageDestinationCreateWithData(&data, "public.jpeg", 1, nil)!
CGImageDestinationAddImage(destination, image, [
    kCGImageDestinationLossyCompressionQuality: 0.8
])
CGImageDestinationFinalize(destination)
```

### Multi-page TIFF

```swift
let destination = CGImageDestinationCreateWithData(&data, "public.tiff", 3, nil)!
CGImageDestinationAddImage(destination, page1, nil)
CGImageDestinationAddImage(destination, page2, nil)
CGImageDestinationAddImage(destination, page3, nil)
CGImageDestinationFinalize(destination)
```

### Animated GIF

```swift
let destination = CGImageDestinationCreateWithData(&data, "com.compuserve.gif", 3, nil)!
CGImageDestinationSetProperties(destination, ["delay": 0.1])
CGImageDestinationAddImage(destination, frame1, nil)
CGImageDestinationAddImage(destination, frame2, nil)
CGImageDestinationAddImage(destination, frame3, nil)
CGImageDestinationFinalize(destination)
```

### BMP with Alpha Channel

```swift
let destination = CGImageDestinationCreateWithData(&data, "com.microsoft.bmp", 1, nil)!
CGImageDestinationAddImage(destination, image, ["preserveAlpha": true])
CGImageDestinationFinalize(destination)
```

## Type Identifiers

| Format | UTI |
|--------|-----|
| PNG | `public.png` |
| JPEG | `public.jpeg` |
| GIF | `com.compuserve.gif` |
| BMP | `com.microsoft.bmp` |
| TIFF | `public.tiff` |
