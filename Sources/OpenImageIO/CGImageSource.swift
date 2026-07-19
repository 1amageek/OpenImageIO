// CGImageSource.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import Foundation
import OpenCoreGraphics

/// An opaque type that you use to read image data from a URL, data object, or data consumer.
public class CGImageSource: Hashable, Equatable {

    // MARK: - Internal Storage

    internal var imageData: Data
    internal var options: [String: Any]?
    internal var isIncremental: Bool
    internal var imageCount: Int = 0
    internal var sourceType: String?
    internal var status: CGImageSourceStatus = .statusIncomplete
    internal var properties: [String: Any] = [:]
    internal var imageProperties: [[String: Any]] = []
    internal var decodedImages: [CGImage] = []
    /// Auxiliary data by image index. Key is auxiliary data type (e.g., kCGImageAuxiliaryDataTypeHDRGainMap).
    internal var auxiliaryDataByIndex: [[String: [String: Any]]] = []

    // MARK: - Initialization

    internal init(data: Data, options: [String: Any]?, isIncremental: Bool = false) {
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
        sourceType = nil
        imageCount = 0
        properties = [:]
        imageProperties = []
        decodedImages = []
        auxiliaryDataByIndex = []

        // Detect image type and parse
        guard imageData.count >= 8 else {
            status = .statusInvalidData
            return
        }

        imageData.withUnsafeBytes { buffer in
            guard let bytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                status = .statusInvalidData
                return
            }

            // PNG signature: 137 80 78 71 13 10 26 10
            if imageData.count >= 8 &&
               bytes[0] == 0x89 && bytes[1] == 0x50 &&
               bytes[2] == 0x4E && bytes[3] == 0x47 {
                sourceType = "public.png"
                parsePNG(bytes: bytes, count: imageData.count)
            }
            // JPEG signature: FF D8 FF
            else if imageData.count >= 3 &&
                    bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
                sourceType = "public.jpeg"
                parseJPEG()
            }
            // GIF signature: GIF87a or GIF89a
            else if imageData.count >= 6 &&
                    bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 {
                sourceType = "com.compuserve.gif"
                parseGIF(bytes: bytes, count: imageData.count)
            }
            // BMP signature: BM
            else if imageData.count >= 2 &&
                    bytes[0] == 0x42 && bytes[1] == 0x4D {
                sourceType = "com.microsoft.bmp"
                parseBMP(bytes: bytes, count: imageData.count)
            }
            // TIFF signature: II (little-endian) or MM (big-endian)
            else if imageData.count >= 4 &&
                    ((bytes[0] == 0x49 && bytes[1] == 0x49) ||
                     (bytes[0] == 0x4D && bytes[1] == 0x4D)) {
                sourceType = "public.tiff"
                parseTIFF()
            }
            else {
                status = .statusUnknownType
            }
        }
    }

    internal func parsePNG(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 25,
              let decoded = PNGDecoder.decode(data: imageData),
              let image = makeDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: decoded.hasAlpha
              ) else {
            status = .statusInvalidData
            return
        }

        // IHDR chunk starts at byte 8, chunk length is 4 bytes, type is 4 bytes, then width/height
        let widthOffset = 16
        let heightOffset = 20

        let headerWidth = (Int(bytes[widthOffset]) << 24) |
                          (Int(bytes[widthOffset + 1]) << 16) |
                          (Int(bytes[widthOffset + 2]) << 8) |
                          Int(bytes[widthOffset + 3])

        let headerHeight = (Int(bytes[heightOffset]) << 24) |
                           (Int(bytes[heightOffset + 1]) << 16) |
                           (Int(bytes[heightOffset + 2]) << 8) |
                           Int(bytes[heightOffset + 3])
        guard decoded.width == headerWidth, decoded.height == headerHeight else {
            status = .statusInvalidData
            return
        }

        let bitDepth = Int(bytes[24])
        let colorType = Int(bytes[25])

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: decoded.width,
            kCGImagePropertyPixelHeight: decoded.height,
            kCGImagePropertyDepth: bitDepth,
            kCGImagePropertyColorModel: colorModelFromPNGColorType(colorType)
        ]
        imageProperties = [properties]
        decodedImages = [image]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseJPEG() {
        guard imageData.count > 2,
              let decoded = JPEGDecoder.decode(data: imageData),
              let image = makeDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: false
              ) else {
            status = .statusInvalidData
            return
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: decoded.width,
            kCGImagePropertyPixelHeight: decoded.height,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        decodedImages = [image]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseGIF(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 12 else {
            status = .statusInvalidData
            return
        }

        let width = Int(bytes[6]) | (Int(bytes[7]) << 8)
        let height = Int(bytes[8]) | (Int(bytes[9]) << 8)
        let frameCount = GIFDecoder.frameCount(data: imageData)
        guard frameCount > 0 else {
            status = .statusInvalidData
            return
        }
        var frames: [CGImage] = []
        frames.reserveCapacity(frameCount)
        for index in 0..<frameCount {
            guard let decoded = GIFDecoder.decode(data: imageData, frameIndex: index),
                  decoded.width == width,
                  decoded.height == height,
                  let image = makeDecodedImage(
                    pixels: decoded.pixels,
                    width: decoded.width,
                    height: decoded.height,
                    hasAlpha: decoded.hasAlpha
                  ) else {
                status = .statusInvalidData
                return
            }
            frames.append(image)
        }
        imageCount = frameCount
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
            kCGImagePropertyImageCount: imageCount
        ]

        // Create properties for each frame
        imageProperties = (0..<imageCount).map { _ in
            [
                kCGImagePropertyPixelWidth: width,
                kCGImagePropertyPixelHeight: height
            ]
        }
        decodedImages = frames
        auxiliaryDataByIndex = (0..<imageCount).map { _ in [:] }

        status = .statusComplete
    }

    internal func parseBMP(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count >= 30,
              let decoded = BMPDecoder.decode(data: imageData),
              let image = makeDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: decoded.hasAlpha
              ) else {
            status = .statusInvalidData
            return
        }

        // BMP header: width at offset 18, height at offset 22 (4 bytes each, little-endian)
        let width = decoded.width
        let height = decoded.height

        let bitsPerPixel = Int(bytes[28]) | (Int(bytes[29]) << 8)

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyDepth: bitsPerPixel,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        decodedImages = [image]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseTIFF() {
        let pageCount = TIFFDecoder.pageCount(data: imageData)
        guard pageCount > 0 else {
            status = .statusInvalidData
            return
        }

        var pages: [CGImage] = []
        var perPageProperties: [[String: Any]] = []
        pages.reserveCapacity(pageCount)
        perPageProperties.reserveCapacity(pageCount)

        for index in 0..<pageCount {
            guard let page = TIFFDecoder.decode(data: imageData, frameIndex: index),
                  let image = makeDecodedImage(
                    pixels: page.pixels,
                    width: page.width,
                    height: page.height,
                    hasAlpha: page.hasAlpha
                  ) else {
                status = .statusInvalidData
                return
            }
            pages.append(image)
            perPageProperties.append([
                kCGImagePropertyPixelWidth: page.width,
                kCGImagePropertyPixelHeight: page.height,
                kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
            ])
        }

        imageCount = pageCount
        // Top-level `properties` describes the first image for backward
        // compatibility with single-page callers.
        properties = perPageProperties[0]
        if imageCount > 1 {
            properties[kCGImagePropertyImageCount] = imageCount
        }
        imageProperties = perPageProperties
        decodedImages = pages
        auxiliaryDataByIndex = Array(repeating: [:], count: imageCount)
        status = .statusComplete
    }

    private func colorModelFromPNGColorType(_ colorType: Int) -> String {
        switch colorType {
        case 0: return kCGImagePropertyColorModelGray
        case 2, 6: return kCGImagePropertyColorModelRGB
        case 3: return kCGImagePropertyColorModelRGB // Indexed
        case 4: return kCGImagePropertyColorModelGray // Gray + Alpha
        default: return kCGImagePropertyColorModelRGB
        }
    }
}

