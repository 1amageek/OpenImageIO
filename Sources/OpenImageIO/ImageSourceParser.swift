// ImageSourceParser.swift
// OpenImageIO

@preconcurrency import Foundation
import OpenCoreGraphics

internal enum CGImageSourcePropertyValue: Sendable {
    case integer(Int)
    case string(String)

    internal var materialized: Any {
        switch self {
        case .integer(let value): return value
        case .string(let value): return value
        }
    }
}

internal struct CGImageSourceDecodedImage: Sendable {
    let pixels: Data
    let width: Int
    let height: Int
    let hasAlpha: Bool

    internal init?(pixels: Data, width: Int, height: Int, hasAlpha: Bool) {
        guard width > 0, height > 0 else { return nil }
        let (pixelCount, pixelCountOverflow) = width.multipliedReportingOverflow(by: height)
        let (byteCount, byteCountOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !pixelCountOverflow, !byteCountOverflow, pixels.count == byteCount else {
            return nil
        }
        self.pixels = pixels
        self.width = width
        self.height = height
        self.hasAlpha = hasAlpha
    }

    internal func makeImage() -> CGImage? {
        makeDecodedImage(
            pixels: pixels,
            width: width,
            height: height,
            hasAlpha: hasAlpha
        )
    }
}

internal struct CGImageSourceParsedState: Sendable {
    internal var imageCount = 0
    internal var sourceType: String?
    internal var status: CGImageSourceStatus = .statusIncomplete
    internal var properties: [String: CGImageSourcePropertyValue] = [:]
    internal var imageProperties: [[String: CGImageSourcePropertyValue]] = []
    internal var decodedImages: [CGImageSourceDecodedImage] = []
    internal var auxiliaryDataByIndex: [[String: [String: CGImageSourcePropertyValue]]] = []

    internal func materializedProperties() -> [String: Any] {
        properties.mapValues(\.materialized)
    }

    internal func materializedProperties(at index: Int) -> [String: Any]? {
        guard imageProperties.indices.contains(index) else { return nil }
        return imageProperties[index].mapValues(\.materialized)
    }

    internal func materializedAuxiliaryData(
        at index: Int,
        type: String
    ) -> [String: Any]? {
        guard auxiliaryDataByIndex.indices.contains(index),
              let values = auxiliaryDataByIndex[index][type] else { return nil }
        return values.mapValues(\.materialized)
    }
}

internal struct ImageSourceParser {
    private let data: Data

    internal init(data: Data) {
        self.data = data
    }

    internal func parse(final: Bool, incremental: Bool) -> CGImageSourceParsedState {
        guard !data.isEmpty else { return CGImageSourceParsedState() }

        guard let sourceType = detectedType else {
            var parsed = CGImageSourceParsedState()
            if incremental && !final {
                parsed.status = .statusReadingHeader
            } else {
                parsed.status = data.count < 8 ? .statusInvalidData : .statusUnknownType
            }
            return parsed
        }

        let complete: CGImageSourceParsedState?
        switch sourceType {
        case "public.png":
            complete = parsePNG()
        case "public.jpeg":
            complete = parseJPEG()
        case "com.compuserve.gif":
            complete = parseGIF()
        case "com.microsoft.bmp":
            complete = parseBMP()
        case "public.tiff":
            complete = parseTIFF()
        default:
            complete = nil
        }

        if var complete {
            if incremental && !final {
                complete.status = .statusIncomplete
            }
            return complete
        }

        if incremental && !final {
            return partialState(for: sourceType)
        }

        var invalid = CGImageSourceParsedState()
        invalid.sourceType = sourceType
        invalid.status = .statusInvalidData
        return invalid
    }

