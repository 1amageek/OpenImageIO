// BMPDecoder.swift
// OpenImageIO
//
// BMP image format decoder

import Foundation

/// BMP image decoder supporting various BMP formats
internal struct BMPDecoder {

    // MARK: - BMP Constants

    private static let BMP_SIGNATURE: UInt16 = 0x4D42 // "BM"

    // Compression types
    private static let BI_RGB: UInt32 = 0
    private static let BI_RLE8: UInt32 = 1
    private static let BI_RLE4: UInt32 = 2
    private static let BI_BITFIELDS: UInt32 = 3

    // MARK: - Decode Result

    struct DecodeResult {
        let pixels: Data
        let width: Int
        let height: Int
        let hasAlpha: Bool
    }

    // MARK: - Public API

    /// Decode BMP data to RGBA pixels
    static func decode(data: Data) -> DecodeResult? {
        guard data.count >= 54 else { return nil }

        return data.withUnsafeBytes { buffer -> DecodeResult? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Verify BMP signature
            let signature = UInt16(ptr[0]) | (UInt16(ptr[1]) << 8)
            guard signature == BMP_SIGNATURE else { return nil }

            // Read BMP header
            let dataOffset = readUInt32LE(ptr, offset: 10)

            // Read DIB header
            let dibHeaderSize = readUInt32LE(ptr, offset: 14)
            guard dibHeaderSize >= 40 else { return nil } // Minimum BITMAPINFOHEADER

            let width = Int(readInt32LE(ptr, offset: 18))
            var height = Int(readInt32LE(ptr, offset: 22))
            let bitsPerPixel = Int(readUInt16LE(ptr, offset: 28))
            let compression = readUInt32LE(ptr, offset: 30)

            guard width > 0 else { return nil }

            // Handle top-down vs bottom-up
            let topDown = height < 0
            if topDown {
                height = -height
            }

            guard height > 0 else { return nil }

            // Read color table if needed
            var colorTable: [(r: UInt8, g: UInt8, b: UInt8, a: UInt8)] = []
            if bitsPerPixel <= 8 {
                let colorTableOffset = 14 + Int(dibHeaderSize)
                let numColors = 1 << bitsPerPixel

                for i in 0..<numColors {
                    let offset = colorTableOffset + i * 4
                    guard offset + 3 < data.count else { break }
                    let b = ptr[offset]
                    let g = ptr[offset + 1]
                    let r = ptr[offset + 2]
                    let a: UInt8 = 255
                    colorTable.append((r, g, b, a))
                }
            }

            // Decode pixel data
            let pixelDataOffset = Int(dataOffset)
            guard pixelDataOffset < data.count else { return nil }

            var pixels: [UInt8]
            var hasAlpha = false

            switch compression {
            case BI_RGB:
                let result = decodeRGB(
                    ptr: ptr,
                    dataCount: data.count,
                    pixelDataOffset: pixelDataOffset,
                    width: width,
                    height: height,
                    bitsPerPixel: bitsPerPixel,
                    colorTable: colorTable,
                    topDown: topDown
                )
                pixels = result.pixels
                hasAlpha = result.hasAlpha

            case BI_RLE8:
                guard let result = decodeRLE8(
                    ptr: ptr,
                    dataCount: data.count,
                    pixelDataOffset: pixelDataOffset,
                    width: width,
                    height: height,
                    colorTable: colorTable,
                    topDown: topDown
                ) else { return nil }
                pixels = result
                hasAlpha = true // RLE can have transparency

            case BI_RLE4:
                guard let result = decodeRLE4(
                    ptr: ptr,
                    dataCount: data.count,
                    pixelDataOffset: pixelDataOffset,
                    width: width,
                    height: height,
                    colorTable: colorTable,
                    topDown: topDown
                ) else { return nil }
                pixels = result
                hasAlpha = true

            case BI_BITFIELDS:
                let result = decodeBitfields(
                    ptr: ptr,
                    dataCount: data.count,
                    pixelDataOffset: pixelDataOffset,
                    width: width,
                    height: height,
                    bitsPerPixel: bitsPerPixel,
                    dibHeaderSize: Int(dibHeaderSize),
                    topDown: topDown
                )
                pixels = result.pixels
                hasAlpha = result.hasAlpha

            default:
                return nil
            }

            return DecodeResult(
                pixels: Data(pixels),
                width: width,
                height: height,
                hasAlpha: hasAlpha
            )
        }
    }

