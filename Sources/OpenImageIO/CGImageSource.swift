// CGImageSource.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

import Foundation

/// An opaque type that you use to read image data from a URL, data object, or data consumer.
public class CGImageSource: Hashable, Equatable {

    // MARK: - Internal Storage

    internal var imageData: [UInt8]
    internal var options: CFDictionary?
    internal var isIncremental: Bool
    internal var imageCount: Int = 0
    internal var sourceType: String?
    internal var status: CGImageSourceStatus = .statusIncomplete
    internal var properties: CFDictionary = [:]
    internal var imageProperties: [CFDictionary] = []

    // MARK: - Initialization

    internal init(data: [UInt8], options: CFDictionary?, isIncremental: Bool = false) {
        self.imageData = data
        self.options = options
        self.isIncremental = isIncremental

        if !isIncremental && !data.isEmpty {
            parseImageData()
        }
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageSource, rhs: CGImageSource) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // MARK: - Internal Methods

    internal func parseImageData() {
        // Detect image type and parse
        guard imageData.count >= 8 else {
            status = .statusInvalidData
            return
        }

        // PNG signature: 137 80 78 71 13 10 26 10
        if imageData.count >= 8 &&
           imageData[0] == 0x89 && imageData[1] == 0x50 &&
           imageData[2] == 0x4E && imageData[3] == 0x47 {
            sourceType = "public.png"
            parsePNG()
        }
        // JPEG signature: FF D8 FF
        else if imageData.count >= 3 &&
                imageData[0] == 0xFF && imageData[1] == 0xD8 && imageData[2] == 0xFF {
            sourceType = "public.jpeg"
            parseJPEG()
        }
        // GIF signature: GIF87a or GIF89a
        else if imageData.count >= 6 &&
                imageData[0] == 0x47 && imageData[1] == 0x49 && imageData[2] == 0x46 {
            sourceType = "com.compuserve.gif"
            parseGIF()
        }
        // BMP signature: BM
        else if imageData.count >= 2 &&
                imageData[0] == 0x42 && imageData[1] == 0x4D {
            sourceType = "com.microsoft.bmp"
            parseBMP()
        }
        // TIFF signature: II (little-endian) or MM (big-endian)
        else if imageData.count >= 4 &&
                ((imageData[0] == 0x49 && imageData[1] == 0x49) ||
                 (imageData[0] == 0x4D && imageData[1] == 0x4D)) {
            sourceType = "public.tiff"
            parseTIFF()
        }
        // WebP signature: RIFF....WEBP
        else if imageData.count >= 12 &&
                imageData[0] == 0x52 && imageData[1] == 0x49 &&
                imageData[2] == 0x46 && imageData[3] == 0x46 &&
                imageData[8] == 0x57 && imageData[9] == 0x45 &&
                imageData[10] == 0x42 && imageData[11] == 0x50 {
            sourceType = "org.webmproject.webp"
            parseWebP()
        }
        else {
            status = .statusUnknownType
        }
    }