    private var detectedType: String? {
        data.withUnsafeBytes { buffer in
            guard let bytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }
            if data.count >= 8,
               bytes[0] == 0x89, bytes[1] == 0x50,
               bytes[2] == 0x4E, bytes[3] == 0x47,
               bytes[4] == 0x0D, bytes[5] == 0x0A,
               bytes[6] == 0x1A, bytes[7] == 0x0A {
                return "public.png"
            }
            if data.count >= 3,
               bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
                return "public.jpeg"
            }
            if data.count >= 6,
               bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46,
               bytes[3] == 0x38, (bytes[4] == 0x37 || bytes[4] == 0x39), bytes[5] == 0x61 {
                return "com.compuserve.gif"
            }
            if data.count >= 2, bytes[0] == 0x42, bytes[1] == 0x4D {
                return "com.microsoft.bmp"
            }
            if data.count >= 4,
               ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
                (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A)) {
                return "public.tiff"
            }
            return nil
        }
    }

    private func partialState(for sourceType: String) -> CGImageSourceParsedState {
        var parsed = CGImageSourceParsedState()
        parsed.sourceType = sourceType
        parsed.status = data.count <= headerRecognitionByteCount(for: sourceType)
            ? .statusReadingHeader
            : .statusIncomplete

        switch sourceType {
        case "public.png":
            if data.count >= 16 {
                parsed.imageCount = 1
            }
            if data.count >= 26 {
                let width = bigEndianInt(at: 16)
                let height = bigEndianInt(at: 20)
                if width > 0, height > 0 {
                    parsed.properties = [
                        kCGImagePropertyPixelWidth: .integer(width),
                        kCGImagePropertyPixelHeight: .integer(height),
                        kCGImagePropertyDepth: .integer(Int(data[24])),
                        kCGImagePropertyColorModel: .string(colorModelFromPNGColorType(Int(data[25])))
                    ]
                    parsed.imageProperties = [parsed.properties]
                }
            }
        case "public.jpeg":
            parsed.imageCount = 1
        case "com.compuserve.gif":
            if data.count >= 10 {
                let width = littleEndianInt16(at: 6)
                let height = littleEndianInt16(at: 8)
                if width > 0, height > 0 {
                    parsed.imageCount = max(1, GIFDecoder.frameCount(data: data))
                    parsed.properties = [
                        kCGImagePropertyPixelWidth: .integer(width),
                        kCGImagePropertyPixelHeight: .integer(height),
                        kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB),
                        kCGImagePropertyImageCount: .integer(parsed.imageCount)
                    ]
                    parsed.imageProperties = Array(
                        repeating: [
                            kCGImagePropertyPixelWidth: .integer(width),
                            kCGImagePropertyPixelHeight: .integer(height)
                        ],
                        count: parsed.imageCount
                    )
                }
            }
        case "com.microsoft.bmp":
            if data.count >= 26 {
                let width = littleEndianInt32(at: 18)
                let rawHeight = littleEndianInt32(at: 22)
                let height = rawHeight == Int32.min ? 0 : abs(Int(rawHeight))
                if width > 0, height > 0 {
                    parsed.imageCount = 1
                    parsed.properties = [
                        kCGImagePropertyPixelWidth: .integer(Int(width)),
                        kCGImagePropertyPixelHeight: .integer(height),
                        kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB)
                    ]
                    parsed.imageProperties = [parsed.properties]
                }
            }
        case "public.tiff":
            let count = TIFFDecoder.pageCount(data: data)
            parsed.imageCount = count
        default:
            break
        }

        parsed.auxiliaryDataByIndex = Array(repeating: [:], count: parsed.imageCount)
        return parsed
    }

    private func headerRecognitionByteCount(for sourceType: String) -> Int {
        switch sourceType {
        case "public.png": return 8
        case "public.jpeg": return 3
        case "com.compuserve.gif": return 6
        case "com.microsoft.bmp": return 2
        case "public.tiff": return 4
        default: return 8
        }
    }

    private func parsePNG() -> CGImageSourceParsedState? {
        guard data.count > 25,
              let decoded = PNGDecoder.decode(data: data),
              let decodedImage = CGImageSourceDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: decoded.hasAlpha
              ) else { return nil }

        let headerWidth = bigEndianInt(at: 16)
        let headerHeight = bigEndianInt(at: 20)
        guard decoded.width == headerWidth, decoded.height == headerHeight else { return nil }

        var parsed = CGImageSourceParsedState()
        parsed.imageCount = 1
        parsed.sourceType = "public.png"
        parsed.status = .statusComplete
        parsed.properties = [
            kCGImagePropertyPixelWidth: .integer(decoded.width),
            kCGImagePropertyPixelHeight: .integer(decoded.height),
            kCGImagePropertyDepth: .integer(Int(data[24])),
            kCGImagePropertyColorModel: .string(colorModelFromPNGColorType(Int(data[25])))
        ]
        parsed.imageProperties = [parsed.properties]
        parsed.decodedImages = [decodedImage]
        parsed.auxiliaryDataByIndex = [[:]]
        return parsed
    }

    private func parseJPEG() -> CGImageSourceParsedState? {
        guard let decoded = JPEGDecoder.decode(data: data),
              let decodedImage = CGImageSourceDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: false
              ) else { return nil }

        var parsed = CGImageSourceParsedState()
        parsed.imageCount = 1
        parsed.sourceType = "public.jpeg"
        parsed.status = .statusComplete
        parsed.properties = [
            kCGImagePropertyPixelWidth: .integer(decoded.width),
            kCGImagePropertyPixelHeight: .integer(decoded.height),
            kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB)
        ]
        parsed.imageProperties = [parsed.properties]
        parsed.decodedImages = [decodedImage]
        parsed.auxiliaryDataByIndex = [[:]]
        return parsed
    }

    private func parseGIF() -> CGImageSourceParsedState? {
        guard data.count > 12 else { return nil }
        let width = littleEndianInt16(at: 6)
        let height = littleEndianInt16(at: 8)
        let frameCount = GIFDecoder.frameCount(data: data)
        guard width > 0, height > 0, frameCount > 0 else { return nil }

        var frames: [CGImageSourceDecodedImage] = []
        frames.reserveCapacity(frameCount)
        for index in 0..<frameCount {
            guard let decoded = GIFDecoder.decode(data: data, frameIndex: index),
                  decoded.width == width,
                  decoded.height == height,
                  let decodedImage = CGImageSourceDecodedImage(
                    pixels: decoded.pixels,
                    width: decoded.width,
                    height: decoded.height,
                    hasAlpha: decoded.hasAlpha
                  ) else { return nil }
            frames.append(decodedImage)
        }

        var parsed = CGImageSourceParsedState()
        parsed.imageCount = frameCount
        parsed.sourceType = "com.compuserve.gif"
        parsed.status = .statusComplete
        parsed.properties = [
            kCGImagePropertyPixelWidth: .integer(width),
            kCGImagePropertyPixelHeight: .integer(height),
            kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB),
            kCGImagePropertyImageCount: .integer(frameCount)
        ]
        parsed.imageProperties = Array(
            repeating: [
                kCGImagePropertyPixelWidth: .integer(width),
                kCGImagePropertyPixelHeight: .integer(height)
            ],
            count: frameCount
        )
        parsed.decodedImages = frames
        parsed.auxiliaryDataByIndex = Array(repeating: [:], count: frameCount)
        return parsed
    }

    private func parseBMP() -> CGImageSourceParsedState? {
        guard data.count >= 30,
              let decoded = BMPDecoder.decode(data: data),
              let decodedImage = CGImageSourceDecodedImage(
                pixels: decoded.pixels,
                width: decoded.width,
                height: decoded.height,
                hasAlpha: decoded.hasAlpha
              ) else { return nil }

        var parsed = CGImageSourceParsedState()
        parsed.imageCount = 1
        parsed.sourceType = "com.microsoft.bmp"
        parsed.status = .statusComplete
        parsed.properties = [
            kCGImagePropertyPixelWidth: .integer(decoded.width),
            kCGImagePropertyPixelHeight: .integer(decoded.height),
            kCGImagePropertyDepth: .integer(littleEndianInt16(at: 28)),
            kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB)
        ]
        parsed.imageProperties = [parsed.properties]
        parsed.decodedImages = [decodedImage]
        parsed.auxiliaryDataByIndex = [[:]]
        return parsed
    }

    private func parseTIFF() -> CGImageSourceParsedState? {
        let pageCount = TIFFDecoder.pageCount(data: data)
        guard pageCount > 0 else { return nil }

        var pages: [CGImageSourceDecodedImage] = []
        var perPageProperties: [[String: CGImageSourcePropertyValue]] = []
        pages.reserveCapacity(pageCount)
        perPageProperties.reserveCapacity(pageCount)
        for index in 0..<pageCount {
            guard let page = TIFFDecoder.decode(data: data, frameIndex: index),
                  let decodedImage = CGImageSourceDecodedImage(
                    pixels: page.pixels,
                    width: page.width,
                    height: page.height,
                    hasAlpha: page.hasAlpha
                  ) else { return nil }
            pages.append(decodedImage)
            perPageProperties.append([
                kCGImagePropertyPixelWidth: .integer(page.width),
                kCGImagePropertyPixelHeight: .integer(page.height),
                kCGImagePropertyColorModel: .string(kCGImagePropertyColorModelRGB)
            ])
        }

        var parsed = CGImageSourceParsedState()
        parsed.imageCount = pageCount
        parsed.sourceType = "public.tiff"
        parsed.status = .statusComplete
        parsed.properties = perPageProperties[0]
        if pageCount > 1 {
            parsed.properties[kCGImagePropertyImageCount] = .integer(pageCount)
        }
        parsed.imageProperties = perPageProperties
        parsed.decodedImages = pages
        parsed.auxiliaryDataByIndex = Array(repeating: [:], count: pageCount)
        return parsed
    }

    private func bigEndianInt(at offset: Int) -> Int {
        (Int(data[offset]) << 24)
            | (Int(data[offset + 1]) << 16)
            | (Int(data[offset + 2]) << 8)
            | Int(data[offset + 3])
    }

    private func littleEndianInt16(at offset: Int) -> Int {
        Int(data[offset]) | (Int(data[offset + 1]) << 8)
    }

    private func littleEndianInt32(at offset: Int) -> Int32 {
        let raw = UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
        return Int32(bitPattern: raw)
    }

    private func colorModelFromPNGColorType(_ colorType: Int) -> String {
        switch colorType {
        case 0, 4: return kCGImagePropertyColorModelGray
        case 2, 3, 6: return kCGImagePropertyColorModelRGB
        default: return kCGImagePropertyColorModelRGB
        }
    }
}

internal func makeDecodedImage(
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
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(
            rawValue: (hasAlpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue
        ),
        provider: CGDataProvider(data: pixels),
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    )
}