    // MARK: - RGB Decoding (No Compression)

    private static func decodeRGB(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        pixelDataOffset: Int,
        width: Int,
        height: Int,
        bitsPerPixel: Int,
        colorTable: [(r: UInt8, g: UInt8, b: UInt8, a: UInt8)],
        topDown: Bool
    ) -> (pixels: [UInt8], hasAlpha: Bool) {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var hasAlpha = false

        // Calculate row size (must be multiple of 4 bytes)
        let rowSize = ((width * bitsPerPixel + 31) / 32) * 4

        for y in 0..<height {
            let srcY = topDown ? y : (height - 1 - y)
            let rowOffset = pixelDataOffset + srcY * rowSize
            let dstY = y

            for x in 0..<width {
                let dstIndex = (dstY * width + x) * 4

                switch bitsPerPixel {
                case 1:
                    let byteIndex = rowOffset + x / 8
                    guard byteIndex < dataCount else { continue }
                    let bitIndex = 7 - (x % 8)
                    let colorIndex = Int((ptr[byteIndex] >> bitIndex) & 0x01)
                    if colorIndex < colorTable.count {
                        let color = colorTable[colorIndex]
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = color.a
                    }

                case 4:
                    let byteIndex = rowOffset + x / 2
                    guard byteIndex < dataCount else { continue }
                    let nibbleIndex = 1 - (x % 2)
                    let colorIndex = Int((ptr[byteIndex] >> (nibbleIndex * 4)) & 0x0F)
                    if colorIndex < colorTable.count {
                        let color = colorTable[colorIndex]
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = color.a
                    }

                case 8:
                    let byteIndex = rowOffset + x
                    guard byteIndex < dataCount else { continue }
                    let colorIndex = Int(ptr[byteIndex])
                    if colorIndex < colorTable.count {
                        let color = colorTable[colorIndex]
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = color.a
                    }

                case 16:
                    let byteIndex = rowOffset + x * 2
                    guard byteIndex + 1 < dataCount else { continue }
                    let pixel16 = UInt16(ptr[byteIndex]) | (UInt16(ptr[byteIndex + 1]) << 8)
                    // 5-5-5 format (most common)
                    let r = UInt8(((pixel16 >> 10) & 0x1F) * 255 / 31)
                    let g = UInt8(((pixel16 >> 5) & 0x1F) * 255 / 31)
                    let b = UInt8((pixel16 & 0x1F) * 255 / 31)
                    pixels[dstIndex] = r
                    pixels[dstIndex + 1] = g
                    pixels[dstIndex + 2] = b
                    pixels[dstIndex + 3] = 255

                case 24:
                    let byteIndex = rowOffset + x * 3
                    guard byteIndex + 2 < dataCount else { continue }
                    pixels[dstIndex] = ptr[byteIndex + 2]     // R
                    pixels[dstIndex + 1] = ptr[byteIndex + 1] // G
                    pixels[dstIndex + 2] = ptr[byteIndex]     // B
                    pixels[dstIndex + 3] = 255                // A

                case 32:
                    let byteIndex = rowOffset + x * 4
                    guard byteIndex + 3 < dataCount else { continue }
                    pixels[dstIndex] = ptr[byteIndex + 2]     // R
                    pixels[dstIndex + 1] = ptr[byteIndex + 1] // G
                    pixels[dstIndex + 2] = ptr[byteIndex]     // B
                    pixels[dstIndex + 3] = ptr[byteIndex + 3] // A
                    if ptr[byteIndex + 3] != 255 {
                        hasAlpha = true
                    }

                default:
                    break
                }
            }
        }

        return (pixels, hasAlpha)
    }

    // MARK: - RLE8 Decoding

    private static func decodeRLE8(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        pixelDataOffset: Int,
        width: Int,
        height: Int,
        colorTable: [(r: UInt8, g: UInt8, b: UInt8, a: UInt8)],
        topDown: Bool
    ) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var x = 0
        var y = topDown ? 0 : height - 1
        var offset = pixelDataOffset

