// CGImageDestination.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import OpenFoundation
import OpenCoreGraphics
import Synchronization

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

internal enum CGImageDestinationPropertyValue: Sendable {
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case string(String)

    var materialized: Any {
        switch self {
        case .integer(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .string(let value): return value
        }
    }

    var numericDouble: Double? {
        switch self {
        case .integer(let value): return Double(value)
        case .double(let value): return value
        case .bool, .string: return nil
        }
    }

    var integer: Int? {
        guard case .integer(let value) = self else { return nil }
        return value
    }
}

internal struct CGImageDestinationPropertyBag: Sendable {
    var values: [String: CGImageDestinationPropertyValue] = [:]
    var dictionaries: [String: [String: CGImageDestinationPropertyValue]] = [:]
    var isRepresentable = true

    init(_ properties: [String: Any]?) {
        guard let properties else { return }
        for (key, value) in properties {
            if let dictionary = value as? [String: Any] {
                var converted: [String: CGImageDestinationPropertyValue] = [:]
                for (nestedKey, nestedValue) in dictionary {
                    guard let value = Self.convert(nestedValue) else {
                        isRepresentable = false
                        continue
                    }
                    converted[nestedKey] = value
                }
                dictionaries[key] = converted
            } else if let value = Self.convert(value) {
                values[key] = value
            } else {
                isRepresentable = false
            }
        }
    }

    var keys: Set<String> {
        Set(values.keys).union(dictionaries.keys)
    }

    func materialized() -> [String: Any] {
        var result = values.mapValues(\.materialized)
        for (key, dictionary) in dictionaries {
            result[key] = dictionary.mapValues(\.materialized)
        }
        return result
    }

    private static func convert(_ value: Any) -> CGImageDestinationPropertyValue? {
        switch value {
        case let value as Bool: return .bool(value)
        case let value as Double: return .double(value)
        case let value as Float: return .double(Double(value))
        case let value as Int: return .integer(value)
        case let value as Int8: return .integer(Int(value))
        case let value as Int16: return .integer(Int(value))
        case let value as Int32: return .integer(Int(value))
        case let value as Int64: return Int(exactly: value).map(Self.integerValue)
        case let value as UInt: return Int(exactly: value).map(Self.integerValue)
        case let value as UInt8: return .integer(Int(value))
        case let value as UInt16: return .integer(Int(value))
        case let value as UInt32: return Int(exactly: value).map(Self.integerValue)
        case let value as UInt64: return Int(exactly: value).map(Self.integerValue)
        case let value as String: return .string(value)
        default: return nil
        }
    }

    private static func integerValue(_ value: Int) -> CGImageDestinationPropertyValue {
        .integer(value)
    }
}

internal struct CGImageEncodingSnapshot: Sendable {
    let pixels: Data
    let width: Int
    let height: Int
    let bitsPerComponent: Int
    let bitsPerPixel: Int
    let bytesPerRow: Int
    let bitmapInfoRawValue: UInt32
    let shouldInterpolate: Bool
    let renderingIntent: CGColorRenderingIntent

    init?(_ image: CGImage) {
        guard image.width > 0,
              image.height > 0,
              image.bitsPerComponent > 0,
              image.bitsPerPixel > 0,
              image.bytesPerRow > 0,
              let pixels = image.dataProvider?.data else { return nil }
        self.pixels = pixels
        self.width = image.width
        self.height = image.height
        self.bitsPerComponent = image.bitsPerComponent
        self.bitsPerPixel = image.bitsPerPixel
        self.bytesPerRow = image.bytesPerRow
        self.bitmapInfoRawValue = image.bitmapInfo.rawValue
        self.shouldInterpolate = image.shouldInterpolate
        self.renderingIntent = image.renderingIntent
    }

    init(_ decoded: CGImageSourceDecodedImage) {
        self.pixels = decoded.pixels
        self.width = decoded.width
        self.height = decoded.height
        self.bitsPerComponent = 8
        self.bitsPerPixel = 32
        self.bytesPerRow = decoded.width * 4
        self.bitmapInfoRawValue = (
            decoded.hasAlpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast
        ).rawValue
        self.shouldInterpolate = true
        self.renderingIntent = .defaultIntent
    }

    func makeImage() -> CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfoRawValue),
            provider: CGDataProvider(data: pixels),
            decode: nil,
            shouldInterpolate: shouldInterpolate,
            intent: renderingIntent
        )
    }
}

