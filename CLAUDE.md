# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenImageIO is a Swift library that provides **full API compatibility with Apple's ImageIO framework** for WebAssembly (WASM) environments.

### Core Principle: Full Compatibility

**The API must be 100% compatible with ImageIO.** This means:
- Identical type names, method signatures, and property names
- Same behavior and semantics as ImageIO
- Code written for ImageIO should compile and work without modification when using OpenImageIO

### How `canImport` Works

Users of this library will write code like:

```swift
#if canImport(ImageIO)
import ImageIO
#else
import OpenImageIO
#endif

// This code works in both environments
let source = CGImageSourceCreateWithData(data as CFData, nil)
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
```

- **When ImageIO is available** (iOS, macOS, etc.): Users import ImageIO directly
- **When ImageIO is NOT available** (WASM): Users import OpenImageIO, which provides identical APIs

This library exists so that cross-platform Swift code can use ImageIO APIs even in WASM environments where Apple's ImageIO is not available.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter <TestName>

# Build for WASM (requires SwiftWasm toolchain)
swift build --triple wasm32-unknown-wasi
```

## Architecture

### Implementation Approach

This library provides standalone implementations of ImageIO types for WASM environments. Each type/function must exactly mirror the ImageIO API:

```swift
// Example: CGImageSource functions must match ImageIO exactly
public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource?

public func CGImageSourceCreateImageAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage?
```

**Important**: Always refer to Apple's official ImageIO documentation to ensure API signatures match exactly.

### Type Categories to Implement

1. **Image Sources**: `CGImageSource` - Read and decode image data
   - `CGImageSourceCreateWithData`, `CGImageSourceCreateWithURL`, `CGImageSourceCreateWithDataProvider`
   - `CGImageSourceGetCount`, `CGImageSourceGetType`, `CGImageSourceGetTypeID`
   - `CGImageSourceCreateImageAtIndex`, `CGImageSourceCreateThumbnailAtIndex`
   - `CGImageSourceCopyProperties`, `CGImageSourceCopyPropertiesAtIndex`
   - `CGImageSourceGetStatus`, `CGImageSourceGetStatusAtIndex`

2. **Image Destinations**: `CGImageDestination` - Encode and write image data
   - `CGImageDestinationCreateWithData`, `CGImageDestinationCreateWithURL`, `CGImageDestinationCreateWithDataConsumer`
   - `CGImageDestinationAddImage`, `CGImageDestinationAddImageFromSource`
   - `CGImageDestinationSetProperties`, `CGImageDestinationFinalize`
   - `CGImageDestinationCopyTypeIdentifiers`, `CGImageDestinationGetTypeID`

3. **Image Metadata**: Reading and writing EXIF, IPTC, XMP metadata
   - `CGImageMetadataCreateMutable`, `CGImageMetadataCreateMutableCopy`
   - `CGImageMetadataGetTypeID`, `CGImageMetadataCopyTags`
   - `CGImageMetadataSetValueWithPath`, `CGImageMetadataCopyStringValueWithPath`

4. **Image Properties Dictionary Keys**:
   - `kCGImageSourceTypeIdentifierHint`
   - `kCGImageSourceShouldCache`
   - `kCGImageSourceShouldCacheImmediately`
   - `kCGImageSourceCreateThumbnailFromImageIfAbsent`
   - `kCGImageSourceCreateThumbnailFromImageAlways`
   - `kCGImageSourceThumbnailMaxPixelSize`
   - `kCGImageSourceCreateThumbnailWithTransform`
   - `kCGImageDestinationLossyCompressionQuality`
   - `kCGImageDestinationBackgroundColor`
   - And all EXIF, IPTC, GPS, TIFF property keys

5. **Supported Image Formats**:
   - PNG, JPEG, GIF, BMP, TIFF (priority formats for WASM)
   - WebP (if feasible)

### Dependencies

This library will likely depend on:
- **OpenCoreGraphics**: For `CGImage`, `CGDataProvider`, `CGDataConsumer`, `CFData`, etc.
- Pure Swift image codec implementations or lightweight C libraries for actual encoding/decoding

### Protocol Conformances

Reference types (`CGImageSource`, `CGImageDestination`, `CGImageMetadata`) should be classes that properly manage resources.

### Implementation Policy

- **Do NOT implement deprecated APIs** - Only implement current, non-deprecated ImageIO APIs
- Focus on APIs that are meaningful for WASM environments
- Prioritize common image formats (PNG, JPEG, GIF) over specialized ones

## Testing

Uses Swift Testing framework (not XCTest). Test syntax:

```swift
import Testing
@testable import OpenImageIO

@Test func testImageSourceFromPNG() {
    let pngData = createTestPNGData()
    let source = CGImageSourceCreateWithData(pngData as CFData, nil)
    #expect(source != nil)
    #expect(CGImageSourceGetCount(source!) == 1)
}

@Test func testImageDestinationToJPEG() {
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(
        data as CFMutableData,
        "public.jpeg" as CFString,
        1,
        nil
    )
    #expect(destination != nil)
}
```
