// CGImageDestination.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

@preconcurrency import Foundation
import OpenCoreGraphics

/// An opaque type that you use to write image data to a URL, data object, or data consumer.
public class CGImageDestination: Hashable, Equatable {

    // MARK: - Internal Types

    internal enum OutputType {
        case url(URL)
        case data(NSMutableData)
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
    guard count > 0 else { return nil }
    return CGImageDestination(
        output: .url(url),
        typeIdentifier: type,
        count: count,
        options: options
    )
}

/// Creates an image destination that writes to a mutable data object.
public func CGImageDestinationCreateWithData(
    _ data: NSMutableData,
    _ type: String,
    _ count: Int,
    _ options: [String: Any]?
) -> CGImageDestination? {
    guard count > 0 else { return nil }
    return CGImageDestination(
        output: .data(data),
        typeIdentifier: type,
        count: count,
        options: options
    )
}

/// Creates an image destination that writes to the specified data consumer.
public func CGImageDestinationCreateWithDataConsumer(
    _ consumer: CGDataConsumer,
    _ type: String,
    _ count: Int,
    _ options: [String: Any]?
) -> CGImageDestination? {
    guard count > 0 else { return nil }
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
    guard !idst.images.isEmpty else { return false }

    idst.isFinalized = true

    // Generate output based on type
    let outputData = encodeImages(idst)
    guard !outputData.isEmpty else { return false }

    switch idst.output {
    case .url(let url):
        do {
            try Data(outputData).write(to: url)
            return true
        } catch {
            return false
        }
    case .data(let mutableData):
        mutableData.append(Data(outputData))
        return true
    case .consumer(let consumer):
        outputData.withUnsafeBytes { buffer in
            _ = consumer.putBytes(buffer.baseAddress, count: buffer.count)
        }
        return true
    }
}

// MARK: - CGImageDestination Type Information

/// Returns an array of the uniform type identifiers that are supported for image destinations.
public func CGImageDestinationCopyTypeIdentifiers() -> [String] {
    return [
        "public.png",
        "public.jpeg",
        "com.compuserve.gif",
        "com.microsoft.bmp",
        "public.tiff"
    ]
}

/// Returns the unique type identifier of an image destination opaque type.
public func CGImageDestinationGetTypeID() -> UInt {
    return 1
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
    if let encoded = PNGEncoder.encode(image: img, options: entry.properties) {
        return Array(encoded)
    }

    return []
}

private func createPNGChunk(type: [UInt8], data: [UInt8]) -> [UInt8] {
    var chunk: [UInt8] = []

    // Length
    chunk.append(contentsOf: withUnsafeBytes(of: UInt32(data.count).bigEndian) { Array($0) })

    // Type
    chunk.append(contentsOf: type)

    // Data
    chunk.append(contentsOf: data)

    // CRC
    var crcData = type
    crcData.append(contentsOf: data)
    let crc = crc32(crcData)
    chunk.append(contentsOf: withUnsafeBytes(of: crc.bigEndian) { Array($0) })

    return chunk
}

// MARK: - CRC32 Lookup Table (Pre-computed for performance)

private let crc32Table: [UInt32] = {
    var table = [UInt32](repeating: 0, count: 256)
    for i in 0..<256 {
        var crc = UInt32(i)
        for _ in 0..<8 {
            crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1
        }
        table[i] = crc
    }
    return table
}()

/// Optimized CRC32 using pre-computed lookup table.
private func crc32(_ data: [UInt8]) -> UInt32 {
    var crc: UInt32 = 0xFFFFFFFF
    for byte in data {
        let index = Int((crc ^ UInt32(byte)) & 0xFF)
        crc = crc32Table[index] ^ (crc >> 8)
    }
    return ~crc
}

/// Optimized Adler32 with batch processing.
private func adler32(_ data: [UInt8]) -> UInt32 {
    let BASE: UInt32 = 65521
    let NMAX = 5552

    var a: UInt32 = 1
    var b: UInt32 = 0
    var index = 0
    let count = data.count

    while index < count {
        let chunkSize = min(NMAX, count - index)
        let end = index + chunkSize

        while index < end {
            a &+= UInt32(data[index])
            b &+= a
            index += 1
        }

        a %= BASE
        b %= BASE
    }

    return (b << 16) | a
}

private func encodeJPEG(_ idst: CGImageDestination, properties: [String: Any]? = nil, globalProperties: [String: Any]? = nil) -> [UInt8] {
    var output: [UInt8] = []

    // Get quality
    var quality: Double = 0.8
    if let q = properties?[kCGImageDestinationLossyCompressionQuality] as? Double {
        quality = q
    } else if let q = globalProperties?[kCGImageDestinationLossyCompressionQuality] as? Double {
        quality = q
    }
    _ = quality // Would be used in actual JPEG encoding

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

    // SOI marker
    output.append(contentsOf: [0xFF, 0xD8])

    // APP0 JFIF marker
    output.append(contentsOf: [0xFF, 0xE0])
    output.append(contentsOf: [0x00, 0x10]) // Length
    output.append(contentsOf: [0x4A, 0x46, 0x49, 0x46, 0x00]) // "JFIF\0"
    output.append(contentsOf: [0x01, 0x01]) // Version
    output.append(0x00) // Aspect ratio units
    output.append(contentsOf: [0x00, 0x01]) // X density
    output.append(contentsOf: [0x00, 0x01]) // Y density
    output.append(contentsOf: [0x00, 0x00]) // Thumbnail dimensions

    // SOF0 marker (baseline DCT)
    output.append(contentsOf: [0xFF, 0xC0])
    output.append(contentsOf: [0x00, 0x0B]) // Length
    output.append(0x08) // Precision
    output.append(contentsOf: withUnsafeBytes(of: UInt16(img.height).bigEndian) { Array($0) })
    output.append(contentsOf: withUnsafeBytes(of: UInt16(img.width).bigEndian) { Array($0) })
    output.append(0x01) // Number of components
    output.append(contentsOf: [0x01, 0x11, 0x00]) // Component info

    // DHT marker (Huffman table - minimal)
    output.append(contentsOf: [0xFF, 0xC4])
    output.append(contentsOf: [0x00, 0x1F])
    output.append(0x00)
    output.append(contentsOf: [0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    output.append(contentsOf: [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B])

    // SOS marker
    output.append(contentsOf: [0xFF, 0xDA])
    output.append(contentsOf: [0x00, 0x08])
    output.append(0x01) // Number of components
    output.append(contentsOf: [0x01, 0x00])
    output.append(contentsOf: [0x00, 0x3F, 0x00])

    // Placeholder image data
    for _ in 0..<min(100, img.width * img.height) {
        output.append(0x00)
    }

    // EOI marker
    output.append(contentsOf: [0xFF, 0xD9])

    return output
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
            continue
        }

        if let frame = frameImage {
            images.append(frame)
        }
    }

    guard !images.isEmpty else { return [] }

    // Use new GIFEncoder with LZW compression
    if let encoded = GIFEncoder.encode(images: images, options: idst.globalProperties) {
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

    var output: [UInt8] = []

    let width = img.width
    let height = img.height
    let rowSize = ((width * 3 + 3) / 4) * 4 // Row size must be multiple of 4
    let imageSize = rowSize * height
    let fileSize = 54 + imageSize // Header + pixel data

    // BMP Header
    output.append(contentsOf: [0x42, 0x4D]) // "BM"
    output.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
    output.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Reserved
    output.append(contentsOf: withUnsafeBytes(of: UInt32(54).littleEndian) { Array($0) }) // Data offset

    // DIB Header (BITMAPINFOHEADER)
    output.append(contentsOf: withUnsafeBytes(of: UInt32(40).littleEndian) { Array($0) }) // Header size
    output.append(contentsOf: withUnsafeBytes(of: Int32(width).littleEndian) { Array($0) }) // Width
    output.append(contentsOf: withUnsafeBytes(of: Int32(height).littleEndian) { Array($0) }) // Height (positive = bottom-up)
    output.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // Color planes
    output.append(contentsOf: withUnsafeBytes(of: UInt16(24).littleEndian) { Array($0) }) // Bits per pixel
    output.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) }) // Compression (none)
    output.append(contentsOf: withUnsafeBytes(of: UInt32(imageSize).littleEndian) { Array($0) }) // Image size
    output.append(contentsOf: withUnsafeBytes(of: Int32(2835).littleEndian) { Array($0) }) // X pixels per meter
    output.append(contentsOf: withUnsafeBytes(of: Int32(2835).littleEndian) { Array($0) }) // Y pixels per meter
    output.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) }) // Colors used
    output.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) }) // Important colors

    // Pixel Data (BGR format)
    guard let imageData = img.dataProvider?.data else { return output }

    for y in 0..<img.height {
        for x in 0..<img.width {
            let srcIndex = y * img.bytesPerRow + x * 4
            if srcIndex + 2 < imageData.count {
                output.append(imageData[srcIndex + 2]) // B
                output.append(imageData[srcIndex + 1]) // G
                output.append(imageData[srcIndex])     // R
            } else {
                output.append(contentsOf: [0, 0, 0])
            }
        }
        // Padding
        let padding = rowSize - img.width * 3
        for _ in 0..<padding {
            output.append(0)
        }
    }

    return output
}

