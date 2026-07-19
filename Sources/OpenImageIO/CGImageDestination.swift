// CGImageDestination.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import Foundation
import OpenCoreGraphics

private let supportedDestinationTypeIdentifiers: Set<String> = [
    "public.png",
    "public.jpeg",
    "com.compuserve.gif",
    "com.microsoft.bmp",
    "public.tiff",
]

private func supportsImageCount(_ count: Int, for type: String) -> Bool {
    switch type {
    case "com.compuserve.gif", "public.tiff":
        return count > 0
    case "public.png", "public.jpeg", "com.microsoft.bmp":
        return count == 1
    default:
        return false
    }
}

/// An opaque type that you use to write image data to a URL, data object, or data consumer.
public class CGImageDestination: Hashable, Equatable {

    // MARK: - Internal Types

    /// Reference-semantics wrapper for encoded data.
    internal final class DataBox {
        var data: Data = Data()
    }

    internal enum OutputType {
        case url(URL)
        case data(DataBox)
        case consumer(CGDataConsumer)
    }

    internal struct ImageEntry {
        let image: CGImage?
        let imageSource: CGImageSource?
        let sourceIndex: Int
        let properties: [String: Any]?
    }

    // MARK: - Internal Storage (Swift types)

    internal var output: OutputType
    internal var typeIdentifier: String
    internal var maxImageCount: Int
    internal var options: [String: Any]?
    internal var images: [ImageEntry] = []
    internal var globalProperties: [String: Any]?
    internal var auxiliaryData: [(type: String, data: [String: Any])] = []
    internal var isFinalized: Bool = false

    // MARK: - Initialization