    internal func parsePNG() {
        // Basic PNG parsing - extract dimensions from IHDR chunk
        guard imageData.count > 24 else {
            status = .statusInvalidData
            return
        }

        // IHDR chunk starts at byte 8, chunk length is 4 bytes, type is 4 bytes, then width/height
        let widthOffset = 16
        let heightOffset = 20

        let width = (Int(imageData[widthOffset]) << 24) |
                    (Int(imageData[widthOffset + 1]) << 16) |
                    (Int(imageData[widthOffset + 2]) << 8) |
                    Int(imageData[widthOffset + 3])

        let height = (Int(imageData[heightOffset]) << 24) |
                     (Int(imageData[heightOffset + 1]) << 16) |
                     (Int(imageData[heightOffset + 2]) << 8) |
                     Int(imageData[heightOffset + 3])

        let bitDepth = Int(imageData[24])
        let colorType = Int(imageData[25])

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyDepth as String: bitDepth,
            kCGImagePropertyColorModel as String: colorModelFromPNGColorType(colorType)
        ]
        imageProperties = [properties]
        status = .statusComplete
    }

    internal func parseJPEG() {
        // Basic JPEG parsing
        guard imageData.count > 2 else {
            status = .statusInvalidData
            return
        }

        var offset = 2
        var width = 0
        var height = 0

        while offset < imageData.count - 1 {
            guard imageData[offset] == 0xFF else {
                offset += 1
                continue
            }

            let marker = imageData[offset + 1]

            // SOF markers (Start of Frame)
            if marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC {
                if offset + 9 < imageData.count {
                    height = (Int(imageData[offset + 5]) << 8) | Int(imageData[offset + 6])
                    width = (Int(imageData[offset + 7]) << 8) | Int(imageData[offset + 8])
                    break
                }
            }

            if marker == 0xD9 || marker == 0xDA {
                break
            }

            if offset + 3 < imageData.count {
                let length = (Int(imageData[offset + 2]) << 8) | Int(imageData[offset + 3])
                offset += 2 + length
            } else {
                break
            }
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        status = .statusComplete
    }

    internal func parseGIF() {
        guard imageData.count > 10 else {
            status = .statusInvalidData
            return
        }

        let width = Int(imageData[6]) | (Int(imageData[7]) << 8)
        let height = Int(imageData[8]) | (Int(imageData[9]) << 8)

        // Count frames for animated GIF
        var frameCount = 0
        var offset = 13 // Skip header and logical screen descriptor

        // Skip global color table if present
        let flags = imageData[10]
        if flags & 0x80 != 0 {
            let colorTableSize = 1 << ((flags & 0x07) + 1)
            offset += colorTableSize * 3
        }

        while offset < imageData.count {
            if imageData[offset] == 0x2C { // Image descriptor
                frameCount += 1
                offset += 10
                // Skip local color table if present
                if offset < imageData.count {
                    let localFlags = imageData[offset - 1]
                    if localFlags & 0x80 != 0 {
                        let localColorTableSize = 1 << ((localFlags & 0x07) + 1)
                        offset += localColorTableSize * 3
                    }
                }
            } else if imageData[offset] == 0x21 { // Extension
                offset += 2
                while offset < imageData.count && imageData[offset] != 0 {
                    offset += Int(imageData[offset]) + 1
                }
                offset += 1
            } else if imageData[offset] == 0x3B { // Trailer
                break
            } else {
                offset += 1
            }
        }

        imageCount = max(frameCount, 1)
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB,
            kCGImagePropertyImageCount as String: imageCount
        ]

        // Create properties for each frame
        imageProperties = (0..<imageCount).map { _ in
            [
                kCGImagePropertyPixelWidth as String: width,
                kCGImagePropertyPixelHeight as String: height
            ]
        }

        status = .statusComplete
    }

    internal func parseBMP() {
        guard imageData.count > 26 else {
            status = .statusInvalidData
            return
        }

        // BMP header: width at offset 18, height at offset 22 (4 bytes each, little-endian)
        let width = Int(imageData[18]) | (Int(imageData[19]) << 8) |
                    (Int(imageData[20]) << 16) | (Int(imageData[21]) << 24)
        var height = Int(imageData[22]) | (Int(imageData[23]) << 8) |
                     (Int(imageData[24]) << 16) | (Int(imageData[25]) << 24)

        // Height can be negative for top-down DIB
        if height < 0 {
            height = -height
        }

        let bitsPerPixel = Int(imageData[28]) | (Int(imageData[29]) << 8)

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyDepth as String: bitsPerPixel,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        status = .statusComplete
    }

    internal func parseTIFF() {
        guard imageData.count > 8 else {
            status = .statusInvalidData
            return
        }

        let isLittleEndian = imageData[0] == 0x49

        func readUInt16(at offset: Int) -> Int {
            if isLittleEndian {
                return Int(imageData[offset]) | (Int(imageData[offset + 1]) << 8)
            } else {
                return (Int(imageData[offset]) << 8) | Int(imageData[offset + 1])
            }
        }

        func readUInt32(at offset: Int) -> Int {
            if isLittleEndian {
                return Int(imageData[offset]) | (Int(imageData[offset + 1]) << 8) |
                       (Int(imageData[offset + 2]) << 16) | (Int(imageData[offset + 3]) << 24)
            } else {
                return (Int(imageData[offset]) << 24) | (Int(imageData[offset + 1]) << 16) |
                       (Int(imageData[offset + 2]) << 8) | Int(imageData[offset + 3])
            }
        }

        // IFD offset at byte 4
        var ifdOffset = readUInt32(at: 4)
        var width = 0
        var height = 0

        if ifdOffset > 0 && ifdOffset + 2 < imageData.count {
            let numEntries = readUInt16(at: ifdOffset)
            var entryOffset = ifdOffset + 2

            for _ in 0..<numEntries {
                guard entryOffset + 12 <= imageData.count else { break }

                let tag = readUInt16(at: entryOffset)
                let value = readUInt32(at: entryOffset + 8)

                if tag == 256 { // ImageWidth
                    width = value
                } else if tag == 257 { // ImageLength
                    height = value
                }

                entryOffset += 12
            }
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        status = .statusComplete
    }

    internal func parseWebP() {
        guard imageData.count > 30 else {
            status = .statusInvalidData
            return
        }

        // WebP format: RIFF size WEBP chunk
        var width = 0
        var height = 0
        var offset = 12

        while offset + 8 < imageData.count {
            let chunkType = String(bytes: imageData[offset..<offset+4], encoding: .ascii) ?? ""

            if chunkType == "VP8 " {
                // Lossy WebP
                if offset + 14 < imageData.count {
                    let frameOffset = offset + 10
                    width = Int(imageData[frameOffset + 6]) | ((Int(imageData[frameOffset + 7]) & 0x3F) << 8)
                    height = Int(imageData[frameOffset + 8]) | ((Int(imageData[frameOffset + 9]) & 0x3F) << 8)
                }
                break
            } else if chunkType == "VP8L" {
                // Lossless WebP
                if offset + 15 < imageData.count {
                    let signature = imageData[offset + 8]
                    if signature == 0x2F {
                        let bits = UInt32(imageData[offset + 9]) |
                                  (UInt32(imageData[offset + 10]) << 8) |
                                  (UInt32(imageData[offset + 11]) << 16) |
                                  (UInt32(imageData[offset + 12]) << 24)
                        width = Int((bits & 0x3FFF) + 1)
                        height = Int(((bits >> 14) & 0x3FFF) + 1)
                    }
                }
                break
            } else if chunkType == "VP8X" {
                // Extended WebP
                if offset + 18 < imageData.count {
                    width = (Int(imageData[offset + 12]) |
                            (Int(imageData[offset + 13]) << 8) |
                            (Int(imageData[offset + 14]) << 16)) + 1
                    height = (Int(imageData[offset + 15]) |
                             (Int(imageData[offset + 16]) << 8) |
                             (Int(imageData[offset + 17]) << 16)) + 1
                }
                break
            }

            let chunkSize = Int(imageData[offset + 4]) |
                           (Int(imageData[offset + 5]) << 8) |
                           (Int(imageData[offset + 6]) << 16) |
                           (Int(imageData[offset + 7]) << 24)
            offset += 8 + chunkSize + (chunkSize & 1) // Padding to even
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth as String: width,
            kCGImagePropertyPixelHeight as String: height,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        status = .statusComplete
    }

    private func colorModelFromPNGColorType(_ colorType: Int) -> String {
        switch colorType {
        case 0: return kCGImagePropertyColorModelGray as String
        case 2, 6: return kCGImagePropertyColorModelRGB as String
        case 3: return kCGImagePropertyColorModelRGB as String // Indexed
        case 4: return kCGImagePropertyColorModelGray as String // Gray + Alpha
        default: return kCGImagePropertyColorModelRGB as String
        }
    }
}

// MARK: - CGImageSource Creation Functions

/// Creates an image source that reads from a location specified by a URL.
public func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource? {
    // Read file data
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: url.path)) else {
        return nil
    }
    return CGImageSource(data: Array(data), options: options)
}

