// PNGEncoder.swift
// OpenImageIO
//
// PNG image format encoder with DEFLATE compression

import Foundation
import OpenCoreGraphics

/// PNG image encoder
internal struct PNGEncoder {

    // MARK: - Constants

    private static let PNG_SIGNATURE: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    // Filter types
    private static let FILTER_NONE: UInt8 = 0
    private static let FILTER_SUB: UInt8 = 1
    private static let FILTER_UP: UInt8 = 2
    private static let FILTER_AVERAGE: UInt8 = 3
    private static let FILTER_PAETH: UInt8 = 4

    // MARK: - Public API

    /// Encode CGImage to PNG data
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        let width = image.width
        let height = image.height

        guard width > 0 && height > 0 else { return nil }

        // Get pixel data
        guard let imageData = image.dataProvider?.data else { return nil }

        var output = Data()

        // PNG Signature
        output.append(contentsOf: PNG_SIGNATURE)

        // Determine color type and bit depth
        let hasAlpha = imageHasAlpha(image)
        let colorType: UInt8 = hasAlpha ? 6 : 2 // 6 = RGBA, 2 = RGB
        let bitDepth: UInt8 = 8
        let bytesPerPixel = hasAlpha ? 4 : 3

        // IHDR chunk
        var ihdr: [UInt8] = []
        ihdr.append(contentsOf: withUnsafeBytes(of: UInt32(width).bigEndian) { Array($0) })
        ihdr.append(contentsOf: withUnsafeBytes(of: UInt32(height).bigEndian) { Array($0) })
        ihdr.append(bitDepth)
        ihdr.append(colorType)
        ihdr.append(0) // Compression method (deflate)
        ihdr.append(0) // Filter method (adaptive)
        ihdr.append(0) // Interlace method (none)
        output.append(contentsOf: createChunk(type: "IHDR", data: ihdr))

        // Prepare filtered image data
        var filteredData: [UInt8] = []

        // Use adaptive filtering for better compression
        var previousRow = [UInt8](repeating: 0, count: width * bytesPerPixel)

        for y in 0..<height {
            var currentRow = [UInt8](repeating: 0, count: width * bytesPerPixel)

            // Extract row from source
            for x in 0..<width {
                let srcIndex = (y * image.bytesPerRow) + (x * 4) // Source is always RGBA
                let dstIndex = x * bytesPerPixel

                if srcIndex + 3 < imageData.count {
                    currentRow[dstIndex] = imageData[srcIndex]         // R
                    currentRow[dstIndex + 1] = imageData[srcIndex + 1] // G
                    currentRow[dstIndex + 2] = imageData[srcIndex + 2] // B
                    if hasAlpha {
                        currentRow[dstIndex + 3] = imageData[srcIndex + 3] // A
                    }
                }
            }

            // Choose best filter for this row
            let (filterType, filteredRow) = selectBestFilter(
                currentRow: currentRow,
                previousRow: previousRow,
                bytesPerPixel: bytesPerPixel
            )

            filteredData.append(filterType)
            filteredData.append(contentsOf: filteredRow)

            previousRow = currentRow
        }

        // Compress filtered data with DEFLATE
        guard let compressedData = Deflate.deflate(data: Data(filteredData)) else {
            // Fallback to uncompressed if compression fails
            return encodeUncompressed(image: image)
        }

        // IDAT chunk
        output.append(contentsOf: createChunk(type: "IDAT", data: Array(compressedData)))

        // IEND chunk
        output.append(contentsOf: createChunk(type: "IEND", data: []))