        while offset < dataCount {
            let count = Int(ptr[offset])
            offset += 1
            guard offset < dataCount else { break }
            let value = Int(ptr[offset])
            offset += 1

            if count == 0 {
                switch value {
                case 0: // End of line
                    x = 0
                    y = topDown ? y + 1 : y - 1

                case 1: // End of bitmap
                    return pixels

                case 2: // Delta
                    guard offset + 1 < dataCount else { return nil }
                    x += Int(ptr[offset])
                    y += topDown ? Int(ptr[offset + 1]) : -Int(ptr[offset + 1])
                    offset += 2

                default: // Absolute mode
                    for _ in 0..<value {
                        guard offset < dataCount else { return nil }
                        let colorIndex = Int(ptr[offset])
                        offset += 1

                        if x < width && y >= 0 && y < height && colorIndex < colorTable.count {
                            let dstIndex = (y * width + x) * 4
                            let color = colorTable[colorIndex]
                            pixels[dstIndex] = color.r
                            pixels[dstIndex + 1] = color.g
                            pixels[dstIndex + 2] = color.b
                            pixels[dstIndex + 3] = color.a
                        }
                        x += 1
                    }
                    // Align to word boundary
                    if value % 2 != 0 {
                        offset += 1
                    }
                }
            } else {
                // Run-length encoded
                guard value < colorTable.count else { continue }
                let color = colorTable[value]

                for _ in 0..<count {
                    if x < width && y >= 0 && y < height {
                        let dstIndex = (y * width + x) * 4
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = color.a
                    }
                    x += 1
                }
            }
        }