/// Creates an image source that reads from a Core Foundation data object.
public func CGImageSourceCreateWithData(_ data: CFData, _ options: CFDictionary?) -> CGImageSource? {
    return CGImageSource(data: data.data, options: options)
}

/// Creates an image source that reads data from the specified data provider.
public func CGImageSourceCreateWithDataProvider(_ provider: CGDataProvider, _ options: CFDictionary?) -> CGImageSource? {
    return CGImageSource(data: provider.data, options: options)
}

/// Creates an empty image source that you can use to accumulate incremental image data.
public func CGImageSourceCreateIncremental(_ options: CFDictionary?) -> CGImageSource {
    return CGImageSource(data: [], options: options, isIncremental: true)
}

// MARK: - CGImageSource Information Functions

/// Returns the unique type identifier of an image source opaque type.
public func CGImageSourceGetTypeID() -> CFTypeID {
    return 0 // Placeholder - actual implementation would return unique ID
}

/// Returns the uniform type identifier of the source container.
public func CGImageSourceGetType(_ isrc: CGImageSource) -> CFString? {
    return isrc.sourceType as CFString?
}

/// Returns an array of uniform type identifiers that are supported for image sources.
public func CGImageSourceCopyTypeIdentifiers() -> CFArray {
    return [
        "public.png",
        "public.jpeg",
        "com.compuserve.gif",
        "com.microsoft.bmp",
        "public.tiff",
        "org.webmproject.webp"
    ] as CFArray
}