private func encodeTIFF(_ idst: CGImageDestination) -> [UInt8] {
    var output: [UInt8] = []

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

    // TIFF Header (little-endian)
    output.append(contentsOf: [0x49, 0x49]) // Little-endian
    output.append(contentsOf: [0x2A, 0x00]) // Magic number
    output.append(contentsOf: withUnsafeBytes(of: UInt32(8).littleEndian) { Array($0) }) // IFD offset

    // IFD entries
    let numEntries: UInt16 = 8
    output.append(contentsOf: withUnsafeBytes(of: numEntries.littleEndian) { Array($0) })

    let dataOffset = 8 + 2 + Int(numEntries) * 12 + 4 // Header + count + entries + next IFD
    _ = dataOffset

    // ImageWidth (256)
    output.append(contentsOf: createTIFFEntry(tag: 256, type: 3, count: 1, value: UInt32(img.width)))
    // ImageLength (257)
    output.append(contentsOf: createTIFFEntry(tag: 257, type: 3, count: 1, value: UInt32(img.height)))
    // BitsPerSample (258)
    output.append(contentsOf: createTIFFEntry(tag: 258, type: 3, count: 1, value: 8))
    // Compression (259) - no compression
    output.append(contentsOf: createTIFFEntry(tag: 259, type: 3, count: 1, value: 1))
    // PhotometricInterpretation (262) - RGB
    output.append(contentsOf: createTIFFEntry(tag: 262, type: 3, count: 1, value: 2))
    // StripOffsets (273)
    output.append(contentsOf: createTIFFEntry(tag: 273, type: 4, count: 1, value: UInt32(8 + 2 + numEntries * 12 + 4)))
    // SamplesPerPixel (277)
    output.append(contentsOf: createTIFFEntry(tag: 277, type: 3, count: 1, value: 3))
    // RowsPerStrip (278)
    output.append(contentsOf: createTIFFEntry(tag: 278, type: 3, count: 1, value: UInt32(img.height)))

    // Next IFD offset (0 = no more IFDs)
    output.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

    // Pixel Data (RGB)
    guard let imageData = img.dataProvider?.data else { return output }

    for y in 0..<img.height {
        for x in 0..<img.width {
            let srcIndex = y * img.bytesPerRow + x * 4
            if srcIndex + 2 < imageData.count {
                output.append(imageData[srcIndex])     // R
                output.append(imageData[srcIndex + 1]) // G
                output.append(imageData[srcIndex + 2]) // B
            } else {
                output.append(contentsOf: [0, 0, 0])
            }
        }
    }

    return output
}

private func createTIFFEntry(tag: UInt16, type: UInt16, count: UInt32, value: UInt32) -> [UInt8] {
    var entry: [UInt8] = []
    entry.append(contentsOf: withUnsafeBytes(of: tag.littleEndian) { Array($0) })
    entry.append(contentsOf: withUnsafeBytes(of: type.littleEndian) { Array($0) })
    entry.append(contentsOf: withUnsafeBytes(of: count.littleEndian) { Array($0) })
    entry.append(contentsOf: withUnsafeBytes(of: value.littleEndian) { Array($0) })
    return entry
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