private func makeDecodedImage(
    pixels: Data,
    width: Int,
    height: Int,
    hasAlpha: Bool
) -> CGImage? {
    guard width > 0, height > 0 else { return nil }
    let (pixelCount, pixelCountOverflow) = width.multipliedReportingOverflow(by: height)
    let (byteCount, byteCountOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
    guard !pixelCountOverflow,
          !byteCountOverflow,
          pixels.count == byteCount,
          let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        return nil
    }
    let alphaInfo: CGImageAlphaInfo = hasAlpha ? .premultipliedLast : .noneSkipLast
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
        provider: CGDataProvider(data: pixels),
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    )
}

// MARK: - CGImageSource Creation Functions

/// Creates an image source that reads from a location specified by a URL.
public func CGImageSourceCreateWithURL(_ url: URL, _ options: [String: Any]?) -> CGImageSource? {
    // Surface the underlying error via the logging stream instead of
    // swallowing it with `try?` — a missing / unreadable file is a
    // legitimate nil-returning path, but the failure reason should be
    // discoverable.
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        print("CGImageSourceCreateWithURL: failed to read \(url): \(error)")
        return nil
    }
    return CGImageSource(data: data, options: options)
}

/// Creates an image source that reads from a Data object.
public func CGImageSourceCreateWithData(_ data: Data, _ options: [String: Any]?) -> CGImageSource? {
    return CGImageSource(data: data, options: options)
}

