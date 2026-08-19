# OpenImageIO

A Swift library providing ImageIO-compatible APIs and pure-Swift codecs for WebAssembly (WASM) and other non-Apple platforms.

[![Swift](https://img.shields.io/badge/Swift-6.4%20snapshot-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-WASM%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

## Overview

OpenImageIO enables cross-platform Swift code to use familiar ImageIO APIs even in environments where Apple's ImageIO framework is unavailable. Write your image handling code once, and it works seamlessly across iOS, macOS, and WebAssembly.

```swift
#if canImport(ImageIO)
import ImageIO
#else
import OpenImageIO
#endif

// This code works in both environments
let source = CGImageSourceCreateWithData(data, nil)
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
```

## Features

- **ImageIO-Compatible Surface** - Familiar source, destination, metadata, and property APIs using WASM-safe Swift types
- **Externally Verified Codecs** - PNG, JPEG, GIF, BMP, and TIFF
- **Image Sources** - Read and decode image data with `CGImageSource`
- **Image Destinations** - Encode and write image data with `CGImageDestination`
- **XMP Metadata** - RDF structures, arrays, qualifiers, namespace registration, paths, and serialization
- **Image Property Constants** - Current ImageIO key names for EXIF, IPTC, GPS, TIFF, and format dictionaries
- **Incremental Sources** - Accumulate data and validate the complete payload when the final update arrives
- **Thumbnail Generation** - Create thumbnails with configurable options

## Requirements

- Swift 6.4 development snapshot baseline
- For WASM: SwiftWasm toolchain

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenImageIO.git", from: "1.0.0")
]
```

Then add `OpenImageIO` to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["OpenImageIO"]
)
```

## Usage

### Reading Images

```swift
import OpenImageIO

// Create image source from data
let source = CGImageSourceCreateWithData(imageData, nil)

// Get image count (useful for animated GIFs)
let count = CGImageSourceGetCount(source!)

// Get image type
let type = CGImageSourceGetType(source!) // e.g., "public.png"

// Extract image at index
let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
print("Size: \(image!.width) x \(image!.height)")
```

### Creating Thumbnails

```swift
let options: [String: Any] = [
    kCGImageSourceThumbnailMaxPixelSize: 200,
    kCGImageSourceCreateThumbnailFromImageAlways: true
]

let thumbnail = CGImageSourceCreateThumbnailAtIndex(source!, 0, options)
```

### Reading Image Properties

```swift
let properties = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)

// Access dimensions
let width = properties![kCGImagePropertyPixelWidth as String] as? Int
let height = properties![kCGImagePropertyPixelHeight as String] as? Int

// Access EXIF data
if let exif = properties![kCGImagePropertyExifDictionary as String] as? [String: Any] {
    let exposureTime = exif[kCGImagePropertyExifExposureTime as String]
    let fNumber = exif[kCGImagePropertyExifFNumber as String]
}

// Access GPS data
if let gps = properties![kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    let latitude = gps[kCGImagePropertyGPSLatitude as String]
    let longitude = gps[kCGImagePropertyGPSLongitude as String]
}
```

### Writing Images

```swift
var data = Data()
let destination = CGImageDestinationCreateWithData(
    &data,
    "public.png",
    1,
    nil
)!

CGImageDestinationAddImage(destination, image, nil)

if CGImageDestinationFinalize(destination) {
    let encodedPNG = CGImageDestinationCopyData(destination)
}
```

### Writing JPEG with Quality

```swift
let options: [String: Any] = [
    kCGImageDestinationLossyCompressionQuality: 0.8
]

let destination = CGImageDestinationCreateWithData(
    &data,
    "public.jpeg",
    1,
    nil
)!

CGImageDestinationAddImage(destination, image, options)
CGImageDestinationFinalize(destination)
```

### Working with Metadata

```swift
// Create mutable metadata
let metadata = CGImageMetadataCreateMutable()

// Set values
CGImageMetadataSetValueWithPath(metadata, nil, "dc:title", "My Photo")

// Read values
let title = CGImageMetadataCopyStringValueWithPath(
    metadata,
    nil,
    "dc:title"
)

// Create XMP data
let xmpData = CGImageMetadataCreateXMPData(metadata, nil)
```

### Incremental Loading

```swift
let source = CGImageSourceCreateIncremental(nil)

// Feed partial data; no successful image is exposed yet.
CGImageSourceUpdateData(source, partialData, false)

// Check status
let status = CGImageSourceGetStatus(source)
if status == .statusIncomplete {
    // Wait for more data...
}

// Feed complete data
CGImageSourceUpdateData(source, completeData, true)
```

## Supported Formats

| Format | Read | Write | Type Identifier |
|--------|------|-------|-----------------|
| PNG | ✅ | ✅ | `public.png` |
| JPEG | ✅ | ✅ | `public.jpeg` |
| GIF | ✅ | ✅ | `com.compuserve.gif` |
| BMP | ✅ | ✅ | `com.microsoft.bmp` |
| TIFF | ✅ | ✅ | `public.tiff` |

### Unsupported Formats

| Format | Status | Reason |
|--------|--------|--------|
| WebP | ❌ | Container detection and metadata constants do not constitute a conforming VP8/VP8L pixel codec |
| HEIF/HEIC | ❌ | Requires HEVC (H.265) codec - complex implementation with patent licensing |
| AVIF | ❌ | Requires AV1 codec |
| RAW | ❌ | Camera-specific formats (CR2, NEF, ARW, etc.) |

> **Note**: HEIF/HEIC support would require implementing an HEVC decoder (thousands of lines of code) or using external libraries like `libheif` compiled to WebAssembly.

## Metadata Status

| Area | Status |
|---|---|
| Standalone XMP | Parsed and serialized with RDF arrays, structures, qualifiers, and namespaces |
| Image dimensions / color model / depth | Returned for exercised codec paths |
| EXIF, IPTC, GPS, maker notes | Public property-key constants are present; embedded payload extraction is not yet implemented |
| Auxiliary images | Not advertised; source lookup returns `nil` and destination finalization fails when auxiliary data is supplied |

## Incremental and Concurrency Contracts

`CGImageSource` publishes one coherent immutable snapshot for type, count,
properties, status, and decoded pixels. Incremental updates parse outside the
state lock and commit only when their generation is still current. A partial
recognized header reports `.statusReadingHeader` or `.statusIncomplete`
without being treated as a completed pixel decode.

`CGImageDestination` captures image bytes and supported properties when an
image is added. Finalization transitions atomically from collecting to
finalizing, performs encoding and output I/O outside the lock, and publishes
the result only for the matching finalization token.

`CGImageMetadata` protects tags and namespace registrations as one state.
Reads use coherent snapshots, compound mutations hold one lock, and mutable
copies own independent state. Metadata tag values are captured into immutable
typed storage at creation; unsupported values, including unsupported values
nested inside arrays or dictionaries, fail at the creation boundary.

## Building

```bash
# Build for the current platform with the fixed toolchain
TOOLCHAINS=org.swift.64202607171a xcrun swift build

# Run a focused native test target with a 30-second process timeout
perl -e 'alarm 30; exec @ARGV' -- \
  xcodebuild test -scheme OpenImageIO -destination 'platform=macOS' \
  -only-testing:OpenImageIOTests

# Build for WebAssembly with the matching Swift 6.4 SDK
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm
```

## WASM-Build Smoke Test

OpenImageIO is a pure-Swift codec library with no WebGPU dependency. Its E2E
suite builds a WASM smoke executable and runs the generated module in a real
browser, in addition to the package build check:

```bash
bash Tests/wasm-build.sh
cd Tests/e2e && npm run build && npm test
```

The current verified baseline is maintained in `QUALITY_CHECKLIST.md`. It
includes native tests, bidirectional Apple ImageIO conformance for
PNG/JPEG/GIF/BMP/TIFF, a Swift WASM PNG pixel roundtrip, and Chromium decode
checks for PNG/JPEG/GIF/BMP. This is evidence for those exercised paths, not a
claim of complete ImageIO parity.

## Foundation boundary

OpenImageIO imports `OpenFoundation` for Foundation-compatible values and URL-backed
`Data` operations. It does not choose `Foundation` or `FoundationEssentials` itself.
Full Swift therefore uses the pinned toolchain Foundation identity, while an Embedded
application selects `OpenFoundationEmbeddedFileSystem` only at its composition root
when file-backed ImageIO is part of that deployment.

## Cross-Platform Pattern

The recommended pattern for cross-platform code:

```swift
#if canImport(ImageIO)
import ImageIO
import CoreGraphics
#else
import OpenImageIO
#endif

func processImage(data: Data) -> (width: Int, height: Int)? {
    #if canImport(ImageIO)
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }
    #else
    guard let source = CGImageSourceCreateWithData(data, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }
    #endif

    return (image.width, image.height)
}
```

## API Reference

### CGImageSource Functions

| Function | Description |
|----------|-------------|
| `CGImageSourceCreateWithData` | Create source from data |
| `CGImageSourceCreateWithURL` | Create source from file URL |
| `CGImageSourceCreateWithDataProvider` | Create source from data provider |
| `CGImageSourceCreateIncremental` | Create incremental source |
| `CGImageSourceGetCount` | Get number of images |
| `CGImageSourceGetType` | Get image format type |
| `CGImageSourceGetStatus` | Get loading status |
| `CGImageSourceCreateImageAtIndex` | Extract image |
| `CGImageSourceCreateThumbnailAtIndex` | Create thumbnail |
| `CGImageSourceCopyProperties` | Get source properties |
| `CGImageSourceCopyPropertiesAtIndex` | Get image properties |
| `CGImageSourceUpdateData` | Update incremental source |

### CGImageDestination Functions

| Function | Description |
|----------|-------------|
| `CGImageDestinationCreateWithData` | Create destination to data |
| `CGImageDestinationCreateWithURL` | Create destination to file |
| `CGImageDestinationCreateWithDataConsumer` | Create destination to consumer |
| `CGImageDestinationAddImage` | Add image to destination |
| `CGImageDestinationAddImageFromSource` | Add image from source |
| `CGImageDestinationSetProperties` | Set destination properties |
| `CGImageDestinationFinalize` | Finalize and write output |

### CGImageMetadata Functions

| Function | Description |
|----------|-------------|
| `CGImageMetadataCreateMutable` | Create mutable metadata |
| `CGImageMetadataCreateMutableCopy` | Copy metadata |
| `CGImageMetadataCopyTags` | Get all tags |
| `CGImageMetadataCopyTagWithPath` | Get tag by path |
| `CGImageMetadataSetValueWithPath` | Set value |
| `CGImageMetadataRemoveTagWithPath` | Remove tag |
| `CGImageMetadataCreateXMPData` | Serialize to XMP |
| `CGImageMetadataCreateFromXMPData` | Parse from XMP |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

This library aims to provide API compatibility with Apple's [ImageIO](https://developer.apple.com/documentation/imageio) framework, enabling Swift developers to write cross-platform image handling code.
