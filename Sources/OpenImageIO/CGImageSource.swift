// CGImageSource.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

@preconcurrency import Foundation

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
                parseJPEG(bytes: bytes, count: imageData.count)
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
                parseTIFF(bytes: bytes, count: imageData.count)
            }
            // WebP signature: RIFF....WEBP
            else if imageData.count >= 12 &&
                    bytes[0] == 0x52 && bytes[1] == 0x49 &&
                    bytes[2] == 0x46 && bytes[3] == 0x46 &&
                    bytes[8] == 0x57 && bytes[9] == 0x45 &&
                    bytes[10] == 0x42 && bytes[11] == 0x50 {
                sourceType = "org.webmproject.webp"
                parseWebP(bytes: bytes, count: imageData.count)
            }
            else {
                status = .statusUnknownType
            }
        }
    }

    internal func parsePNG(bytes: UnsafePointer<UInt8>, count: Int) {
        // Basic PNG parsing - extract dimensions from IHDR chunk
        guard count > 24 else {
            status = .statusInvalidData
            return
        }

        // IHDR chunk starts at byte 8, chunk length is 4 bytes, type is 4 bytes, then width/height
        let widthOffset = 16
        let heightOffset = 20

        let width = (Int(bytes[widthOffset]) << 24) |
                    (Int(bytes[widthOffset + 1]) << 16) |
                    (Int(bytes[widthOffset + 2]) << 8) |
                    Int(bytes[widthOffset + 3])

        let height = (Int(bytes[heightOffset]) << 24) |
                     (Int(bytes[heightOffset + 1]) << 16) |
                     (Int(bytes[heightOffset + 2]) << 8) |
                     Int(bytes[heightOffset + 3])

        let bitDepth = Int(bytes[24])
        let colorType = Int(bytes[25])

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyDepth: bitDepth,
            kCGImagePropertyColorModel: colorModelFromPNGColorType(colorType)
        ]
        imageProperties = [properties]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseJPEG(bytes: UnsafePointer<UInt8>, count: Int) {
        // Basic JPEG parsing
        guard count > 2 else {
            status = .statusInvalidData
            return
        }

        var offset = 2
        var width = 0
        var height = 0
        var xmpData: Data?
        var gainMapInfo: [String: Any]?

        while offset < count - 1 {
            guard bytes[offset] == 0xFF else {
                offset += 1
                continue
            }

            let marker = bytes[offset + 1]

            // SOF markers (Start of Frame)
            if marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC {
                if offset + 9 < count {
                    height = (Int(bytes[offset + 5]) << 8) | Int(bytes[offset + 6])
                    width = (Int(bytes[offset + 7]) << 8) | Int(bytes[offset + 8])
                }
            }

            // APP1 marker (XMP or EXIF)
            if marker == 0xE1 && offset + 3 < count {
                let length = (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
                if offset + 2 + length <= count {
                    let segmentStart = offset + 4
                    let segmentData = Data(bytes: bytes + segmentStart, count: length - 2)

                    // Check for XMP namespace: "http://ns.adobe.com/xap/1.0/"
                    if let xmpString = String(data: segmentData, encoding: .utf8),
                       xmpString.hasPrefix("http://ns.adobe.com/xap/1.0/") {
                        // Extract XMP content after the namespace identifier and null byte
                        if let nullIndex = segmentData.firstIndex(of: 0) {
                            xmpData = segmentData.suffix(from: segmentData.index(after: nullIndex))
                        }
                    }
                }
            }

            if marker == 0xD9 || marker == 0xDA {
                break
            }

            if offset + 3 < count {
                let length = (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
                offset += 2 + length
            } else {
                break
            }
        }

        // Parse XMP for HDR Gain Map metadata
        if let xmpData = xmpData,
           let xmpString = String(data: xmpData, encoding: .utf8) {
            gainMapInfo = parseXMPForGainMap(xmpString: xmpString, imageData: imageData)
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]

        // Store auxiliary data if found
        if let gainMapInfo = gainMapInfo {
            auxiliaryDataByIndex = [[kCGImageAuxiliaryDataTypeHDRGainMap: gainMapInfo]]
        } else {
            auxiliaryDataByIndex = [[:]]
        }

        status = .statusComplete
    }

    /// Parses XMP metadata to extract HDR Gain Map information (Ultra HDR / ISO 21496-1)
    private func parseXMPForGainMap(xmpString: String, imageData: Data) -> [String: Any]? {
        // Check for HDR Gain Map version indicator
        guard xmpString.contains("hdrgm:Version") || xmpString.contains("GainMap") else {
            return nil
        }

        var gainMapMetadata: [String: Any] = [:]

        // Extract hdrgm namespace attributes
        let hdrgmAttributes = [
            ("hdrgm:Version", "Version"),
            ("hdrgm:GainMapMin", "GainMapMin"),
            ("hdrgm:GainMapMax", "GainMapMax"),
            ("hdrgm:Gamma", "Gamma"),
            ("hdrgm:OffsetSDR", "OffsetSDR"),
            ("hdrgm:OffsetHDR", "OffsetHDR"),
            ("hdrgm:HDRCapacityMin", "HDRCapacityMin"),
            ("hdrgm:HDRCapacityMax", "HDRCapacityMax"),
            ("hdrgm:BaseRenditionIsHDR", "BaseRenditionIsHDR")
        ]

        for (xmlKey, dictKey) in hdrgmAttributes {
            if let value = extractXMPAttribute(from: xmpString, attribute: xmlKey) {
                // Parse numeric values
                if let doubleValue = Double(value) {
                    gainMapMetadata[dictKey] = doubleValue
                } else if value.lowercased() == "true" {
                    gainMapMetadata[dictKey] = true
                } else if value.lowercased() == "false" {
                    gainMapMetadata[dictKey] = false
                } else {
                    gainMapMetadata[dictKey] = value
                }
            }
        }

        // Extract GContainer information for Gain Map location
        if let gainMapLength = extractGainMapLength(from: xmpString) {
            gainMapMetadata["GainMapLength"] = gainMapLength

            // Extract the gain map image data from the end of the file
            if let gainMapData = extractGainMapData(from: imageData, length: gainMapLength) {
                gainMapMetadata[kCGImageAuxiliaryDataInfoData] = gainMapData
            }
        }

        // Only return if we found meaningful gain map data
        guard !gainMapMetadata.isEmpty,
              gainMapMetadata["Version"] != nil || gainMapMetadata[kCGImageAuxiliaryDataInfoData] != nil else {
            return nil
        }

        // Build the data description dictionary
        var dataDescription: [String: Any] = [:]
        for (key, value) in gainMapMetadata where key != kCGImageAuxiliaryDataInfoData {
            dataDescription[key] = value
        }
        gainMapMetadata[kCGImageAuxiliaryDataInfoDataDescription] = dataDescription

        return gainMapMetadata
    }

    /// Extracts an attribute value from XMP string
    private func extractXMPAttribute(from xmpString: String, attribute: String) -> String? {
        // Pattern: attribute="value" or attribute='value'
        let patterns = [
            "\(attribute)=\"([^\"]+)\"",
            "\(attribute)='([^']+)'"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: xmpString, options: [], range: NSRange(xmpString.startIndex..., in: xmpString)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: xmpString) {
                return String(xmpString[range])
            }
        }
        return nil
    }

    /// Extracts the Gain Map length from GContainer directory in XMP
    private func extractGainMapLength(from xmpString: String) -> Int? {
        // Look for Item:Length in GainMap semantic item
        // Pattern: Item:Semantic="GainMap"...Item:Length="12345"

        // First check if GainMap semantic exists
        guard xmpString.contains("GainMap") else { return nil }

        // Try to find Item:Length near GainMap
        let pattern = "Item:Length=\"(\\d+)\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: xmpString, options: [], range: NSRange(xmpString.startIndex..., in: xmpString)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: xmpString),
           let length = Int(xmpString[range]) {
            return length
        }
        return nil
    }

    /// Extracts Gain Map JPEG data from the end of the image file
    private func extractGainMapData(from imageData: Data, length: Int) -> Data? {
        // Gain Map is appended after the primary image's EOI marker
        // Search for the last EOI (0xFFD9) that marks the start of gain map

        guard length > 0, length < imageData.count else { return nil }

        // The gain map should be at the end of the file
        let gainMapStart = imageData.count - length
        guard gainMapStart > 0 else { return nil }

        // Verify the gain map starts with JPEG SOI marker (0xFFD8)
        guard gainMapStart + 1 < imageData.count else { return nil }

        let soi1 = imageData[gainMapStart]
        let soi2 = imageData[gainMapStart + 1]

        if soi1 == 0xFF && soi2 == 0xD8 {
            return imageData.suffix(length)
        }

        return nil
    }

    internal func parseGIF(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 10 else {
            status = .statusInvalidData
            return
        }

        let width = Int(bytes[6]) | (Int(bytes[7]) << 8)
        let height = Int(bytes[8]) | (Int(bytes[9]) << 8)

        // Count frames for animated GIF
        var frameCount = 0
        var offset = 13 // Skip header and logical screen descriptor

        // Skip global color table if present
        let flags = bytes[10]
        if flags & 0x80 != 0 {
            let colorTableSize = 1 << ((flags & 0x07) + 1)
            offset += colorTableSize * 3
        }

        while offset < count {
            if bytes[offset] == 0x2C { // Image descriptor
                frameCount += 1
                offset += 10
                // Skip local color table if present
                if offset < count {
                    let localFlags = bytes[offset - 1]
                    if localFlags & 0x80 != 0 {
                        let localColorTableSize = 1 << ((localFlags & 0x07) + 1)
                        offset += localColorTableSize * 3
                    }
                }
            } else if bytes[offset] == 0x21 { // Extension
                offset += 2
                while offset < count && bytes[offset] != 0 {
                    offset += Int(bytes[offset]) + 1
                }
                offset += 1
            } else if bytes[offset] == 0x3B { // Trailer
                break
            } else {
                offset += 1
            }
        }

        imageCount = max(frameCount, 1)
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
        auxiliaryDataByIndex = (0..<imageCount).map { _ in [:] }

        status = .statusComplete
    }

    internal func parseBMP(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 26 else {
            status = .statusInvalidData
            return
        }

        // BMP header: width at offset 18, height at offset 22 (4 bytes each, little-endian)
        let width = Int(bytes[18]) | (Int(bytes[19]) << 8) |
                    (Int(bytes[20]) << 16) | (Int(bytes[21]) << 24)
        var height = Int(bytes[22]) | (Int(bytes[23]) << 8) |
                     (Int(bytes[24]) << 16) | (Int(bytes[25]) << 24)

        // Height can be negative for top-down DIB
        if height < 0 {
            height = -height
        }

        let bitsPerPixel = Int(bytes[28]) | (Int(bytes[29]) << 8)

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyDepth: bitsPerPixel,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseTIFF(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 8 else {
            status = .statusInvalidData
            return
        }

        let isLittleEndian = bytes[0] == 0x49

        func readUInt16(at offset: Int) -> Int {
            if isLittleEndian {
                return Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            } else {
                return (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
            }
        }

        func readUInt32(at offset: Int) -> Int {
            if isLittleEndian {
                return Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8) |
                       (Int(bytes[offset + 2]) << 16) | (Int(bytes[offset + 3]) << 24)
            } else {
                return (Int(bytes[offset]) << 24) | (Int(bytes[offset + 1]) << 16) |
                       (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
            }
        }

        // IFD offset at byte 4
        let ifdOffset = readUInt32(at: 4)
        var width = 0
        var height = 0

        if ifdOffset > 0 && ifdOffset + 2 < count {
            let numEntries = readUInt16(at: ifdOffset)
            var entryOffset = ifdOffset + 2

            for _ in 0..<numEntries {
                guard entryOffset + 12 <= count else { break }

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
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        auxiliaryDataByIndex = [[:]]
        status = .statusComplete
    }

    internal func parseWebP(bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 30 else {
            status = .statusInvalidData
            return
        }

        // WebP format: RIFF size WEBP chunk
        var width = 0
        var height = 0
        var offset = 12

        while offset + 8 < count {
            let chunkType = String(
                bytes: UnsafeBufferPointer(start: bytes.advanced(by: offset), count: 4),
                encoding: .ascii
            ) ?? ""

            if chunkType == "VP8 " {
                // Lossy WebP
                if offset + 14 < count {
                    let frameOffset = offset + 10
                    width = Int(bytes[frameOffset + 6]) | ((Int(bytes[frameOffset + 7]) & 0x3F) << 8)
                    height = Int(bytes[frameOffset + 8]) | ((Int(bytes[frameOffset + 9]) & 0x3F) << 8)
                }
                break
            } else if chunkType == "VP8L" {
                // Lossless WebP
                if offset + 15 < count {
                    let signature = bytes[offset + 8]
                    if signature == 0x2F {
                        let bits = UInt32(bytes[offset + 9]) |
                                  (UInt32(bytes[offset + 10]) << 8) |
                                  (UInt32(bytes[offset + 11]) << 16) |
                                  (UInt32(bytes[offset + 12]) << 24)
                        width = Int((bits & 0x3FFF) + 1)
                        height = Int(((bits >> 14) & 0x3FFF) + 1)
                    }
                }
                break
            } else if chunkType == "VP8X" {
                // Extended WebP
                if offset + 18 < count {
                    width = (Int(bytes[offset + 12]) |
                            (Int(bytes[offset + 13]) << 8) |
                            (Int(bytes[offset + 14]) << 16)) + 1
                    height = (Int(bytes[offset + 15]) |
                             (Int(bytes[offset + 16]) << 8) |
                             (Int(bytes[offset + 17]) << 16)) + 1
                }
                break
            }

            let chunkSize = Int(bytes[offset + 4]) |
                           (Int(bytes[offset + 5]) << 8) |
                           (Int(bytes[offset + 6]) << 16) |
                           (Int(bytes[offset + 7]) << 24)
            offset += 8 + chunkSize + (chunkSize & 1) // Padding to even
        }

        imageCount = 1
        properties = [
            kCGImagePropertyPixelWidth: width,
            kCGImagePropertyPixelHeight: height,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]
        imageProperties = [properties]
        auxiliaryDataByIndex = [[:]]
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

// MARK: - CGImageSource Creation Functions

/// Creates an image source that reads from a location specified by a URL.
public func CGImageSourceCreateWithURL(_ url: URL, _ options: [String: Any]?) -> CGImageSource? {
    // Read file data
    guard let data = try? Data(contentsOf: url) else {
        return nil
    }
    return CGImageSource(data: data, options: options)
}

/// Creates an image source that reads from a Data object.
public func CGImageSourceCreateWithData(_ data: Data, _ options: [String: Any]?) -> CGImageSource? {
    return CGImageSource(data: data, options: options)
}

/// Creates an image source that reads data from the specified data provider.
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
        "public.tiff",
        "org.webmproject.webp"
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
    guard index >= 0 && index < isrc.imageCount else {
        return nil
    }

    // Decode based on image type
    guard let sourceType = isrc.sourceType else {
        return nil
    }

    var pixelData: Data?
    var width = 0
    var height = 0
    var hasAlpha = false

    switch sourceType {
    case "public.png":
        if let result = PNGDecoder.decode(data: isrc.imageData) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = result.hasAlpha
        }

    case "public.jpeg":
        if let result = JPEGDecoder.decode(data: isrc.imageData) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = false
        }

    case "com.compuserve.gif":
        if let result = GIFDecoder.decode(data: isrc.imageData, frameIndex: index) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = result.hasAlpha
        }

    case "com.microsoft.bmp":
        if let result = BMPDecoder.decode(data: isrc.imageData) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = result.hasAlpha
        }

    case "public.tiff":
        if let result = TIFFDecoder.decode(data: isrc.imageData) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = result.hasAlpha
        }

    case "org.webmproject.webp":
        if let result = WebPDecoder.decode(data: isrc.imageData) {
            pixelData = result.pixels
            width = result.width
            height = result.height
            hasAlpha = result.hasAlpha
        }

    default:
        // Unsupported format - return nil
        return nil
    }

    guard let pixels = pixelData, width > 0, height > 0 else {
        return nil
    }

    // Create CGImage using OpenCoreGraphics
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        return nil
    }

    let bytesPerRow = width * 4
    let provider = CGDataProvider(data: pixels)

    let alphaInfo: CGImageAlphaInfo = hasAlpha ? .premultipliedLast : .noneSkipLast

    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    )
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