        return output
    }

    // MARK: - Filter Selection

    private static func selectBestFilter(
        currentRow: [UInt8],
        previousRow: [UInt8],
        bytesPerPixel: Int
    ) -> (UInt8, [UInt8]) {
        // Try all filter types and choose the one with lowest sum of absolute values
        let filterNone = applyFilter(currentRow: currentRow, previousRow: previousRow, bytesPerPixel: bytesPerPixel, filterType: FILTER_NONE)
        let filterSub = applyFilter(currentRow: currentRow, previousRow: previousRow, bytesPerPixel: bytesPerPixel, filterType: FILTER_SUB)
        let filterUp = applyFilter(currentRow: currentRow, previousRow: previousRow, bytesPerPixel: bytesPerPixel, filterType: FILTER_UP)
        let filterAverage = applyFilter(currentRow: currentRow, previousRow: previousRow, bytesPerPixel: bytesPerPixel, filterType: FILTER_AVERAGE)
        let filterPaeth = applyFilter(currentRow: currentRow, previousRow: previousRow, bytesPerPixel: bytesPerPixel, filterType: FILTER_PAETH)

        // Calculate sum of absolute values for each filter
        let scores = [
            (FILTER_NONE, calculateFilterScore(filterNone)),
            (FILTER_SUB, calculateFilterScore(filterSub)),
            (FILTER_UP, calculateFilterScore(filterUp)),
            (FILTER_AVERAGE, calculateFilterScore(filterAverage)),
            (FILTER_PAETH, calculateFilterScore(filterPaeth))
        ]

        // Find minimum score
        let best = scores.min { $0.1 < $1.1 }!

        switch best.0 {
        case FILTER_NONE: return (FILTER_NONE, filterNone)
        case FILTER_SUB: return (FILTER_SUB, filterSub)
        case FILTER_UP: return (FILTER_UP, filterUp)
        case FILTER_AVERAGE: return (FILTER_AVERAGE, filterAverage)
        case FILTER_PAETH: return (FILTER_PAETH, filterPaeth)
        default: return (FILTER_NONE, filterNone)
        }
    }

    private static func calculateFilterScore(_ data: [UInt8]) -> Int {
        return data.reduce(0) { sum, byte in
            // Use signed interpretation for better scoring
            let signed = Int8(bitPattern: byte)
            return sum + abs(Int(signed))
        }
    }

    private static func applyFilter(
        currentRow: [UInt8],
        previousRow: [UInt8],
        bytesPerPixel: Int,
        filterType: UInt8
    ) -> [UInt8] {
        var filtered = [UInt8](repeating: 0, count: currentRow.count)

        switch filterType {
        case FILTER_NONE:
            return currentRow

        case FILTER_SUB:
            for i in 0..<currentRow.count {
                let a = i >= bytesPerPixel ? currentRow[i - bytesPerPixel] : 0
                filtered[i] = currentRow[i] &- a
            }

        case FILTER_UP:
            for i in 0..<currentRow.count {
                let b = previousRow[i]
                filtered[i] = currentRow[i] &- b
            }

        case FILTER_AVERAGE:
            for i in 0..<currentRow.count {
                let a = i >= bytesPerPixel ? Int(currentRow[i - bytesPerPixel]) : 0
                let b = Int(previousRow[i])
                filtered[i] = currentRow[i] &- UInt8((a + b) / 2)
            }

        case FILTER_PAETH:
            for i in 0..<currentRow.count {
                let a = i >= bytesPerPixel ? Int(currentRow[i - bytesPerPixel]) : 0
                let b = Int(previousRow[i])
                let c = i >= bytesPerPixel ? Int(previousRow[i - bytesPerPixel]) : 0
                filtered[i] = currentRow[i] &- UInt8(paethPredictor(a: a, b: b, c: c))
            }

        default:
            return currentRow
        }

        return filtered
    }

    private static func paethPredictor(a: Int, b: Int, c: Int) -> Int {
        let p = a + b - c
        let pa = abs(p - a)
        let pb = abs(p - b)
        let pc = abs(p - c)

        if pa <= pb && pa <= pc {
            return a
        } else if pb <= pc {
            return b
        } else {
            return c
        }
    }

    // MARK: - Fallback Uncompressed

    private static func encodeUncompressed(image: CGImage) -> Data? {
        let width = image.width
        let height = image.height

        guard let imageData = image.dataProvider?.data else { return nil }

        var output = Data()

        // PNG Signature
        output.append(contentsOf: PNG_SIGNATURE)

        // IHDR
        let hasAlpha = imageHasAlpha(image)
        let colorType: UInt8 = hasAlpha ? 6 : 2
        let bytesPerPixel = hasAlpha ? 4 : 3

        var ihdr: [UInt8] = []
        ihdr.append(contentsOf: withUnsafeBytes(of: UInt32(width).bigEndian) { Array($0) })
        ihdr.append(contentsOf: withUnsafeBytes(of: UInt32(height).bigEndian) { Array($0) })
        ihdr.append(8) // Bit depth
        ihdr.append(colorType)
        ihdr.append(0) // Compression
        ihdr.append(0) // Filter
        ihdr.append(0) // Interlace
        output.append(contentsOf: createChunk(type: "IHDR", data: ihdr))

        // Prepare unfiltered image data
        var rawData: [UInt8] = []
        for y in 0..<height {
            rawData.append(FILTER_NONE) // No filter
            for x in 0..<width {
                let srcIndex = (y * image.bytesPerRow) + (x * 4)
                if srcIndex + 3 < imageData.count {
                    rawData.append(imageData[srcIndex])     // R
                    rawData.append(imageData[srcIndex + 1]) // G
                    rawData.append(imageData[srcIndex + 2]) // B
                    if hasAlpha {
                        rawData.append(imageData[srcIndex + 3]) // A
                    }
                }
            }
        }

        // Use stored blocks (no compression)
        var idat: [UInt8] = []
        idat.append(0x78) // zlib CMF
        idat.append(0x01) // zlib FLG

        // Store blocks
        var offset = 0
        while offset < rawData.count {
            let remaining = rawData.count - offset
            let blockSize = min(remaining, 65535)
            let isFinal = (offset + blockSize) >= rawData.count

            idat.append(isFinal ? 0x01 : 0x00)
            idat.append(contentsOf: withUnsafeBytes(of: UInt16(blockSize).littleEndian) { Array($0) })
            idat.append(contentsOf: withUnsafeBytes(of: (~UInt16(blockSize)).littleEndian) { Array($0) })
            idat.append(contentsOf: rawData[offset..<(offset + blockSize)])

            offset += blockSize
        }

        // Adler-32
        let adler = Deflate.adler32(Data(rawData))
        idat.append(contentsOf: withUnsafeBytes(of: adler.bigEndian) { Array($0) })

        output.append(contentsOf: createChunk(type: "IDAT", data: idat))

        // IEND
        output.append(contentsOf: createChunk(type: "IEND", data: []))

        return output
    }

    // MARK: - Helper Functions

    private static func imageHasAlpha(_ image: CGImage) -> Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        switch alphaInfo {
        case .premultipliedLast, .premultipliedFirst, .last, .first, .alphaOnly:
            return true
        default:
            return false
        }
    }

    private static func createChunk(type: String, data: [UInt8]) -> [UInt8] {
        var chunk: [UInt8] = []

        // Length
        chunk.append(contentsOf: withUnsafeBytes(of: UInt32(data.count).bigEndian) { Array($0) })

        // Type
        let typeBytes = Array(type.utf8)
        chunk.append(contentsOf: typeBytes)

        // Data
        chunk.append(contentsOf: data)

        // CRC
        var crcData = typeBytes
        crcData.append(contentsOf: data)
        let crc = crc32(crcData)
        chunk.append(contentsOf: withUnsafeBytes(of: crc.bigEndian) { Array($0) })

        return chunk
    }

    private static func crc32(_ data: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crc32Table[index] ^ (crc >> 8)
        }
        return ~crc
    }

    // Pre-computed CRC32 table
    private static let crc32Table: [UInt32] = {
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
}