/// Returns the number of images (not including thumbnails) in the image source.
public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int {
    return isrc.imageCount
}

/// Returns the properties of the image source.
public func CGImageSourceCopyProperties(_ isrc: CGImageSource, _ options: CFDictionary?) -> CFDictionary? {
    return isrc.properties
}

/// Returns the properties of the image at a specified location in an image source.
public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CFDictionary? {
    guard index >= 0 && index < isrc.imageProperties.count else {
        return nil
    }
    return isrc.imageProperties[index]
}

/// Returns auxiliary data, such as mattes and depth information, that accompany the image.
public func CGImageSourceCopyAuxiliaryDataInfoAtIndex(_ isrc: CGImageSource, _ index: Int, _ auxiliaryImageDataType: CFString) -> CFDictionary? {
    // Placeholder - auxiliary data parsing not implemented
    return nil
}

// MARK: - CGImageSource Image Extraction Functions

/// Creates an image object from the data at the specified index in an image source.
public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage? {
    guard index >= 0 && index < isrc.imageCount else {
        return nil
    }

    // Placeholder implementation - actual decoding would be needed
    // For now, return a placeholder CGImage
    guard let props = CGImageSourceCopyPropertiesAtIndex(isrc, index, options),
          let width = props[kCGImagePropertyPixelWidth as String] as? Int,
          let height = props[kCGImagePropertyPixelHeight as String] as? Int else {
        return nil
    }

    // Create empty image data
    let bytesPerRow = width * 4
    let data = [UInt8](repeating: 0, count: bytesPerRow * height)

    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        data: data
    )
}