/// An opaque type that you use to write image data to a URL, data object, or data consumer.
public final class CGImageDestination: Hashable, Equatable {

    // MARK: - Internal Types

    internal enum OutputType {
        case url(URL)
        case data
        case consumer(CGDataConsumer)
    }

    internal struct ImageEntry: Sendable {
        let image: CGImageEncodingSnapshot
        let properties: CGImageDestinationPropertyBag
    }

    internal struct Snapshot: Sendable {
        let typeIdentifier: String
        let maxImageCount: Int
        let hasUnsupportedOptions: Bool
        let images: [ImageEntry]
        let globalProperties: CGImageDestinationPropertyBag
        let hasAuxiliaryData: Bool
    }

    internal enum Lifecycle: Sendable {
        case collecting
        case finalizing(UInt64)
        case finalized(Data?)
        case failed
    }

    internal struct State: Sendable {
        let typeIdentifier: String
        let maxImageCount: Int
        let hasUnsupportedOptions: Bool
        var images: [ImageEntry] = []
        var globalProperties = CGImageDestinationPropertyBag(nil)
        var hasAuxiliaryData = false
        var lifecycle = Lifecycle.collecting
        var generation: UInt64 = 0

    }

    private let output: OutputType
    private let state: Mutex<State>

    // MARK: - Initialization

    internal init(output: OutputType, typeIdentifier: String, count: Int, options: [String: Any]?) {
        self.output = output
        self.state = Mutex(State(
            typeIdentifier: typeIdentifier,
            maxImageCount: count,
            hasUnsupportedOptions: options?.isEmpty == false
        ))
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageDestination, rhs: CGImageDestination) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    internal func mutateIfCollecting(_ body: (inout State) -> Void) {
        state.withLock { locked in
            guard case .collecting = locked.lifecycle else { return }
            body(&locked)
        }
    }

    internal func beginFinalization() -> (token: UInt64, snapshot: Snapshot)? {
        state.withLock { locked in
            guard case .collecting = locked.lifecycle else { return nil }
            let snapshot = Snapshot(
                typeIdentifier: locked.typeIdentifier,
                maxImageCount: locked.maxImageCount,
                hasUnsupportedOptions: locked.hasUnsupportedOptions,
                images: locked.images,
                globalProperties: locked.globalProperties,
                hasAuxiliaryData: locked.hasAuxiliaryData
            )
            guard snapshot.images.count == snapshot.maxImageCount,
                  validateConfiguration(snapshot) else { return nil }
            locked.generation &+= 1
            let token = locked.generation
            locked.lifecycle = .finalizing(token)
            return (token, snapshot)
        }
    }

    internal func finishFinalization(
        token: UInt64,
        outputData: Data?,
        retryableOnFailure: Bool = false
    ) {
        state.withLock { locked in
            guard case .finalizing(token) = locked.lifecycle else { return }
            if let outputData {
                locked.lifecycle = .finalized(
                    output.isDataOutput ? outputData : nil
                )
            } else {
                locked.lifecycle = retryableOnFailure ? .collecting : .failed
            }
        }
    }

    internal func copiedData() -> Data? {
        state.withLock { locked in
            guard case .finalized(let data) = locked.lifecycle else { return nil }
            return data
        }
    }

    internal func write(_ data: Data) -> (succeeded: Bool, retryable: Bool) {
        switch output {
        case .url(let url):
            do {
                try data.write(to: url)
                return (true, false)
            } catch {
                return (false, true)
            }
        case .data:
            return (true, false)
        case .consumer(let consumer):
            let succeeded = data.withUnsafeBytes { buffer in
                consumer.putBytes(buffer.baseAddress, count: buffer.count) == buffer.count
            }
            return (succeeded, false)
        }
    }
}