/// Creates an image source that reads data from the specified data provider.
///
/// Materialises every byte of the provider into a Swift `Data` value.
public func CGImageSourceCreateWithDataProvider(_ provider: CGDataProvider, _ options: [String: Any]?) -> CGImageSource? {
    guard let data = provider.data else { return nil }
    return CGImageSource(data: data, options: options)
}

/// Creates an empty image source that you can use to accumulate incremental image data.
public func CGImageSourceCreateIncremental(_ options: [String: Any]?) -> CGImageSource {
    return CGImageSource(data: Data(), options: options, isIncremental: true)
}

// MARK: - CGImageSource Information Functions


/// Returns the uniform type identifier of the source container.
public func CGImageSourceGetType(_ isrc: CGImageSource) -> String? {
    return isrc.sourceType
}

/// Returns an array of uniform type identifiers that are supported for image sources.
public func CGImageSourceCopyTypeIdentifiers() -> [String] {
    return [
        "public.png",
        "public.jpeg",
        "com.compuserve.gif",
        "com.microsoft.bmp",
        "public.tiff"
    ]
}

/// Returns the number of images (not including thumbnails) in the image source.
public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int {
    return isrc.imageCount
}

/// Returns the properties of the image source.
public func CGImageSourceCopyProperties(_ isrc: CGImageSource, _ options: [String: Any]?) -> [String: Any]? {
    return isrc.properties
}

/// Returns the properties of the image at a specified location in an image source.
public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> [String: Any]? {
    guard index >= 0 && index < isrc.imageProperties.count else {
        return nil
    }
    return isrc.imageProperties[index]
}

/// Returns auxiliary data, such as mattes and depth information, that accompany the image.
public func CGImageSourceCopyAuxiliaryDataInfoAtIndex(_ isrc: CGImageSource, _ index: Int, _ auxiliaryImageDataType: String) -> [String: Any]? {
    guard index >= 0 && index < isrc.auxiliaryDataByIndex.count else {
        return nil
    }
    return isrc.auxiliaryDataByIndex[index][auxiliaryImageDataType]
}

// MARK: - CGImageSource Image Extraction Functions

/// Creates an image object from the data at the specified index in an image source.
public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> CGImage? {
    guard index >= 0 && index < isrc.decodedImages.count else { return nil }
    return isrc.decodedImages[index]
}