/// Creates a thumbnail version of the image at the specified index in an image source.
public func CGImageSourceCreateThumbnailAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage? {
    guard index >= 0 && index < isrc.imageCount else {
        return nil
    }

    // Get original dimensions
    guard let props = CGImageSourceCopyPropertiesAtIndex(isrc, index, nil),
          let width = props[kCGImagePropertyPixelWidth as String] as? Int,
          let height = props[kCGImagePropertyPixelHeight as String] as? Int else {
        return nil
    }

    // Calculate thumbnail dimensions
    var thumbWidth = width
    var thumbHeight = height

    if let maxPixelSize = options?[kCGImageSourceThumbnailMaxPixelSize as String] as? Int {
        let scale = min(Double(maxPixelSize) / Double(width), Double(maxPixelSize) / Double(height))
        if scale < 1.0 {
            thumbWidth = Int(Double(width) * scale)
            thumbHeight = Int(Double(height) * scale)
        }
    }

    // Create thumbnail (placeholder)
    let bytesPerRow = thumbWidth * 4
    let data = [UInt8](repeating: 0, count: bytesPerRow * thumbHeight)

    return CGImage(
        width: thumbWidth,
        height: thumbHeight,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        data: data
    )
}

/// Returns the index of the primary image for an High Efficiency Image File Format (HEIF) image.
public func CGImageSourceGetPrimaryImageIndex(_ isrc: CGImageSource) -> Int {
    return 0
}

// MARK: - CGImageSource Status Functions

/// Return the status of an image source.
public func CGImageSourceGetStatus(_ isrc: CGImageSource) -> CGImageSourceStatus {
    return isrc.status
}

/// Returns the current status of an image at the specified location in the image source.
public func CGImageSourceGetStatusAtIndex(_ isrc: CGImageSource, _ index: Int) -> CGImageSourceStatus {
    guard index >= 0 && index < isrc.imageCount else {
        return .statusInvalidData
    }
    return isrc.status
}

// MARK: - CGImageSource Incremental Functions

/// Updates the data in an incremental image source.
public func CGImageSourceUpdateData(_ isrc: CGImageSource, _ data: CFData, _ final: Bool) {
    isrc.imageData = data.data
    if final {
        isrc.parseImageData()
    } else {
        isrc.status = .statusIncomplete
    }
}

/// Updates an incremental image source with a new data provider.
public func CGImageSourceUpdateDataProvider(_ isrc: CGImageSource, _ provider: CGDataProvider, _ final: Bool) {
    isrc.imageData = provider.data
    if final {
        isrc.parseImageData()
    } else {
        isrc.status = .statusIncomplete
    }
}

// MARK: - CGImageSource Options Keys

/// The uniform type identifier that represents your best guess for the image's type.
public let kCGImageSourceTypeIdentifierHint: CFString = "kCGImageSourceTypeIdentifierHint"

/// A Boolean that indicates whether to use floating-point values in returned images.
public let kCGImageSourceShouldAllowFloat: CFString = "kCGImageSourceShouldAllowFloat"

/// A Boolean value that indicates whether to cache the decoded image.
public let kCGImageSourceShouldCache: CFString = "kCGImageSourceShouldCache"

/// A Boolean value that indicates whether image decoding and caching happens at image creation time.
public let kCGImageSourceShouldCacheImmediately: CFString = "kCGImageSourceShouldCacheImmediately"

/// A Boolean value that indicates whether to create a thumbnail image automatically
/// if the data source doesn't contain one.
public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString = "kCGImageSourceCreateThumbnailFromImageIfAbsent"

/// A Boolean value that indicates whether to always create a thumbnail image.
public let kCGImageSourceCreateThumbnailFromImageAlways: CFString = "kCGImageSourceCreateThumbnailFromImageAlways"

/// The maximum width and height of a thumbnail image, specified in pixels.
public let kCGImageSourceThumbnailMaxPixelSize: CFString = "kCGImageSourceThumbnailMaxPixelSize"

/// A Boolean value that indicates whether to rotate and scale the thumbnail image
/// to match the image's orientation and aspect ratio.
public let kCGImageSourceCreateThumbnailWithTransform: CFString = "kCGImageSourceCreateThumbnailWithTransform"

/// The factor by which to scale down any returned images.
public let kCGImageSourceSubsampleFactor: CFString = "kCGImageSourceSubsampleFactor"

/// A Boolean value that indicates whether to generate image-specific luma scaling.
public let kCGImageSourceGenerateImageSpecificLumaScaling: CFString = "kCGImageSourceGenerateImageSpecificLumaScaling"