        return pixels
    }

    // MARK: - RLE4 Decoding

    private static func decodeRLE4(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        pixelDataOffset: Int,
        width: Int,
        height: Int,
        colorTable: [(r: UInt8, g: UInt8, b: UInt8, a: UInt8)],
        topDown: Bool
    ) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var x = 0
        var y = topDown ? 0 : height - 1
        var offset = pixelDataOffset

        while offset < dataCount {
            let count = Int(ptr[offset])
            offset += 1
            guard offset < dataCount else { break }
            let value = Int(ptr[offset])
            offset += 1

            if count == 0 {
                switch value {
                case 0: // End of line
                    x = 0
                    y = topDown ? y + 1 : y - 1

                case 1: // End of bitmap
                    return pixels

                case 2: // Delta
                    guard offset + 1 < dataCount else { return nil }
                    x += Int(ptr[offset])
                    y += topDown ? Int(ptr[offset + 1]) : -Int(ptr[offset + 1])
                    offset += 2

                default: // Absolute mode
                    var pixelsWritten = 0
                    while pixelsWritten < value {
                        guard offset < dataCount else { return nil }
                        let byte = ptr[offset]
                        offset += 1

                        for nibbleIndex in 0..<2 {
                            if pixelsWritten >= value { break }
                            let colorIndex = Int((byte >> ((1 - nibbleIndex) * 4)) & 0x0F)

                            if x < width && y >= 0 && y < height && colorIndex < colorTable.count {
                                let dstIndex = (y * width + x) * 4
                                let color = colorTable[colorIndex]
                                pixels[dstIndex] = color.r
                                pixels[dstIndex + 1] = color.g
                                pixels[dstIndex + 2] = color.b
                                pixels[dstIndex + 3] = color.a
                            }
                            x += 1
                            pixelsWritten += 1
                        }
                    }
                    // Align to word boundary
                    let bytesRead = (value + 1) / 2
                    if bytesRead % 2 != 0 {
                        offset += 1
                    }
                }
            } else {
                // Run-length encoded (alternating pixels)
                let color1Index = (value >> 4) & 0x0F
                let color2Index = value & 0x0F

                for i in 0..<count {
                    let colorIndex = (i % 2 == 0) ? color1Index : color2Index

                    if x < width && y >= 0 && y < height && colorIndex < colorTable.count {
                        let dstIndex = (y * width + x) * 4
                        let color = colorTable[colorIndex]
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = color.a
                    }
                    x += 1
                }
            }
        }

        return pixels
    }

    // MARK: - Bitfields Decoding

    private static func decodeBitfields(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        pixelDataOffset: Int,
        width: Int,
        height: Int,
        bitsPerPixel: Int,
        dibHeaderSize: Int,
        topDown: Bool
    ) -> (pixels: [UInt8], hasAlpha: Bool) {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var hasAlpha = false

        // Read bit masks (after DIB header)
        let maskOffset = 14 + dibHeaderSize
        guard maskOffset + 12 <= dataCount else {
            return (pixels, false)
        }

        let redMask = readUInt32LE(ptr, offset: maskOffset)
        let greenMask = readUInt32LE(ptr, offset: maskOffset + 4)
        let blueMask = readUInt32LE(ptr, offset: maskOffset + 8)
        var alphaMask: UInt32 = 0

        if maskOffset + 16 <= dataCount {
            alphaMask = readUInt32LE(ptr, offset: maskOffset + 12)
            if alphaMask != 0 {
                hasAlpha = true
            }
        }

        // Calculate shifts and sizes
        let redShift = trailingZeroBitCount(redMask)
        let greenShift = trailingZeroBitCount(greenMask)
        let blueShift = trailingZeroBitCount(blueMask)
        let alphaShift = trailingZeroBitCount(alphaMask)

        let redBits = bitCount(redMask)
        let greenBits = bitCount(greenMask)
        let blueBits = bitCount(blueMask)
        let alphaBits = bitCount(alphaMask)

        let rowSize = ((width * bitsPerPixel + 31) / 32) * 4

        for y in 0..<height {
            let srcY = topDown ? y : (height - 1 - y)
            let rowOffset = pixelDataOffset + srcY * rowSize

            for x in 0..<width {
                let dstIndex = (y * width + x) * 4
                var pixel: UInt32 = 0

                switch bitsPerPixel {
                case 16:
                    let byteIndex = rowOffset + x * 2
                    guard byteIndex + 1 < dataCount else { continue }
                    pixel = UInt32(ptr[byteIndex]) | (UInt32(ptr[byteIndex + 1]) << 8)

                case 32:
                    let byteIndex = rowOffset + x * 4
                    guard byteIndex + 3 < dataCount else { continue }
                    pixel = readUInt32LE(ptr, offset: byteIndex)

                default:
                    continue
                }

                let r = extractComponent(pixel, mask: redMask, shift: redShift, bits: redBits)
                let g = extractComponent(pixel, mask: greenMask, shift: greenShift, bits: greenBits)
                let b = extractComponent(pixel, mask: blueMask, shift: blueShift, bits: blueBits)
                let a = alphaMask != 0 ? extractComponent(pixel, mask: alphaMask, shift: alphaShift, bits: alphaBits) : 255

                pixels[dstIndex] = r
                pixels[dstIndex + 1] = g
                pixels[dstIndex + 2] = b
                pixels[dstIndex + 3] = a
            }
        }

        return (pixels, hasAlpha)
    }

    // MARK: - Helper Functions

    private static func readUInt16LE(_ ptr: UnsafePointer<UInt8>, offset: Int) -> UInt16 {
        return UInt16(ptr[offset]) | (UInt16(ptr[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ ptr: UnsafePointer<UInt8>, offset: Int) -> UInt32 {
        return UInt32(ptr[offset]) |
               (UInt32(ptr[offset + 1]) << 8) |
               (UInt32(ptr[offset + 2]) << 16) |
               (UInt32(ptr[offset + 3]) << 24)
    }

    private static func readInt32LE(_ ptr: UnsafePointer<UInt8>, offset: Int) -> Int32 {
        return Int32(bitPattern: readUInt32LE(ptr, offset: offset))
    }

    private static func trailingZeroBitCount(_ value: UInt32) -> Int {
        guard value != 0 else { return 32 }
        var v = value
        var count = 0
        while (v & 1) == 0 {
            v >>= 1
            count += 1
        }
        return count
    }

    private static func bitCount(_ value: UInt32) -> Int {
        var v = value
        var count = 0
        while v != 0 {
            count += Int(v & 1)
            v >>= 1
        }
        return count
    }

    private static func extractComponent(_ pixel: UInt32, mask: UInt32, shift: Int, bits: Int) -> UInt8 {
        guard mask != 0 && bits > 0 else { return 0 }
        let value = (pixel & mask) >> shift
        // Scale to 8 bits
        let maxValue = (1 << bits) - 1
        return UInt8(value * 255 / UInt32(maxValue))
    }
}
