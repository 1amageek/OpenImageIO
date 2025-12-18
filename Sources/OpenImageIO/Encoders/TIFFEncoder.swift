// TIFFEncoder.swift
// OpenImageIO
//
// TIFF image format encoder with multi-page support

import Foundation
import OpenCoreGraphics

/// TIFF image encoder
internal struct TIFFEncoder {

    // MARK: - TIFF Constants

    /// TIFF byte order markers
    private static let LITTLE_ENDIAN_MARKER: [UInt8] = [0x49, 0x49] // "II"
    private static let BIG_ENDIAN_MARKER: [UInt8] = [0x4D, 0x4D]    // "MM"

    /// TIFF magic number
    private static let TIFF_MAGIC: UInt16 = 42

    // TIFF Tag IDs
    private static let TAG_IMAGE_WIDTH: UInt16 = 256
    private static let TAG_IMAGE_LENGTH: UInt16 = 257
    private static let TAG_BITS_PER_SAMPLE: UInt16 = 258
    private static let TAG_COMPRESSION: UInt16 = 259
    private static let TAG_PHOTOMETRIC_INTERPRETATION: UInt16 = 262
    private static let TAG_STRIP_OFFSETS: UInt16 = 273
    private static let TAG_SAMPLES_PER_PIXEL: UInt16 = 277
    private static let TAG_ROWS_PER_STRIP: UInt16 = 278
    private static let TAG_STRIP_BYTE_COUNTS: UInt16 = 279
    private static let TAG_X_RESOLUTION: UInt16 = 282
    private static let TAG_Y_RESOLUTION: UInt16 = 283
    private static let TAG_RESOLUTION_UNIT: UInt16 = 296
    private static let TAG_EXTRA_SAMPLES: UInt16 = 338

    // TIFF Data Types
    private static let TYPE_SHORT: UInt16 = 3    // 16-bit unsigned int
    private static let TYPE_LONG: UInt16 = 4     // 32-bit unsigned int
    private static let TYPE_RATIONAL: UInt16 = 5 // Two LONGs: numerator/denominator

    // Compression types
    private static let COMPRESSION_NONE: UInt16 = 1
    // Note: LZW compression requires license consideration and complex implementation

    // Photometric interpretation
    private static let PHOTOMETRIC_RGB: UInt16 = 2

    // Extra samples (for alpha)
    private static let EXTRA_SAMPLE_ASSOCIATED_ALPHA: UInt16 = 1
    private static let EXTRA_SAMPLE_UNASSOCIATED_ALPHA: UInt16 = 2

    // MARK: - Public API

