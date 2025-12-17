# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL REQUIREMENT: API Compatibility

**THIS IS THE MOST IMPORTANT REQUIREMENT. IT IS NON-NEGOTIABLE.**

OpenImageIO MUST maintain **100% API compatibility with Apple's ImageIO framework**. This requirement takes absolute priority over all other considerations:

- **Cost is not a constraint** - Spend as much effort as needed to achieve compatibility
- **No shortcuts** - Do not simplify or deviate from ImageIO's API signatures
- **Exact matching** - Every function signature, type name, and constant must match ImageIO exactly

### Why This Matters

Users write code like this:

```swift
#if canImport(ImageIO)
import ImageIO
#else
import OpenImageIO
#endif

// This code MUST compile and work identically in both cases
let source = CGImageSourceCreateWithData(data as CFData, nil)
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
```

**If even one API signature differs, the user's code will fail to compile.**

### Verification Process

Before implementing ANY function:
1. Check Apple's official ImageIO documentation
2. Verify the EXACT function signature (parameter types, return type, parameter names)
3. Match the behavior as closely as possible

### API Signatures MUST Match ImageIO

```swift
// These signatures are from Apple's ImageIO - they MUST be identical

// CGImageSource
public func CGImageSourceCreateWithData(_ data: CFData, _ options: CFDictionary?) -> CGImageSource?
public func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource?
public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage?
public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CFDictionary?

// CGImageDestination
public func CGImageDestinationCreateWithData(_ data: CFMutableData, _ type: CFString, _ count: Int, _ options: CFDictionary?) -> CGImageDestination?
public func CGImageDestinationAddImage(_ idst: CGImageDestination, _ image: CGImage, _ properties: CFDictionary?)
public func CGImageDestinationFinalize(_ idst: CGImageDestination) -> Bool
```

---

## Project Overview

OpenImageIO is a Swift library that provides **full API compatibility with Apple's ImageIO framework** for WebAssembly (WASM) environments.

- **When ImageIO is available** (iOS, macOS, etc.): Users import ImageIO directly
- **When ImageIO is NOT available** (WASM): Users import OpenImageIO, which provides identical APIs

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

### Dependencies

- **OpenCoreGraphics**: For `CGImage`, `CGDataProvider`, `CGDataConsumer`, `CGColorSpace`, etc.
- **Foundation**: For CoreFoundation types (`CFData`, `CFString`, `CFDictionary`, etc.)

### CoreFoundation Types

CoreFoundation types (`CFData`, `CFString`, `CFDictionary`, `CFURL`, etc.) are available through `import Foundation`.

**Use `@preconcurrency import Foundation` to avoid Swift 6 concurrency warnings with CF types.**

```swift
@preconcurrency import Foundation
import OpenCoreGraphics

// CF types from Foundation
// CG types from OpenCoreGraphics
```

### Internal Implementation vs Public API

**Public API** must use CF types to match ImageIO exactly:
```swift
// Public API - MUST match ImageIO signatures
public func CGImageSourceCreateWithData(_ data: CFData, _ options: CFDictionary?) -> CGImageSource?
```

**Internal implementation** can use Swift types for convenience, with conversions at the API boundary:
```swift
internal var imageData: Data  // Internal: Swift types
internal var properties: [String: Any]  // Internal: Swift types

// At API boundary: convert to CF types
public func CGImageSourceCopyProperties(...) -> CFDictionary? {
    return properties as CFDictionary
}
```

### String Constants

For ImageIO property key constants, use `String` type (bridges to `CFString` automatically):

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

- PNG, JPEG, GIF, BMP, TIFF (priority formats)
- WebP (if feasible)

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
