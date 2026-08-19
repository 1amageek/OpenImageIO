// CGImageSource.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import OpenFoundation
import OpenCoreGraphics
import Synchronization

/// An opaque type that you use to read image data from a URL, data object, or data consumer.
public final class CGImageSource: Hashable, Equatable, Sendable {

    private struct State {
        var generation: UInt64
        var parsed: CGImageSourceParsedState
    }

    private let isIncremental: Bool
    private let state: Mutex<State>

    // MARK: - Initialization

    internal init(data: Data, options: [String: Any]?, isIncremental: Bool = false) {
        self.isIncremental = isIncremental
        let parsed = isIncremental
            ? CGImageSourceParsedState()
            : ImageSourceParser(data: data).parse(final: true, incremental: false)
        self.state = Mutex(State(generation: 0, parsed: parsed))
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageSource, rhs: CGImageSource) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    internal func parsedSnapshot() -> CGImageSourceParsedState {
        state.withLock { $0.parsed }
    }

    internal func update(data: Data, final: Bool) {
        let generation = state.withLock { locked -> UInt64 in
            locked.generation &+= 1
            return locked.generation
        }
        let parsed = ImageSourceParser(data: data).parse(
            final: final,
            incremental: isIncremental
        )
        state.withLock { locked in
            guard locked.generation == generation else { return }
            locked.parsed = parsed
        }
    }

    internal func markProviderFailure(final: Bool) {
        state.withLock { locked in
            locked.generation &+= 1
            if final {
                var invalid = CGImageSourceParsedState()
                invalid.status = .statusInvalidData
                locked.parsed = invalid
            } else {
                locked.parsed.status = .statusIncomplete
            }
        }
    }
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
    isrc.parsedSnapshot().sourceType
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
    isrc.parsedSnapshot().imageCount
}

/// Returns the properties of the image source.
public func CGImageSourceCopyProperties(_ isrc: CGImageSource, _ options: [String: Any]?) -> [String: Any]? {
    isrc.parsedSnapshot().materializedProperties()
}

/// Returns the properties of the image at a specified location in an image source.
public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> [String: Any]? {
    isrc.parsedSnapshot().materializedProperties(at: index)
}

/// Returns auxiliary data, such as mattes and depth information, that accompany the image.
public func CGImageSourceCopyAuxiliaryDataInfoAtIndex(_ isrc: CGImageSource, _ index: Int, _ auxiliaryImageDataType: String) -> [String: Any]? {
    isrc.parsedSnapshot().materializedAuxiliaryData(
        at: index,
        type: auxiliaryImageDataType
    )
}

// MARK: - CGImageSource Image Extraction Functions

/// Creates an image object from the data at the specified index in an image source.
public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: [String: Any]?) -> CGImage? {
    let parsed = isrc.parsedSnapshot()
    guard parsed.decodedImages.indices.contains(index) else { return nil }
    return parsed.decodedImages[index].makeImage()
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
    isrc.parsedSnapshot().status
}

/// Returns the current status of an image at the specified location in the image source.
public func CGImageSourceGetStatusAtIndex(_ isrc: CGImageSource, _ index: Int) -> CGImageSourceStatus {
    let parsed = isrc.parsedSnapshot()
    guard index >= 0 && index < parsed.imageCount else {
        return .statusInvalidData
    }
    return parsed.status
}

// MARK: - CGImageSource Incremental Functions

/// Updates the data in an incremental image source.
public func CGImageSourceUpdateData(_ isrc: CGImageSource, _ data: Data, _ final: Bool) {
    isrc.update(data: data, final: final)
}

/// Updates an incremental image source with a new data provider.
///
/// Uses the provider's materialised data snapshot.
public func CGImageSourceUpdateDataProvider(_ isrc: CGImageSource, _ provider: CGDataProvider, _ final: Bool) {
    guard let data = provider.data else {
        isrc.markProviderFailure(final: final)
        return
    }
    isrc.update(data: data, final: final)
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
