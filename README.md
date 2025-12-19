# OpenImageIO

A Swift library providing **full API compatibility with Apple's ImageIO framework** for WebAssembly (WASM) and other non-Apple platforms.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
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

- **Full API Compatibility** - Identical type names, method signatures, and property names as Apple's ImageIO
- **Multiple Format Support** - PNG, JPEG, GIF, BMP, TIFF, WebP
- **Image Sources** - Read and decode image data with `CGImageSource`
- **Image Destinations** - Encode and write image data with `CGImageDestination`
- **Rich Metadata Support** - EXIF, IPTC, GPS, XMP, TIFF, and format-specific metadata
- **Manufacturer Metadata** - Canon, Nikon, Apple, and other camera maker notes
- **Incremental Loading** - Progressive image loading support
- **Thumbnail Generation** - Create thumbnails with configurable options

## Requirements

- Swift 6.2+
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
let options: CFDictionary = [
    kCGImageSourceThumbnailMaxPixelSize as String: 200,
    kCGImageSourceCreateThumbnailFromImageAlways as String: true
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
let data = CFMutableData()
let destination = CGImageDestinationCreateWithData(
    data,
    "public.png" as CFString,
    1,
    nil
)!

CGImageDestinationAddImage(destination, image, nil)

if CGImageDestinationFinalize(destination) {
    // data now contains the encoded PNG
}
```

### Writing JPEG with Quality

```swift
let options: CFDictionary = [
    kCGImageDestinationLossyCompressionQuality as String: 0.8
]

let destination = CGImageDestinationCreateWithData(
    data,
    "public.jpeg" as CFString,
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
CGImageMetadataSetValueWithPath(
    metadata,
    nil,
    "dc:title" as CFString,
    "My Photo"
)

// Read values
let title = CGImageMetadataCopyStringValueWithPath(
    metadata,
    nil,
    "dc:title" as CFString
)

// Create XMP data
let xmpData = CGImageMetadataCreateXMPData(metadata, nil)
```

### Incremental Loading

```swift
let source = CGImageSourceCreateIncremental(nil)

// Feed partial data
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
| WebP | ✅ | ✅ | `org.webmproject.webp` |

### Unsupported Formats

| Format | Status | Reason |
|--------|--------|--------|
| HEIF/HEIC | ❌ | Requires HEVC (H.265) codec - complex implementation with patent licensing |
| AVIF | ❌ | Requires AV1 codec |
| RAW | ❌ | Camera-specific formats (CR2, NEF, ARW, etc.) |

> **Note**: HEIF/HEIC support would require implementing an HEVC decoder (thousands of lines of code) or using external libraries like `libheif` compiled to WebAssembly.

## Supported Metadata

- **EXIF** - Exposure, aperture, ISO, date/time, camera settings
- **IPTC** - Copyright, caption, keywords, location
- **GPS** - Latitude, longitude, altitude, timestamps
- **TIFF** - Resolution, orientation, software, artist
- **XMP** - Dublin Core, Photoshop, IPTC Core, EXIF
- **DNG** - Complete Digital Negative metadata support
- **HEIC/HEIF** - Property keys defined (format itself not supported, see above)
- **Maker Notes** - Canon, Nikon, Apple, Fuji, Olympus, Pentax, Minolta

## Building

```bash
# Build for current platform
swift build

# Build for WebAssembly (requires SwiftWasm)
swift build --triple wasm32-unknown-wasi

# Run tests
swift test
```

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
    let cfData = data as CFData
    #else
    let cfData = CFData(bytes: Array(data))
    #endif

    guard let source = CGImageSourceCreateWithData(cfData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }

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