    internal init(output: OutputType, typeIdentifier: String, count: Int, options: [String: Any]?) {
        self.output = output
        self.typeIdentifier = typeIdentifier
        self.maxImageCount = count
        self.options = options
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageDestination, rhs: CGImageDestination) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CGImageDestination Creation Functions

/// Creates an image destination that writes image data to the specified URL.
public func CGImageDestinationCreateWithURL(
    _ url: URL,
    _ type: String,
    _ count: Int,
    _ options: [String: Any]?
) -> CGImageDestination? {
    guard supportsImageCount(count, for: type) else { return nil }
    return CGImageDestination(
        output: .url(url),
        typeIdentifier: type,
        count: count,
        options: options
    )
}

/// Creates an image destination that writes to a mutable `Data` value.
///
/// The `data` parameter is `inout` because `Data` is a Swift value type with
/// copy-on-write semantics and `NSMutableData` is not available on WASM.
/// Swift does not provide a safe way to retain and mutate that `inout` storage
/// after this function returns, so callers retrieve the produced bytes with
/// `CGImageDestinationCopyData(_:)` after finalization.
public func CGImageDestinationCreateWithData(
    _ data: inout Data,
    _ type: String,
    _ count: Int,
    _ options: [String: Any]?
) -> CGImageDestination? {
    guard supportsImageCount(count, for: type) else { return nil }
    let box = CGImageDestination.DataBox()
    return CGImageDestination(
        output: .data(box),
        typeIdentifier: type,
        count: count,
        options: options
    )
}

/// Retrieves the encoded data from an image destination created with
/// `CGImageDestinationCreateWithData`, after `CGImageDestinationFinalize`
/// has been called. Returns `nil` for destinations created with a URL or
/// data consumer, or if finalization has not yet occurred.
public func CGImageDestinationCopyData(_ idst: CGImageDestination) -> Data? {
    guard idst.isFinalized else { return nil }
    if case .data(let box) = idst.output {
        return box.data
    }
    return nil
}

/// Creates an image destination that writes to the specified data consumer.
public func CGImageDestinationCreateWithDataConsumer(
    _ consumer: CGDataConsumer,
    _ type: String,
    _ count: Int,
    _ options: [String: Any]?
) -> CGImageDestination? {
    guard supportsImageCount(count, for: type) else { return nil }
    return CGImageDestination(
        output: .consumer(consumer),
        typeIdentifier: type,
        count: count,
        options: options
    )
}

// MARK: - CGImageDestination Image Addition Functions

/// Adds an image to an image destination.
public func CGImageDestinationAddImage(
    _ idst: CGImageDestination,
    _ image: CGImage,
    _ properties: [String: Any]?
) {
    guard !idst.isFinalized && idst.images.count < idst.maxImageCount else { return }
    idst.images.append(CGImageDestination.ImageEntry(
        image: image,
        imageSource: nil,
        sourceIndex: 0,
        properties: properties
    ))
}

/// Adds an image from an image source to an image destination.
public func CGImageDestinationAddImageFromSource(
    _ idst: CGImageDestination,
    _ isrc: CGImageSource,
    _ index: Int,
    _ properties: [String: Any]?
) {
    guard !idst.isFinalized && idst.images.count < idst.maxImageCount else { return }
    guard index >= 0 && index < isrc.imageCount else { return }
    idst.images.append(CGImageDestination.ImageEntry(
        image: nil,
        imageSource: isrc,
        sourceIndex: index,
        properties: properties
    ))
}

// MARK: - CGImageDestination Properties Functions

/// Applies one or more properties to all images in an image destination.
public func CGImageDestinationSetProperties(_ idst: CGImageDestination, _ properties: [String: Any]?) {
    guard !idst.isFinalized else { return }
    idst.globalProperties = properties
}

/// Sets the auxiliary data, such as mattes and depth information, that accompany the image.
public func CGImageDestinationAddAuxiliaryDataInfo(
    _ idst: CGImageDestination,
    _ auxiliaryImageDataType: String,
    _ auxiliaryDataInfo: [String: Any]
) {
    guard !idst.isFinalized else { return }
    idst.auxiliaryData.append((type: auxiliaryImageDataType, data: auxiliaryDataInfo))
}

// MARK: - CGImageDestination Finalization

/// Writes image data and properties to the data, URL, or data consumer associated with the image destination.
public func CGImageDestinationFinalize(_ idst: CGImageDestination) -> Bool {
    guard !idst.isFinalized else { return false }
    guard idst.images.count == idst.maxImageCount else { return false }
    guard validateConfiguration(idst) else { return false }

    // Generate output based on type
    let outputData = encodeImages(idst)
    guard !outputData.isEmpty else { return false }

    switch idst.output {
    case .url(let url):
        do {
            try Data(outputData).write(to: url)
            idst.isFinalized = true
            return true
        } catch {
            return false
        }
    case .data(let box):
        let produced = Data(outputData)
        box.data = produced
        idst.isFinalized = true
        return true
    case .consumer(let consumer):
        let written = outputData.withUnsafeBytes { buffer in
            consumer.putBytes(buffer.baseAddress, count: buffer.count)
        }
        let success = written == outputData.count
        if success {
            idst.isFinalized = true
        }
        return success
    }
}

// MARK: - CGImageDestination Type Information

/// Returns an array of the uniform type identifiers that are supported for image destinations.
public func CGImageDestinationCopyTypeIdentifiers() -> [String] {
    supportedDestinationTypeIdentifiers.sorted()
}

// MARK: - Image Encoding

private func encodeImages(_ idst: CGImageDestination) -> [UInt8] {
    switch idst.typeIdentifier {
    case "public.png":
        return encodePNG(idst)
    case "public.jpeg":
        return encodeJPEG(idst)
    case "com.compuserve.gif":
        return encodeGIF(idst)
    case "com.microsoft.bmp":
        return encodeBMP(idst)
    case "public.tiff":
        return encodeTIFF(idst)
    default:
        return []
    }
}

private func encodePNG(_ idst: CGImageDestination) -> [UInt8] {
    guard let entry = idst.images.first else { return [] }

    let image: CGImage?
    if let img = entry.image {
        image = img
    } else if let source = entry.imageSource {
        image = CGImageSourceCreateImageAtIndex(source, entry.sourceIndex, nil)
    } else {
        return []
    }

    guard let img = image else { return [] }

    // Use new PNGEncoder with DEFLATE compression
    if let encoded = PNGEncoder.encode(image: img) {
        return Array(encoded)
    }

    return []
}

private func encodeJPEG(_ idst: CGImageDestination) -> [UInt8] {
    // Merge properties (image properties override global properties)
    var mergedOptions: [String: Any] = idst.globalProperties ?? [:]
    if let props = idst.images.first?.properties {
        for (key, value) in props {
            mergedOptions[key] = value
        }
    }

    guard let entry = idst.images.first else { return [] }

    let image: CGImage?
    if let img = entry.image {
        image = img
    } else if let source = entry.imageSource {
        image = CGImageSourceCreateImageAtIndex(source, entry.sourceIndex, nil)
    } else {
        return []
    }

    guard let img = image else { return [] }

    // Use the full JPEG encoder with DCT compression
    if let encoded = JPEGEncoder.encode(image: img, options: mergedOptions) {
        return Array(encoded)
    }

    return []
}

private func encodeGIF(_ idst: CGImageDestination) -> [UInt8] {
    // Collect all images
    var images: [CGImage] = []

    for entry in idst.images {
        let frameImage: CGImage?
        if let img = entry.image {
            frameImage = img
        } else if let source = entry.imageSource {
            frameImage = CGImageSourceCreateImageAtIndex(source, entry.sourceIndex, nil)
        } else {
            return []
        }
        guard let frame = frameImage else { return [] }
        images.append(frame)
    }

    guard images.count == idst.images.count else { return [] }

    let globalGIFProperties = idst.globalProperties?[kCGImagePropertyGIFDictionary] as? [String: Any]
    let loopCount = globalGIFProperties?[kCGImagePropertyGIFLoopCount] as? Int ?? 0
    let frameDelays = idst.images.map { entry -> Double in
        let properties = entry.properties?[kCGImagePropertyGIFDictionary] as? [String: Any]
        let delayValue = properties?[kCGImagePropertyGIFUnclampedDelayTime] ??
            properties?[kCGImagePropertyGIFDelayTime]
        return numericDouble(delayValue) ?? 0.1
    }

    // Use new GIFEncoder with LZW compression
    if let encoded = GIFEncoder.encode(images: images, frameDelays: frameDelays, loopCount: loopCount) {
        return Array(encoded)
    }

    return []
}

private func encodeBMP(_ idst: CGImageDestination) -> [UInt8] {
    guard let entry = idst.images.first else { return [] }

    let image: CGImage?
    if let img = entry.image {
        image = img
    } else if let source = entry.imageSource {
        image = CGImageSourceCreateImageAtIndex(source, entry.sourceIndex, nil)
    } else {
        return []
    }

    guard let img = image else { return [] }

    // Use BMPEncoder
    if let encoded = BMPEncoder.encode(image: img) {
        return Array(encoded)
    }

    return []
}

private func encodeTIFF(_ idst: CGImageDestination) -> [UInt8] {
    // Collect all images for multi-page TIFF
    var images: [CGImage] = []

    for entry in idst.images {
        let frameImage: CGImage?
        if let img = entry.image {
            frameImage = img
        } else if let source = entry.imageSource {
            frameImage = CGImageSourceCreateImageAtIndex(source, entry.sourceIndex, nil)
        } else {
            return []
        }
        guard let frame = frameImage else { return [] }
        images.append(frame)
    }

    guard images.count == idst.images.count else { return [] }

    // Use TIFFEncoder with multi-page support
    if let encoded = TIFFEncoder.encode(images: images) {
        return Array(encoded)
    }

    return []
}

private func validateConfiguration(_ destination: CGImageDestination) -> Bool {
    guard destination.options?.isEmpty != false else { return false }

    // Auxiliary payload encoding is not implemented. The active call path is
    // AddAuxiliaryDataInfo -> Finalize; finalization must not report success
    // until the selected container actually embeds and can read back the data.
    guard destination.auxiliaryData.isEmpty else { return false }

    switch destination.typeIdentifier {
    case "public.jpeg":
        let supported = Set([kCGImageDestinationLossyCompressionQuality])
        guard propertyKeys(destination.globalProperties).isSubset(of: supported) else { return false }
        guard validateJPEGProperties(destination.globalProperties) else { return false }
        return destination.images.allSatisfy { entry in
            propertyKeys(entry.properties).isSubset(of: supported)
                && validateJPEGProperties(entry.properties)
        }
    case "com.compuserve.gif":
        guard propertyKeys(destination.globalProperties).isSubset(of: [kCGImagePropertyGIFDictionary]),
              validateGIFProperties(destination.globalProperties, global: true) else { return false }
        return destination.images.allSatisfy { validateGIFProperties($0.properties, global: false) }
    case "public.png", "com.microsoft.bmp", "public.tiff":
        guard destination.globalProperties?.isEmpty != false else { return false }
        return destination.images.allSatisfy { $0.properties?.isEmpty != false }
    default:
        return false
    }
}

private func validateJPEGProperties(_ properties: [String: Any]?) -> Bool {
    guard let qualityValue = properties?[kCGImageDestinationLossyCompressionQuality] else { return true }
    guard let quality = numericDouble(qualityValue) else { return false }
    return quality.isFinite && quality >= 0 && quality <= 1
}

private func numericDouble(_ value: Any?) -> Double? {
    switch value {
    case nil: return nil
    case is Bool: return nil
    case let value as Double: return value
    case let value as Float: return Double(value)
    case let value as Int: return Double(value)
    case let value as Int8: return Double(value)
    case let value as Int16: return Double(value)
    case let value as Int32: return Double(value)
    case let value as Int64: return Double(value)
    case let value as UInt: return Double(value)
    case let value as UInt8: return Double(value)
    case let value as UInt16: return Double(value)
    case let value as UInt32: return Double(value)
    case let value as UInt64: return Double(value)
    default: return nil
    }
}

private func propertyKeys(_ properties: [String: Any]?) -> Set<String> {
    guard let properties else { return [] }
    return Set(properties.keys)
}

private func validateGIFProperties(_ properties: [String: Any]?, global: Bool) -> Bool {
    guard let properties else { return true }
    guard Set(properties.keys).isSubset(of: [kCGImagePropertyGIFDictionary]) else { return false }
    guard let gif = properties[kCGImagePropertyGIFDictionary] as? [String: Any] else { return false }
    let supported: Set<String> = global
        ? [kCGImagePropertyGIFLoopCount]
        : [kCGImagePropertyGIFDelayTime, kCGImagePropertyGIFUnclampedDelayTime]
    guard Set(gif.keys).isSubset(of: supported) else { return false }
    if global, let loopCount = gif[kCGImagePropertyGIFLoopCount] as? Int {
        return loopCount >= 0 && loopCount <= Int(UInt16.max)
    }
    guard let delayValue = gif[kCGImagePropertyGIFUnclampedDelayTime] ??
        gif[kCGImagePropertyGIFDelayTime] else { return true }
    guard let delay = numericDouble(delayValue) else { return false }
    return delay.isFinite && delay >= 0 && delay <= Double(UInt16.max) / 100
}

// MARK: - CGImageDestination Options Keys

/// The desired compression quality to use when writing the image data.
public let kCGImageDestinationLossyCompressionQuality: String = "kCGImageDestinationLossyCompressionQuality"

/// The background color to use when the image has an alpha component, but the destination format doesn't support alpha.
public let kCGImageDestinationBackgroundColor: String = "kCGImageDestinationBackgroundColor"

/// The date and time information to associate with the image.
public let kCGImageDestinationDateTime: String = "kCGImageDestinationDateTime"

/// A Boolean value that indicates whether to embed a thumbnail for JPEG and HEIF images.
public let kCGImageDestinationEmbedThumbnail: String = "kCGImageDestinationEmbedThumbnail"

/// The maximum width and height of the image, in pixels.
public let kCGImageDestinationImageMaxPixelSize: String = "kCGImageDestinationImageMaxPixelSize"

/// The metadata tags to include with the image.
public let kCGImageDestinationMetadata: String = "kCGImageDestinationMetadata"

/// A Boolean value that indicates whether to merge new metadata with the image's existing metadata.
public let kCGImageDestinationMergeMetadata: String = "kCGImageDestinationMergeMetadata"

/// A Boolean value that indicates whether to create the image using a colorspace.
public let kCGImageDestinationOptimizeColorForSharing: String = "kCGImageDestinationOptimizeColorForSharing"

/// The orientation of the image, specified as an EXIF value in the range 1 to 8.
public let kCGImageDestinationOrientation: String = "kCGImageDestinationOrientation"

/// A Boolean value that indicates whether to include a HEIF-embedded gain map in the image data.
public let kCGImageDestinationPreserveGainMap: String = "kCGImageDestinationPreserveGainMap"

/// A Boolean value that indicates whether to exclude GPS metadata from EXIF data or the corresponding XMP tags.
public let kCGImageMetadataShouldExcludeGPS: String = "kCGImageMetadataShouldExcludeGPS"

/// A Boolean value that indicates whether to exclude XMP data from the destination.
public let kCGImageMetadataShouldExcludeXMP: String = "kCGImageMetadataShouldExcludeXMP"
