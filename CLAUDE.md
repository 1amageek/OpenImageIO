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

# Run tests
swift test

# Run a specific test
swift test --filter <TestName>

# Build for WASM (requires Swift WASM SDK)
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
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

All formats are fully implemented with complete decode and encode support:

| Format | Decode | Encode | Notes |
|--------|--------|--------|-------|
| PNG | ✅ Full | ✅ Full | DEFLATE compression, all color types |
| JPEG | ✅ Full | ✅ Full | Baseline DCT, Huffman coding, quality control |
| GIF | ✅ Full | ✅ Full | LZW compression, Median Cut quantization, animation |
| BMP | ✅ Full | ✅ Full | 24-bit BGR, 32-bit BGRA with alpha support |
| TIFF | ✅ Full | ✅ Full | Uncompressed RGB/RGBA, multi-page support |
| WebP | ✅ Full | ✅ Full | VP8 (lossy) and VP8L (lossless) encode/decode |

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
- **WebP**: Full encode/decode support:
  - VP8L (lossless): LZ77 matching, Huffman coding, subtract-green transform
  - VP8 (lossy): DCT transform, quantization, boolean arithmetic coding
  - RIFF container format
- **GIF**: Advanced color quantization:
  - Median Cut algorithm for optimal palette selection
  - Floyd-Steinberg dithering (available via ColorQuantizer)

### Implementation Policy

- **Do NOT implement deprecated APIs** - Only implement current, non-deprecated ImageIO APIs
- Focus on APIs that are meaningful for WASM environments
- Prioritize common image formats (PNG, JPEG, GIF) over specialized ones

## Testing

Uses Swift Testing framework (not XCTest):

```swift
import Testing
@testable import OpenImageIO

@Test func testImageSourceFromPNG() {
    let pngData = createTestPNGData()
    let source = CGImageSourceCreateWithData(pngData as CFData, nil)
    #expect(source != nil)
    #expect(CGImageSourceGetCount(source!) == 1)
}
```