private extension CGImageDestination.OutputType {
    var isDataOutput: Bool {
        if case .data = self { return true }
        return false
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
    return CGImageDestination(
        output: .data,
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
    idst.copiedData()
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
    guard let image = CGImageEncodingSnapshot(image) else { return }
    idst.mutateIfCollecting { locked in
        guard locked.images.count < locked.maxImageCount else { return }
        locked.images.append(CGImageDestination.ImageEntry(
            image: image,
            properties: CGImageDestinationPropertyBag(properties)
        ))
    }
}

/// Adds an image from an image source to an image destination.
public func CGImageDestinationAddImageFromSource(
    _ idst: CGImageDestination,
    _ isrc: CGImageSource,
    _ index: Int,
    _ properties: [String: Any]?
) {
    let source = isrc.parsedSnapshot()
    guard source.decodedImages.indices.contains(index) else { return }
    let image = CGImageEncodingSnapshot(source.decodedImages[index])
    idst.mutateIfCollecting { locked in
        guard locked.images.count < locked.maxImageCount else { return }
        locked.images.append(CGImageDestination.ImageEntry(
            image: image,
            properties: CGImageDestinationPropertyBag(properties)
        ))
    }
}

// MARK: - CGImageDestination Properties Functions

/// Applies one or more properties to all images in an image destination.
public func CGImageDestinationSetProperties(_ idst: CGImageDestination, _ properties: [String: Any]?) {
    let captured = CGImageDestinationPropertyBag(properties)
    idst.mutateIfCollecting { $0.globalProperties = captured }
}

/// Sets the auxiliary data, such as mattes and depth information, that accompany the image.
public func CGImageDestinationAddAuxiliaryDataInfo(
    _ idst: CGImageDestination,
    _ auxiliaryImageDataType: String,
    _ auxiliaryDataInfo: [String: Any]
) {
    idst.mutateIfCollecting {
        $0.hasAuxiliaryData = true
    }
}

// MARK: - CGImageDestination Finalization

/// Writes image data and properties to the data, URL, or data consumer associated with the image destination.
public func CGImageDestinationFinalize(_ idst: CGImageDestination) -> Bool {
    guard let finalization = idst.beginFinalization() else { return false }

    let outputData = encodeImages(finalization.snapshot)
    guard !outputData.isEmpty else {
        idst.finishFinalization(token: finalization.token, outputData: nil)
        return false
    }

    let produced = Data(outputData)
    let writeResult = idst.write(produced)
    idst.finishFinalization(
        token: finalization.token,
        outputData: writeResult.succeeded ? produced : nil,
        retryableOnFailure: writeResult.retryable
    )
    return writeResult.succeeded
}

// MARK: - CGImageDestination Type Information

/// Returns an array of the uniform type identifiers that are supported for image destinations.
public func CGImageDestinationCopyTypeIdentifiers() -> [String] {
    supportedDestinationTypeIdentifiers.sorted()
}

// MARK: - Image Encoding

private func encodeImages(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    switch snapshot.typeIdentifier {
    case "public.png":
        return encodePNG(snapshot)
    case "public.jpeg":
        return encodeJPEG(snapshot)
    case "com.compuserve.gif":
        return encodeGIF(snapshot)
    case "com.microsoft.bmp":
        return encodeBMP(snapshot)
    case "public.tiff":
        return encodeTIFF(snapshot)
    default:
        return []
    }
}

private func encodePNG(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    guard let entry = snapshot.images.first else { return [] }

    guard let img = entry.image.makeImage() else { return [] }

    // Use new PNGEncoder with DEFLATE compression
    if let encoded = PNGEncoder.encode(image: img) {
        return Array(encoded)
    }

    return []
}

private func encodeJPEG(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    // Merge properties (image properties override global properties)
    var mergedOptions = snapshot.globalProperties.materialized()
    if let entry = snapshot.images.first {
        let properties = entry.properties.materialized()
        for (key, value) in properties {
            mergedOptions[key] = value
        }
    }

    guard let entry = snapshot.images.first else { return [] }

    guard let img = entry.image.makeImage() else { return [] }

    // Use the full JPEG encoder with DCT compression
    if let encoded = JPEGEncoder.encode(image: img, options: mergedOptions) {
        return Array(encoded)
    }

    return []
}

private func encodeGIF(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    // Collect all images
    var images: [CGImage] = []

    for entry in snapshot.images {
        guard let frame = entry.image.makeImage() else { return [] }
        images.append(frame)
    }

    guard images.count == snapshot.images.count else { return [] }

    let globalGIFProperties = snapshot.globalProperties.dictionaries[kCGImagePropertyGIFDictionary]
    let loopCount = globalGIFProperties?[kCGImagePropertyGIFLoopCount]?.integer ?? 0
    let frameDelays = snapshot.images.map { entry -> Double in
        let properties = entry.properties.dictionaries[kCGImagePropertyGIFDictionary]
        let delayValue = properties?[kCGImagePropertyGIFUnclampedDelayTime] ??
            properties?[kCGImagePropertyGIFDelayTime]
        return delayValue?.numericDouble ?? 0.1
    }

    // Use new GIFEncoder with LZW compression
    if let encoded = GIFEncoder.encode(images: images, frameDelays: frameDelays, loopCount: loopCount) {
        return Array(encoded)
    }

    return []
}

private func encodeBMP(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    guard let entry = snapshot.images.first else { return [] }

    guard let img = entry.image.makeImage() else { return [] }

    // Use BMPEncoder
    if let encoded = BMPEncoder.encode(image: img) {
        return Array(encoded)
    }

    return []
}

private func encodeTIFF(_ snapshot: CGImageDestination.Snapshot) -> [UInt8] {
    // Collect all images for multi-page TIFF
    var images: [CGImage] = []

    for entry in snapshot.images {
        guard let frame = entry.image.makeImage() else { return [] }
        images.append(frame)
    }

    guard images.count == snapshot.images.count else { return [] }

    // Use TIFFEncoder with multi-page support
    if let encoded = TIFFEncoder.encode(images: images) {
        return Array(encoded)
    }

    return []
}

private func validateConfiguration(_ destination: CGImageDestination.Snapshot) -> Bool {
    guard !destination.hasUnsupportedOptions else { return false }

    // Auxiliary payload encoding is not implemented. The active call path is
    // AddAuxiliaryDataInfo -> Finalize; finalization must not report success
    // until the selected container actually embeds and can read back the data.
    guard !destination.hasAuxiliaryData else { return false }

    switch destination.typeIdentifier {
    case "public.jpeg":
        let supported = Set([kCGImageDestinationLossyCompressionQuality])
        guard destination.globalProperties.keys.isSubset(of: supported) else { return false }
        guard validateJPEGProperties(destination.globalProperties) else { return false }
        return destination.images.allSatisfy { entry in
            entry.properties.keys.isSubset(of: supported)
                && validateJPEGProperties(entry.properties)
        }
    case "com.compuserve.gif":
        guard destination.globalProperties.keys.isSubset(of: [kCGImagePropertyGIFDictionary]),
              validateGIFProperties(destination.globalProperties, global: true) else { return false }
        return destination.images.allSatisfy { validateGIFProperties($0.properties, global: false) }
    case "public.png", "com.microsoft.bmp", "public.tiff":
        guard destination.globalProperties.keys.isEmpty,
              destination.globalProperties.isRepresentable else { return false }
        return destination.images.allSatisfy {
            $0.properties.keys.isEmpty && $0.properties.isRepresentable
        }
    default:
        return false
    }
}

private func validateJPEGProperties(_ properties: CGImageDestinationPropertyBag) -> Bool {
    guard properties.isRepresentable else { return false }
    guard let qualityValue = properties.values[kCGImageDestinationLossyCompressionQuality] else {
        return true
    }
    guard let quality = qualityValue.numericDouble else { return false }
    return quality.isFinite && quality >= 0 && quality <= 1
}

private func validateGIFProperties(
    _ properties: CGImageDestinationPropertyBag,
    global: Bool
) -> Bool {
    guard properties.isRepresentable,
          properties.keys.isSubset(of: [kCGImagePropertyGIFDictionary]) else { return false }
    guard let gif = properties.dictionaries[kCGImagePropertyGIFDictionary] else {
        return properties.keys.isEmpty
    }
    let supported: Set<String> = global
        ? [kCGImagePropertyGIFLoopCount]
        : [kCGImagePropertyGIFDelayTime, kCGImagePropertyGIFUnclampedDelayTime]
    guard Set(gif.keys).isSubset(of: supported) else { return false }
    if global, let loopValue = gif[kCGImagePropertyGIFLoopCount] {
        guard let loopCount = loopValue.integer else { return false }
        return loopCount >= 0 && loopCount <= Int(UInt16.max)
    }
    guard let delayValue = gif[kCGImagePropertyGIFUnclampedDelayTime] ??
        gif[kCGImagePropertyGIFDelayTime] else { return true }
    guard let delay = delayValue.numericDouble else { return false }
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