    /// Encode multiple CGImages to multi-page TIFF data
    /// - Parameters:
    ///   - images: Array of images to encode
    ///   - options: Encoding options (optional)
    /// - Returns: TIFF data or nil if encoding fails
    static func encode(images: [CGImage], options: [String: Any]? = nil) -> Data? {
        guard !images.isEmpty else { return nil }

        var output = Data()

        // TIFF Header (8 bytes)
        output.append(contentsOf: LITTLE_ENDIAN_MARKER)                    // Byte order
        output.append(contentsOf: uint16ToLE(TIFF_MAGIC))                 // Magic number
        output.append(contentsOf: uint32ToLE(8))                          // First IFD offset (right after header)

        // Build all IFDs and collect strip data
        var currentOffset: UInt32 = 8
        var ifdDataList: [(ifd: Data, strips: Data)] = []

        for (index, image) in images.enumerated() {
            guard let imageData = image.dataProvider?.data else { continue }

            let hasAlpha = imageHasAlpha(image)
            let isLastImage = (index == images.count - 1)

            // Calculate sizes
            let width = image.width
            let height = image.height
            let samplesPerPixel: UInt16 = hasAlpha ? 4 : 3
            let bytesPerRow = width * Int(samplesPerPixel)
            let stripSize = bytesPerRow * height

            // Build IFD entries
            var entries: [(tag: UInt16, type: UInt16, count: UInt32, value: UInt32)] = []

            // Calculate entry count and additional data offsets
            let numEntries: UInt16 = hasAlpha ? 12 : 11
            let ifdSize = 2 + Int(numEntries) * 12 + 4 // count + entries + next IFD offset

            // Offset for data that doesn't fit in value field
            var extraDataOffset = currentOffset + UInt32(ifdSize)

            // Prepare extra data
            var extraData = Data()

            // BitsPerSample (needs extra data for RGB/RGBA)
            let bitsPerSampleOffset = extraDataOffset
            if hasAlpha {
                extraData.append(contentsOf: uint16ToLE(8))  // R
                extraData.append(contentsOf: uint16ToLE(8))  // G
                extraData.append(contentsOf: uint16ToLE(8))  // B
                extraData.append(contentsOf: uint16ToLE(8))  // A
                extraDataOffset += 8
            } else {
                extraData.append(contentsOf: uint16ToLE(8))  // R
                extraData.append(contentsOf: uint16ToLE(8))  // G
                extraData.append(contentsOf: uint16ToLE(8))  // B
                extraDataOffset += 6
            }

            // Resolution data (rational: 72/1 DPI)
            let xResolutionOffset = extraDataOffset
            extraData.append(contentsOf: uint32ToLE(72))     // Numerator
            extraData.append(contentsOf: uint32ToLE(1))      // Denominator
            extraDataOffset += 8

            let yResolutionOffset = extraDataOffset
            extraData.append(contentsOf: uint32ToLE(72))     // Numerator
            extraData.append(contentsOf: uint32ToLE(1))      // Denominator
            extraDataOffset += 8

            // Strip data will follow extra data
            let stripOffset = extraDataOffset

            // Build IFD entries (must be in tag order)
            entries.append((TAG_IMAGE_WIDTH, TYPE_SHORT, 1, UInt32(width)))
            entries.append((TAG_IMAGE_LENGTH, TYPE_SHORT, 1, UInt32(height)))
            entries.append((TAG_BITS_PER_SAMPLE, TYPE_SHORT, UInt32(samplesPerPixel), bitsPerSampleOffset))
            entries.append((TAG_COMPRESSION, TYPE_SHORT, 1, UInt32(COMPRESSION_NONE)))
            entries.append((TAG_PHOTOMETRIC_INTERPRETATION, TYPE_SHORT, 1, UInt32(PHOTOMETRIC_RGB)))
            entries.append((TAG_STRIP_OFFSETS, TYPE_LONG, 1, stripOffset))
            entries.append((TAG_SAMPLES_PER_PIXEL, TYPE_SHORT, 1, UInt32(samplesPerPixel)))
            entries.append((TAG_ROWS_PER_STRIP, TYPE_SHORT, 1, UInt32(height)))
            entries.append((TAG_STRIP_BYTE_COUNTS, TYPE_LONG, 1, UInt32(stripSize)))
            entries.append((TAG_X_RESOLUTION, TYPE_RATIONAL, 1, xResolutionOffset))
            entries.append((TAG_Y_RESOLUTION, TYPE_RATIONAL, 1, yResolutionOffset))

            if hasAlpha {
                // Extra data for alpha: offset for ExtraSamples value
                let extraSamplesOffset = extraDataOffset
                extraData.append(contentsOf: uint16ToLE(EXTRA_SAMPLE_ASSOCIATED_ALPHA))
                extraDataOffset += 2

                entries.append((TAG_EXTRA_SAMPLES, TYPE_SHORT, 1, extraSamplesOffset))
            }

            entries.append((TAG_RESOLUTION_UNIT, TYPE_SHORT, 1, 2)) // Inches

            // Sort entries by tag
            entries.sort { $0.tag < $1.tag }

            // Build IFD data
            var ifd = Data()
            ifd.append(contentsOf: uint16ToLE(numEntries))

            for entry in entries {
                ifd.append(contentsOf: createIFDEntry(
                    tag: entry.tag,
                    type: entry.type,
                    count: entry.count,
                    value: entry.value
                ))
            }

            // Next IFD offset
            let nextIFDOffset: UInt32 = isLastImage ? 0 : stripOffset + UInt32(stripSize)
            ifd.append(contentsOf: uint32ToLE(nextIFDOffset))

            // Append extra data
            ifd.append(extraData)

            // Build strip data (RGB or RGBA)
            var stripData = Data()
            stripData.reserveCapacity(stripSize)

            for y in 0..<height {
                for x in 0..<width {
                    let srcIndex = y * image.bytesPerRow + x * 4
                    if srcIndex + 3 < imageData.count {
                        stripData.append(imageData[srcIndex])     // R
                        stripData.append(imageData[srcIndex + 1]) // G
                        stripData.append(imageData[srcIndex + 2]) // B
                        if hasAlpha {
                            stripData.append(imageData[srcIndex + 3]) // A
                        }
                    } else {
                        stripData.append(contentsOf: hasAlpha ? [0, 0, 0, 255] : [0, 0, 0])
                    }
                }
            }

            ifdDataList.append((ifd: ifd, strips: stripData))
            currentOffset = nextIFDOffset
        }

        // Write all IFDs and strip data
        for (ifd, strips) in ifdDataList {
            output.append(ifd)
            output.append(strips)
        }

        return output
    }

    /// Encode a single CGImage to TIFF data
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        return encode(images: [image], options: options)
    }

    // MARK: - Helper Functions

    private static func createIFDEntry(
        tag: UInt16,
        type: UInt16,
        count: UInt32,
        value: UInt32
    ) -> [UInt8] {
        var entry: [UInt8] = []
        entry.append(contentsOf: uint16ToLE(tag))
        entry.append(contentsOf: uint16ToLE(type))
        entry.append(contentsOf: uint32ToLE(count))
        entry.append(contentsOf: uint32ToLE(value))
        return entry
    }

    private static func imageHasAlpha(_ image: CGImage) -> Bool {
        let alphaInfo = image.alphaInfo
        switch alphaInfo {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false
        default:
            return true
        }
    }

    private static func uint16ToLE(_ value: UInt16) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }

    private static func uint32ToLE(_ value: UInt32) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }
}