/// Creates a thumbnail version of the image at the specified index in an image source.
public func CGImageSourceCreateThumbnailAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> CGImage? {
    // First decode the full image
    guard let fullImage = CGImageSourceCreateImageAtIndex(isrc, index, nil) else {
        return nil
    }

    let width = fullImage.width
    let height = fullImage.height

    // Calculate thumbnail dimensions
    var thumbWidth = width
    var thumbHeight = height

    if let opts = options,
       let maxPixelSize = opts[kCGImageSourceThumbnailMaxPixelSize] as? Int {
        let scale = min(Double(maxPixelSize) / Double(width), Double(maxPixelSize) / Double(height))
        if scale < 1.0 {
            thumbWidth = Int(Double(width) * scale)
            thumbHeight = Int(Double(height) * scale)
        }
    }

    // If no scaling needed, return the original
    if thumbWidth == width && thumbHeight == height {
        return fullImage
    }

    // Create scaled thumbnail using simple bilinear interpolation
    guard let srcData = fullImage.dataProvider?.data else {
        return nil
    }

    var thumbPixels = [UInt8](repeating: 0, count: thumbWidth * thumbHeight * 4)

    let xRatio = Double(width) / Double(thumbWidth)
    let yRatio = Double(height) / Double(thumbHeight)

    for y in 0..<thumbHeight {
        for x in 0..<thumbWidth {
            let srcX = Int(Double(x) * xRatio)
            let srcY = Int(Double(y) * yRatio)

            let srcIndex = (srcY * width + srcX) * 4
            let dstIndex = (y * thumbWidth + x) * 4

            if srcIndex + 3 < srcData.count {
                thumbPixels[dstIndex] = srcData[srcIndex]
                thumbPixels[dstIndex + 1] = srcData[srcIndex + 1]
                thumbPixels[dstIndex + 2] = srcData[srcIndex + 2]
                thumbPixels[dstIndex + 3] = srcData[srcIndex + 3]
            }
        }
    }

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        return nil
    }

    let bytesPerRow = thumbWidth * 4
    let provider = CGDataProvider(data: Data(thumbPixels))

    return CGImage(
        width: thumbWidth,
        height: thumbHeight,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: fullImage.bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
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
public func CGImageSourceUpdateData(_ isrc: CGImageSource, _ data: Data, _ final: Bool) {
    isrc.imageData = data
    if final {
        isrc.parseImageData()
    } else {
        isrc.status = .statusIncomplete
    }
}

/// Updates an incremental image source with a new data provider.
///
/// Uses the provider's materialised data snapshot.
public func CGImageSourceUpdateDataProvider(_ isrc: CGImageSource, _ provider: CGDataProvider, _ final: Bool) {
    if let data = provider.data {
        isrc.imageData = data
    }
    if final {
        isrc.parseImageData()
    } else {
        isrc.status = .statusIncomplete
    }
}

// MARK: - CGImageSource Options Keys

/// The uniform type identifier that represents your best guess for the image's type.
public let kCGImageSourceTypeIdentifierHint: String = "kCGImageSourceTypeIdentifierHint"

/// A Boolean that indicates whether to use floating-point values in returned images.
public let kCGImageSourceShouldAllowFloat: String = "kCGImageSourceShouldAllowFloat"

/// A Boolean value that indicates whether to cache the decoded image.
public let kCGImageSourceShouldCache: String = "kCGImageSourceShouldCache"

/// A Boolean value that indicates whether image decoding and caching happens at image creation time.
public let kCGImageSourceShouldCacheImmediately: String = "kCGImageSourceShouldCacheImmediately"

/// A Boolean value that indicates whether to create a thumbnail image automatically
/// if the data source doesn't contain one.
public let kCGImageSourceCreateThumbnailFromImageIfAbsent: String = "kCGImageSourceCreateThumbnailFromImageIfAbsent"

/// A Boolean value that indicates whether to always create a thumbnail image.
public let kCGImageSourceCreateThumbnailFromImageAlways: String = "kCGImageSourceCreateThumbnailFromImageAlways"

/// The maximum width and height of a thumbnail image, specified in pixels.
public let kCGImageSourceThumbnailMaxPixelSize: String = "kCGImageSourceThumbnailMaxPixelSize"

/// A Boolean value that indicates whether to rotate and scale the thumbnail image
/// to match the image's orientation and aspect ratio.
public let kCGImageSourceCreateThumbnailWithTransform: String = "kCGImageSourceCreateThumbnailWithTransform"

/// The factor by which to scale down any returned images.
public let kCGImageSourceSubsampleFactor: String = "kCGImageSourceSubsampleFactor"

/// A Boolean value that indicates whether to generate image-specific luma scaling.
public let kCGImageSourceGenerateImageSpecificLumaScaling: String = "kCGImageSourceGenerateImageSpecificLumaScaling"
