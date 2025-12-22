// WebPEncoder.swift
// OpenImageIO
//
// WebP image format encoder with VP8L (lossless) and VP8 (lossy) support

import Foundation
import OpenCoreGraphics

/// WebP image encoder
internal struct WebPEncoder {

    // MARK: - Constants

    private static let RIFF_SIGNATURE: [UInt8] = [0x52, 0x49, 0x46, 0x46] // "RIFF"
    private static let WEBP_SIGNATURE: [UInt8] = [0x57, 0x45, 0x42, 0x50] // "WEBP"
    private static let VP8L_CHUNK: [UInt8] = [0x56, 0x50, 0x38, 0x4C]     // "VP8L"
    private static let VP8_CHUNK: [UInt8] = [0x56, 0x50, 0x38, 0x20]      // "VP8 "

    private static let VP8L_SIGNATURE: UInt8 = 0x2F

    // MARK: - Public API

    /// Encode CGImage to WebP data
    /// - Parameters:
    ///   - image: The image to encode
    ///   - options: Encoding options
    ///     - "lossless": Bool (default: true) - Use lossless VP8L encoding
    ///     - "quality": Double (0.0-1.0, default: 0.8) - Quality for lossy encoding
    /// - Returns: WebP data or nil if encoding fails
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        let lossless = (options?["lossless"] as? Bool) ?? true
        let quality = (options?["quality"] as? Double) ?? 0.8

        if lossless {
            return encodeVP8L(image: image)
        } else {
            return encodeVP8(image: image, quality: quality)
        }
    }

    // MARK: - VP8L Encoding (Lossless)

    private static func encodeVP8L(image: CGImage) -> Data? {
        let width = image.width
        let height = image.height

        guard width > 0 && height > 0 else { return nil }
        guard width <= 16384 && height <= 16384 else { return nil }

        // Get pixel data
        guard let pixelData = getARGBPixels(from: image) else { return nil }

        // Encode VP8L bitstream
        guard let vp8lData = VP8LBitstreamEncoder.encode(
            pixels: pixelData,
            width: width,
            height: height
        ) else {
            return nil
        }

        // Build WebP container
        return buildWebPContainer(chunkType: VP8L_CHUNK, chunkData: vp8lData)
    }

    // MARK: - VP8 Encoding (Lossy)

    private static func encodeVP8(image: CGImage, quality: Double) -> Data? {
        let width = image.width
        let height = image.height

        guard width > 0 && height > 0 else { return nil }
        guard width <= 16384 && height <= 16384 else { return nil }

        // Get pixel data
        guard let pixelData = getRGBPixels(from: image) else { return nil }

        // Encode VP8 bitstream
        guard let vp8Data = VP8BitstreamEncoder.encode(
            pixels: pixelData,
            width: width,
            height: height,
            quality: quality
        ) else {
            return nil
        }

        // Build WebP container
        return buildWebPContainer(chunkType: VP8_CHUNK, chunkData: vp8Data)
    }

    // MARK: - Container Building

    private static func buildWebPContainer(chunkType: [UInt8], chunkData: Data) -> Data {
        var output = Data()

        // RIFF header
        output.append(contentsOf: RIFF_SIGNATURE)

        // File size (will be updated later)
        let fileSize = UInt32(4 + 8 + chunkData.count) // WEBP + chunk header + chunk data
        output.append(contentsOf: uint32ToLE(fileSize))

        // WEBP signature
        output.append(contentsOf: WEBP_SIGNATURE)

        // Chunk header
        output.append(contentsOf: chunkType)
        output.append(contentsOf: uint32ToLE(UInt32(chunkData.count)))

        // Chunk data
        output.append(chunkData)

        // Pad to even size if needed
        if chunkData.count % 2 != 0 {
            output.append(0)
        }

        return output
    }

    // MARK: - Pixel Extraction

    private static func getARGBPixels(from image: CGImage) -> [UInt8]? {
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data else {
            return nil
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        // Detect alpha info
        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let isARGB = (alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst)
        let hasAlpha = (alphaInfo != CGImageAlphaInfo.none && alphaInfo != .noneSkipLast && alphaInfo != .noneSkipFirst)

        // Convert to ARGB format for VP8L
        var argb = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let srcIdx = y * bytesPerRow + x * bytesPerPixel
                let dstIdx = (y * width + x) * 4

                var a: UInt8 = 255, r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0

                if bytesPerPixel == 4 && srcIdx + 3 < data.count {
                    if isARGB {
                        a = hasAlpha ? data[srcIdx] : 255
                        r = data[srcIdx + 1]
                        g = data[srcIdx + 2]
                        b = data[srcIdx + 3]
                    } else {
                        r = data[srcIdx]
                        g = data[srcIdx + 1]
                        b = data[srcIdx + 2]
                        a = hasAlpha ? data[srcIdx + 3] : 255
                    }
                } else if bytesPerPixel == 3 && srcIdx + 2 < data.count {
                    r = data[srcIdx]
                    g = data[srcIdx + 1]
                    b = data[srcIdx + 2]
                } else if bytesPerPixel == 1 && srcIdx < data.count {
                    let gray = data[srcIdx]
                    r = gray
                    g = gray
                    b = gray
                }

                // Store as ARGB
                argb[dstIdx] = a
                argb[dstIdx + 1] = r
                argb[dstIdx + 2] = g
                argb[dstIdx + 3] = b
            }
        }

        return argb
    }

    private static func getRGBPixels(from image: CGImage) -> [UInt8]? {
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data else {
            return nil
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let isARGB = (alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst)

        var rgb = [UInt8](repeating: 0, count: width * height * 3)

        for y in 0..<height {
            for x in 0..<width {
                let srcIdx = y * bytesPerRow + x * bytesPerPixel
                let dstIdx = (y * width + x) * 3

                var r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0

                if bytesPerPixel == 4 && srcIdx + 3 < data.count {
                    if isARGB {
                        r = data[srcIdx + 1]
                        g = data[srcIdx + 2]
                        b = data[srcIdx + 3]
                    } else {
                        r = data[srcIdx]
                        g = data[srcIdx + 1]
                        b = data[srcIdx + 2]
                    }
                } else if bytesPerPixel == 3 && srcIdx + 2 < data.count {
                    r = data[srcIdx]
                    g = data[srcIdx + 1]
                    b = data[srcIdx + 2]
                } else if bytesPerPixel == 1 && srcIdx < data.count {
                    let gray = data[srcIdx]
                    r = gray
                    g = gray
                    b = gray
                }

                rgb[dstIdx] = r
                rgb[dstIdx + 1] = g
                rgb[dstIdx + 2] = b
            }
        }

        return rgb
    }

    // MARK: - Helpers

    private static func uint32ToLE(_ value: UInt32) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }
}

// MARK: - VP8L Bitstream Encoder

private struct VP8LBitstreamEncoder {

    /// Encode ARGB pixels to VP8L bitstream
    /// Uses a simplified format compatible with our decoder:
    /// - No transforms (for simplicity and compatibility)
    /// - No color cache
    /// - Raw 8-bit values for each pixel component (no Huffman encoding)
    static func encode(pixels: [UInt8], width: Int, height: Int) -> Data? {
        var writer = BitWriter()

        // VP8L signature
        writer.writeByte(0x2F)

        // Image size: 14 bits width-1, 14 bits height-1, 1 bit alpha, 3 bits version
        let widthMinusOne = UInt32(width - 1)
        let heightMinusOne = UInt32(height - 1)
        let hasAlpha: UInt32 = checkAlpha(pixels: pixels) ? 1 : 0
        let version: UInt32 = 0

        let sizeBits = widthMinusOne |
                      (heightMinusOne << 14) |
                      (hasAlpha << 28) |
                      (version << 29)

        writer.writeBits(value: Int(sizeBits), count: 32)

        // No transforms - write 0 to indicate no more transforms
        writer.writeBit(0)

        // No color cache
        writer.writeBit(0)

        // Write raw pixel data without Huffman encoding
        // The decoder expects: green (8 bits), red (8 bits), blue (8 bits), alpha (8 bits)
        // Input pixels are in ARGB format: [A, R, G, B, A, R, G, B, ...]
        let totalPixels = width * height
        for i in 0..<totalPixels {
            let idx = i * 4
            let a = Int(pixels[idx])     // Alpha
            let r = Int(pixels[idx + 1]) // Red
            let g = Int(pixels[idx + 2]) // Green
            let b = Int(pixels[idx + 3]) // Blue

            // Write in the order decoder expects: G, R, B, A
            writer.writeBits(value: g, count: 8)
            writer.writeBits(value: r, count: 8)
            writer.writeBits(value: b, count: 8)
            writer.writeBits(value: a, count: 8)
        }

        return Data(writer.bytes)
    }

    private static func checkAlpha(pixels: [UInt8]) -> Bool {
        for i in stride(from: 0, to: pixels.count, by: 4) {
            if pixels[i] != 255 { // Alpha is at position 0 in ARGB
                return true
            }
        }
        return false
    }

    private static func applySubtractGreen(pixels: [UInt8]) -> [UInt8] {
        var result = pixels
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let g = Int(pixels[i + 2]) // G is at position 2 in ARGB
            result[i + 1] = UInt8((Int(pixels[i + 1]) - g) & 0xFF) // R -= G
            result[i + 3] = UInt8((Int(pixels[i + 3]) - g) & 0xFF) // B -= G
        }
        return result
    }

    private static func encodeImageData(
        pixels: [UInt8],
        width: Int,
        height: Int,
        colorCacheBits: Int,
        writer: inout BitWriter
    ) {
        let totalPixels = width * height
        let colorCacheSize = colorCacheBits > 0 ? (1 << colorCacheBits) : 0
        var colorCache = [UInt32](repeating: 0, count: colorCacheSize)

        // Build histogram for Huffman coding
        var greenHistogram = [Int](repeating: 0, count: 256 + 24 + colorCacheSize)
        var redHistogram = [Int](repeating: 0, count: 256)
        var blueHistogram = [Int](repeating: 0, count: 256)
        var alphaHistogram = [Int](repeating: 0, count: 256)
        var distHistogram = [Int](repeating: 0, count: 40)

        // First pass: build histograms and find LZ77 matches
        var matches: [(index: Int, length: Int, distance: Int)] = []
        let lz77WindowSize = min(totalPixels, 1 << 15)

        for i in 0..<totalPixels {
            let idx = i * 4
            let a = pixels[idx]
            let r = pixels[idx + 1]
            let g = pixels[idx + 2]
            let b = pixels[idx + 3]

            // Try to find LZ77 match
            var bestLength = 0
            var bestDistance = 0

            if i > 0 {
                let searchStart = max(0, i - lz77WindowSize)
                for j in stride(from: i - 1, through: searchStart, by: -1) {
                    var length = 0
                    while i + length < totalPixels && length < 4096 {
                        let srcIdx = j + (length % (i - j))
                        let dstIdx = i + length
                        if srcIdx * 4 + 3 < pixels.count && dstIdx * 4 + 3 < pixels.count {
                            if pixels[srcIdx * 4] == pixels[dstIdx * 4] &&
                               pixels[srcIdx * 4 + 1] == pixels[dstIdx * 4 + 1] &&
                               pixels[srcIdx * 4 + 2] == pixels[dstIdx * 4 + 2] &&
                               pixels[srcIdx * 4 + 3] == pixels[dstIdx * 4 + 3] {
                                length += 1
                            } else {
                                break
                            }
                        } else {
                            break
                        }
                    }

                    if length > bestLength && length >= 3 {
                        bestLength = length
                        bestDistance = i - j
                    }
                }
            }

            if bestLength >= 3 {
                matches.append((index: i, length: bestLength, distance: bestDistance))
                let lengthCode = encodeLZ77Length(bestLength)
                greenHistogram[256 + lengthCode] += 1
                distHistogram[min(encodeDistance(bestDistance), 39)] += 1
            } else {
                greenHistogram[Int(g)] += 1
                redHistogram[Int(r)] += 1
                blueHistogram[Int(b)] += 1
                alphaHistogram[Int(a)] += 1
            }
        }

        // Build Huffman codes
        let greenCodes = buildHuffmanCodes(histogram: greenHistogram)
        let redCodes = buildHuffmanCodes(histogram: redHistogram)
        let blueCodes = buildHuffmanCodes(histogram: blueHistogram)
        let alphaCodes = buildHuffmanCodes(histogram: alphaHistogram)
        let distCodes = buildHuffmanCodes(histogram: distHistogram)

        // Write Huffman code info (using simple code method)
        writeHuffmanCodeInfo(codes: greenCodes, maxSymbol: greenHistogram.count, writer: &writer)
        writeHuffmanCodeInfo(codes: redCodes, maxSymbol: 256, writer: &writer)
        writeHuffmanCodeInfo(codes: blueCodes, maxSymbol: 256, writer: &writer)
        writeHuffmanCodeInfo(codes: alphaCodes, maxSymbol: 256, writer: &writer)
        writeHuffmanCodeInfo(codes: distCodes, maxSymbol: 40, writer: &writer)

        // Second pass: encode pixels
        var matchIndex = 0
        var i = 0

        while i < totalPixels {
            // Check if we have a match at this position
            if matchIndex < matches.count && matches[matchIndex].index == i {
                let match = matches[matchIndex]

                // Write length code
                let lengthCode = encodeLZ77Length(match.length)
                let lengthSymbol = 256 + lengthCode
                writeHuffmanSymbol(symbol: lengthSymbol, codes: greenCodes, writer: &writer)

                // Write extra length bits if needed
                let lengthExtra = getLZ77LengthExtra(match.length, code: lengthCode)
                if lengthExtra.bits > 0 {
                    writer.writeBits(value: lengthExtra.value, count: lengthExtra.bits)
                }

                // Write distance code
                let distCode = encodeDistance(match.distance)
                writeHuffmanSymbol(symbol: distCode, codes: distCodes, writer: &writer)

                // Write extra distance bits if needed
                let distExtra = getDistanceExtra(match.distance, code: distCode)
                if distExtra.bits > 0 {
                    writer.writeBits(value: distExtra.value, count: distExtra.bits)
                }

                i += match.length
                matchIndex += 1
            } else {
                // Write literal pixel
                let idx = i * 4
                let a = Int(pixels[idx])
                let r = Int(pixels[idx + 1])
                let g = Int(pixels[idx + 2])
                let b = Int(pixels[idx + 3])

                // Check color cache
                var usedCache = false
                if colorCacheSize > 0 {
                    let argb = UInt32(a) << 24 | UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b)
                    let hashKey = colorCacheHash(argb, cacheBits: colorCacheBits)

                    if colorCache[hashKey] == argb && i > 0 {
                        // Use color cache reference
                        let cacheSymbol = 256 + 24 + hashKey
                        if cacheSymbol < greenCodes.count {
                            writeHuffmanSymbol(symbol: cacheSymbol, codes: greenCodes, writer: &writer)
                            usedCache = true
                        }
                    }

                    // Update cache
                    colorCache[hashKey] = argb
                }

                if !usedCache {
                    // Write literal ARGB
                    writeHuffmanSymbol(symbol: g, codes: greenCodes, writer: &writer)
                    writeHuffmanSymbol(symbol: r, codes: redCodes, writer: &writer)
                    writeHuffmanSymbol(symbol: b, codes: blueCodes, writer: &writer)
                    writeHuffmanSymbol(symbol: a, codes: alphaCodes, writer: &writer)
                }

                i += 1
            }
        }
    }

    // MARK: - LZ77 Encoding

    private static func encodeLZ77Length(_ length: Int) -> Int {
        // VP8L length code table
        if length <= 1 { return 0 }
        if length <= 2 { return 1 }
        if length <= 3 { return 2 }
        if length <= 4 { return 3 }
        if length <= 5 { return 4 }
        if length <= 6 { return 5 }
        if length <= 7 { return 6 }
        if length <= 8 { return 7 }
        if length <= 10 { return 8 }
        if length <= 12 { return 9 }
        if length <= 14 { return 10 }
        if length <= 18 { return 11 }
        if length <= 22 { return 12 }
        if length <= 30 { return 13 }
        if length <= 38 { return 14 }
        if length <= 54 { return 15 }
        if length <= 70 { return 16 }
        if length <= 102 { return 17 }
        if length <= 134 { return 18 }
        if length <= 198 { return 19 }
        if length <= 262 { return 20 }
        if length <= 390 { return 21 }
        if length <= 518 { return 22 }
        return 23
    }

    private static func getLZ77LengthExtra(_ length: Int, code: Int) -> (value: Int, bits: Int) {
        let baseLengths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 13, 15, 19, 23, 31, 39, 55, 71, 103, 135, 199, 263, 391, 519]
        let extraBits = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8]

        if code < baseLengths.count {
            let bits = extraBits[code]
            let base = baseLengths[code]
            return (value: length - base, bits: bits)
        }
        return (value: 0, bits: 0)
    }

    private static func encodeDistance(_ distance: Int) -> Int {
        if distance <= 1 { return 0 }
        if distance <= 2 { return 1 }
        if distance <= 3 { return 2 }
        if distance <= 4 { return 3 }

        var code = 2
        var d = distance - 1
        while d > 1 {
            d >>= 1
            code += 2
        }
        return min(code + ((distance - 1) >> (code / 2 - 1)) & 1, 39)
    }

    private static func getDistanceExtra(_ distance: Int, code: Int) -> (value: Int, bits: Int) {
        if code < 4 {
            return (value: 0, bits: 0)
        }
        let extraBits = (code - 2) >> 1
        let base = (2 + (code & 1)) << extraBits
        return (value: distance - base - 1, bits: extraBits)
    }

    private static func colorCacheHash(_ argb: UInt32, cacheBits: Int) -> Int {
        return Int((argb &* 0x1e35a7bd) >> (32 - cacheBits))
    }

    // MARK: - Huffman Coding

    private struct HuffmanCode {
        let code: Int
        let length: Int
    }

    private static func buildHuffmanCodes(histogram: [Int]) -> [HuffmanCode] {
        var codes = [HuffmanCode](repeating: HuffmanCode(code: 0, length: 0), count: histogram.count)

        // Find non-zero symbols
        var symbols: [(symbol: Int, count: Int)] = []
        for (i, count) in histogram.enumerated() {
            if count > 0 {
                symbols.append((symbol: i, count: count))
            }
        }

        if symbols.isEmpty {
            return codes
        }

        if symbols.count == 1 {
            // Single symbol: use code 0 with length 1
            codes[symbols[0].symbol] = HuffmanCode(code: 0, length: 1)
            return codes
        }

        // Sort by count (descending) for canonical Huffman
        symbols.sort { $0.count > $1.count }

        // Build canonical Huffman codes
        // Use simple approach: assign lengths based on rank
        let maxLength = min(15, symbols.count)

        for (rank, item) in symbols.enumerated() {
            let length = min(max(1, rank / 2 + 1), maxLength)
            codes[item.symbol] = HuffmanCode(code: 0, length: length)
        }

        // Assign canonical codes
        var code = 0
        var prevLength = 0

        // Sort by length, then by symbol
        var sortedSymbols = symbols.map { ($0.symbol, codes[$0.symbol].length) }
        sortedSymbols.sort { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0 < $1.0) }

        for (symbol, length) in sortedSymbols {
            if length > prevLength {
                code <<= (length - prevLength)
                prevLength = length
            }
            codes[symbol] = HuffmanCode(code: code, length: length)
            code += 1
        }

        return codes
    }

    private static func writeHuffmanCodeInfo(codes: [HuffmanCode], maxSymbol: Int, writer: inout BitWriter) {
        // Count non-zero code lengths
        var nonZeroCount = 0
        for code in codes {
            if code.length > 0 {
                nonZeroCount += 1
            }
        }

        if nonZeroCount == 0 {
            // No codes - write simple marker
            writer.writeBit(1) // Simple code
            writer.writeBit(0) // 1 symbol
            writer.writeBit(1) // 8 bits for symbol
            writer.writeBits(value: 0, count: 8)
            return
        }

        if nonZeroCount == 1 {
            // Single symbol
            writer.writeBit(1) // Simple code
            writer.writeBit(0) // 1 symbol
            let symbol = codes.firstIndex { $0.length > 0 } ?? 0
            if symbol < 256 {
                writer.writeBit(1) // 8 bits
                writer.writeBits(value: symbol, count: 8)
            } else {
                writer.writeBit(0) // Large symbol
                writer.writeBits(value: symbol, count: 16)
            }
            return
        }

        if nonZeroCount == 2 {
            // Two symbols
            writer.writeBit(1) // Simple code
            writer.writeBit(1) // 2 symbols
            var symbols: [Int] = []
            for (i, code) in codes.enumerated() {
                if code.length > 0 {
                    symbols.append(i)
                }
            }
            writer.writeBit(symbols[0] < 256 ? 1 : 0)
            writer.writeBits(value: symbols[0], count: symbols[0] < 256 ? 8 : 16)
            writer.writeBits(value: symbols[1], count: 8)
            return
        }

        // Normal Huffman code
        writer.writeBit(0) // Normal code

        // Write code lengths using another Huffman code
        // For simplicity, use run-length encoded code lengths
        var codeLengths: [Int] = []
        for i in 0..<maxSymbol {
            codeLengths.append(i < codes.count ? codes[i].length : 0)
        }

        // Count code length histogram
        var lengthHist = [Int](repeating: 0, count: 19)
        for len in codeLengths {
            lengthHist[min(len, 18)] += 1
        }

        // Write number of code length codes
        let numCodeLengthCodes = 18
        writer.writeBits(value: numCodeLengthCodes - 4, count: 4)

        // Write code length code lengths (fixed order: 17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
        for _ in 0..<numCodeLengthCodes {
            writer.writeBits(value: 3, count: 3) // Fixed length of 3
        }

        // Write actual code lengths
        for len in codeLengths {
            writer.writeBits(value: len, count: 3)
        }
    }

    private static func writeHuffmanSymbol(symbol: Int, codes: [HuffmanCode], writer: inout BitWriter) {
        guard symbol < codes.count else {
            // Fallback: write raw bits
            writer.writeBits(value: symbol, count: 8)
            return
        }

        let code = codes[symbol]
        if code.length > 0 {
            writer.writeBits(value: code.code, count: code.length)
        } else {
            // No code assigned - write raw
            writer.writeBits(value: symbol, count: 8)
        }
    }
}

// MARK: - VP8 Bitstream Encoder (Lossy)

private struct VP8BitstreamEncoder {

    // Quantization tables
    private static let dcQLookup: [Int] = [
        4, 5, 6, 7, 8, 9, 10, 10, 11, 12, 13, 14, 15, 16, 17, 17,
        18, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 25, 25, 26, 27, 28,
        29, 30, 31, 32, 33, 34, 35, 36, 37, 37, 38, 39, 40, 41, 42, 43,
        44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58,
        59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
        75, 76, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
        91, 93, 95, 96, 98, 100, 101, 102, 104, 106, 108, 110, 112, 114, 116, 118,
        122, 124, 126, 128, 130, 132, 134, 136, 138, 140, 143, 145, 148, 151, 154, 157
    ]

    private static let acQLookup: [Int] = [
        4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76,
        78, 80, 82, 84, 86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108,
        110, 112, 114, 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152,
        155, 158, 161, 164, 167, 170, 173, 177, 181, 185, 189, 193, 197, 201, 205, 209,
        213, 217, 221, 225, 229, 234, 239, 245, 249, 254, 259, 264, 269, 274, 279, 284
    ]

    private static let zigzag: [Int] = [
        0, 1, 4, 8, 5, 2, 3, 6, 9, 12, 13, 10, 7, 11, 14, 15
    ]

    /// Encode RGB pixels to VP8 bitstream
    static func encode(pixels: [UInt8], width: Int, height: Int, quality: Double) -> Data? {
        // Convert RGB to YUV
        let yuv = rgbToYUV(pixels: pixels, width: width, height: height)

        // Calculate quantization index from quality
        let qIndex = max(0, min(127, Int((1.0 - quality) * 127)))
        let dcQ = dcQLookup[qIndex]
        let acQ = acQLookup[qIndex]

        // Pad dimensions to multiple of 16 for macroblocks
        let mbWidth = (width + 15) / 16
        let mbHeight = (height + 15) / 16

        var writer = BoolWriter()

        // Build frame header
        var frameData = Data()

        // Frame tag (3 bytes)
        // Bit 0: keyframe (0)
        // Bits 1-3: version (0)
        // Bit 4: show frame (1)
        // Bits 5-23: first partition size (will be set later)
        frameData.append(contentsOf: [0x10, 0x00, 0x00]) // Placeholder, will update

        // Keyframe header
        frameData.append(0x9D) // Start code
        frameData.append(0x01)
        frameData.append(0x2A)

        // Width and height (little-endian)
        frameData.append(UInt8(width & 0xFF))
        frameData.append(UInt8((width >> 8) & 0x3F))
        frameData.append(UInt8(height & 0xFF))
        frameData.append(UInt8((height >> 8) & 0x3F))

        // Initialize boolean encoder
        writer.init_()

        // Write frame header
        writer.writeBool(prob: 128, value: 0) // Color space (YUV)
        writer.writeBool(prob: 128, value: 0) // Clamping type

        // Segmentation
        writer.writeBool(prob: 128, value: 0) // No segmentation

        // Filter parameters
        writer.writeBool(prob: 128, value: 0) // Filter type (normal)
        writer.writeLiteral(bits: 6, value: 0) // Filter level
        writer.writeLiteral(bits: 3, value: 0) // Sharpness

        // Loop filter adjustments
        writer.writeBool(prob: 128, value: 0) // No adjustments

        // Partitions
        writer.writeLiteral(bits: 2, value: 0) // 1 partition

        // Quantization
        writer.writeLiteral(bits: 7, value: qIndex)
        writer.writeBool(prob: 128, value: 0) // No Y DC delta
        writer.writeBool(prob: 128, value: 0) // No Y2 DC delta
        writer.writeBool(prob: 128, value: 0) // No Y2 AC delta
        writer.writeBool(prob: 128, value: 0) // No UV DC delta
        writer.writeBool(prob: 128, value: 0) // No UV AC delta

        // Refresh entropy probs
        writer.writeBool(prob: 128, value: 0)

        // Coefficient probability updates (none)
        for _ in 0..<(4 * 8 * 3 * 11) {
            writer.writeBool(prob: 255, value: 0)
        }

        // MB no coeff skip
        writer.writeLiteral(bits: 8, value: 0)

        // Encode macroblocks
        var prevDCY: Int = 0
        var prevDCCb: Int = 0
        var prevDCCr: Int = 0

        for mbY in 0..<mbHeight {
            for mbX in 0..<mbWidth {
                // Encode macroblock
                encodeMacroblock(
                    mbX: mbX,
                    mbY: mbY,
                    yuv: yuv,
                    width: width,
                    height: height,
                    dcQ: dcQ,
                    acQ: acQ,
                    prevDCY: &prevDCY,
                    prevDCCb: &prevDCCb,
                    prevDCCr: &prevDCCr,
                    writer: &writer
                )
            }
        }

        // Flush boolean encoder
        let partitionData = writer.flush()

        // Update frame tag with partition size
        let partitionSize = partitionData.count
        frameData[0] = UInt8((partitionSize << 5) & 0xE0) | 0x10 // keyframe + show
        frameData[1] = UInt8((partitionSize >> 3) & 0xFF)
        frameData[2] = UInt8((partitionSize >> 11) & 0xFF)

        // Combine frame header and partition data
        frameData.append(contentsOf: partitionData)

        return frameData
    }

    private static func rgbToYUV(pixels: [UInt8], width: Int, height: Int) -> (y: [UInt8], u: [UInt8], v: [UInt8]) {
        let ySize = width * height
        let uvWidth = (width + 1) / 2
        let uvHeight = (height + 1) / 2
        let uvSize = uvWidth * uvHeight

        var y = [UInt8](repeating: 128, count: ySize)
        var u = [UInt8](repeating: 128, count: uvSize)
        var v = [UInt8](repeating: 128, count: uvSize)

        for py in 0..<height {
            for px in 0..<width {
                let srcIdx = (py * width + px) * 3
                let r = Int(pixels[srcIdx])
                let g = Int(pixels[srcIdx + 1])
                let b = Int(pixels[srcIdx + 2])

                // BT.601 conversion
                let yVal = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16
                y[py * width + px] = UInt8(clamping: max(0, min(255, yVal)))

                // Subsample U and V
                if px % 2 == 0 && py % 2 == 0 {
                    let uvIdx = (py / 2) * uvWidth + (px / 2)
                    let uVal = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128
                    let vVal = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128
                    u[uvIdx] = UInt8(clamping: max(0, min(255, uVal)))
                    v[uvIdx] = UInt8(clamping: max(0, min(255, vVal)))
                }
            }
        }

        return (y, u, v)
    }

    private static func encodeMacroblock(
        mbX: Int,
        mbY: Int,
        yuv: (y: [UInt8], u: [UInt8], v: [UInt8]),
        width: Int,
        height: Int,
        dcQ: Int,
        acQ: Int,
        prevDCY: inout Int,
        prevDCCb: inout Int,
        prevDCCr: inout Int,
        writer: inout BoolWriter
    ) {
        // MB skip coefficient flag
        writer.writeBool(prob: 128, value: 0) // Don't skip

        // Intra prediction mode (DC_PRED = 0)
        writer.writeBool(prob: 145, value: 0) // DC_PRED for Y

        // UV prediction mode
        writer.writeBool(prob: 142, value: 0) // DC_PRED for UV

        // Encode Y blocks (16 4x4 blocks)
        let baseX = mbX * 16
        let baseY = mbY * 16

        // Y2 DC block (WHT of 16 Y DC values)
        var y2Block = [Int](repeating: 0, count: 16)

        for sbY in 0..<4 {
            for sbX in 0..<4 {
                let sbIdx = sbY * 4 + sbX

                // Get 4x4 block
                var block = [Int](repeating: 0, count: 16)
                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = baseX + sbX * 4 + x
                        let py = baseY + sbY * 4 + y
                        if px < width && py < height {
                            block[y * 4 + x] = Int(yuv.y[py * width + px]) - 128
                        }
                    }
                }

                // Forward DCT
                let dct = forwardDCT4x4(block: block)

                // Store DC for Y2
                y2Block[sbIdx] = dct[0]

                // Quantize and encode AC coefficients
                var quantized = [Int](repeating: 0, count: 16)
                for i in 1..<16 {
                    quantized[zigzag[i]] = dct[i] / acQ
                }

                // Write coefficients
                encodeCoefficients(coeffs: quantized, dcCoeff: 0, type: 0, writer: &writer)
            }
        }

        // Encode Y2 block (WHT)
        let y2WHT = forwardWHT4x4(block: y2Block)
        var y2Quantized = [Int](repeating: 0, count: 16)
        for i in 0..<16 {
            y2Quantized[i] = y2WHT[i] / dcQ
        }

        let y2DC = y2Quantized[0] - prevDCY
        prevDCY = y2Quantized[0]
        encodeCoefficients(coeffs: y2Quantized, dcCoeff: y2DC, type: 1, writer: &writer)

        // Encode U blocks (4 4x4 blocks)
        let uvWidth = (width + 1) / 2
        let uvBaseX = mbX * 8
        let uvBaseY = mbY * 8

        for sbY in 0..<2 {
            for sbX in 0..<2 {
                var block = [Int](repeating: 0, count: 16)
                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = uvBaseX + sbX * 4 + x
                        let py = uvBaseY + sbY * 4 + y
                        if px < uvWidth && py < (height + 1) / 2 {
                            block[y * 4 + x] = Int(yuv.u[py * uvWidth + px]) - 128
                        }
                    }
                }

                let dct = forwardDCT4x4(block: block)
                var quantized = [Int](repeating: 0, count: 16)
                quantized[0] = dct[0] / dcQ - prevDCCb
                prevDCCb = dct[0] / dcQ
                for i in 1..<16 {
                    quantized[zigzag[i]] = dct[i] / acQ
                }
                encodeCoefficients(coeffs: quantized, dcCoeff: quantized[0], type: 2, writer: &writer)
            }
        }

        // Encode V blocks (4 4x4 blocks)
        for sbY in 0..<2 {
            for sbX in 0..<2 {
                var block = [Int](repeating: 0, count: 16)
                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = uvBaseX + sbX * 4 + x
                        let py = uvBaseY + sbY * 4 + y
                        if px < uvWidth && py < (height + 1) / 2 {
                            block[y * 4 + x] = Int(yuv.v[py * uvWidth + px]) - 128
                        }
                    }
                }

                let dct = forwardDCT4x4(block: block)
                var quantized = [Int](repeating: 0, count: 16)
                quantized[0] = dct[0] / dcQ - prevDCCr
                prevDCCr = dct[0] / dcQ
                for i in 1..<16 {
                    quantized[zigzag[i]] = dct[i] / acQ
                }
                encodeCoefficients(coeffs: quantized, dcCoeff: quantized[0], type: 2, writer: &writer)
            }
        }
    }

    private static func forwardDCT4x4(block: [Int]) -> [Int] {
        var out = [Int](repeating: 0, count: 16)
        var tmp = [Int](repeating: 0, count: 16)

        // Horizontal pass
        for i in 0..<4 {
            let a0 = block[i * 4] + block[i * 4 + 3]
            let a1 = block[i * 4 + 1] + block[i * 4 + 2]
            let a2 = block[i * 4 + 1] - block[i * 4 + 2]
            let a3 = block[i * 4] - block[i * 4 + 3]

            tmp[i * 4] = a0 + a1
            tmp[i * 4 + 2] = a0 - a1
            tmp[i * 4 + 1] = (a2 * 2217 + a3 * 5352 + 14500) >> 12
            tmp[i * 4 + 3] = (a3 * 2217 - a2 * 5352 + 7500) >> 12
        }

        // Vertical pass
        for i in 0..<4 {
            let a0 = tmp[i] + tmp[12 + i]
            let a1 = tmp[4 + i] + tmp[8 + i]
            let a2 = tmp[4 + i] - tmp[8 + i]
            let a3 = tmp[i] - tmp[12 + i]

            out[i] = (a0 + a1 + 7) >> 4
            out[8 + i] = (a0 - a1 + 7) >> 4
            out[4 + i] = ((a2 * 2217 + a3 * 5352 + 12000) >> 16) + (a3 != 0 ? 1 : 0)
            out[12 + i] = (a3 * 2217 - a2 * 5352 + 51000) >> 16
        }

        return out
    }

    private static func forwardWHT4x4(block: [Int]) -> [Int] {
        var out = [Int](repeating: 0, count: 16)
        var tmp = [Int](repeating: 0, count: 16)

        // Horizontal pass
        for i in 0..<4 {
            let a0 = block[i * 4] + block[i * 4 + 2]
            let a1 = block[i * 4] - block[i * 4 + 2]
            let a2 = block[i * 4 + 1] - block[i * 4 + 3]
            let a3 = block[i * 4 + 1] + block[i * 4 + 3]

            tmp[i * 4] = a0 + a3
            tmp[i * 4 + 1] = a1 + a2
            tmp[i * 4 + 2] = a1 - a2
            tmp[i * 4 + 3] = a0 - a3
        }

        // Vertical pass
        for i in 0..<4 {
            let a0 = tmp[i] + tmp[8 + i]
            let a1 = tmp[i] - tmp[8 + i]
            let a2 = tmp[4 + i] - tmp[12 + i]
            let a3 = tmp[4 + i] + tmp[12 + i]

            out[i] = (a0 + a3) >> 1
            out[4 + i] = (a1 + a2) >> 1
            out[8 + i] = (a1 - a2) >> 1
            out[12 + i] = (a0 - a3) >> 1
        }

        return out
    }

    private static func encodeCoefficients(coeffs: [Int], dcCoeff: Int, type: Int, writer: inout BoolWriter) {
        // Encode using VP8 coefficient coding
        var hasNonZero = false
        for i in 0..<16 {
            if coeffs[i] != 0 {
                hasNonZero = true
                break
            }
        }

        if !hasNonZero {
            // All zeros - write EOB
            writer.writeBool(prob: 128, value: 0)
            return
        }

        // Write coefficients
        for i in 0..<16 {
            let coeff = i == 0 ? dcCoeff : coeffs[i]

            if coeff == 0 {
                writer.writeBool(prob: 128, value: 0) // Zero
            } else {
                writer.writeBool(prob: 128, value: 1) // Non-zero
                let absCoeff = abs(coeff)

                if absCoeff == 1 {
                    writer.writeBool(prob: 128, value: 0) // Value is 1
                } else {
                    writer.writeBool(prob: 128, value: 1) // Value > 1
                    // Write token for larger values
                    if absCoeff <= 4 {
                        writer.writeBool(prob: 128, value: 0)
                        writer.writeLiteral(bits: 2, value: absCoeff - 2)
                    } else {
                        writer.writeBool(prob: 128, value: 1)
                        writer.writeLiteral(bits: 8, value: min(absCoeff, 255))
                    }
                }

                // Write sign
                writer.writeBool(prob: 128, value: coeff < 0 ? 1 : 0)
            }
        }
    }
}

// MARK: - Bit Writer

private struct BitWriter {
    var bytes: [UInt8] = []
    private var currentByte: UInt8 = 0
    private var bitPosition: Int = 0

    mutating func writeBit(_ bit: Int) {
        currentByte |= UInt8((bit & 1) << bitPosition)
        bitPosition += 1

        if bitPosition == 8 {
            bytes.append(currentByte)
            currentByte = 0
            bitPosition = 0
        }
    }

    mutating func writeBits(value: Int, count: Int) {
        for i in 0..<count {
            writeBit((value >> i) & 1)
        }
    }

    mutating func writeByte(_ byte: UInt8) {
        if bitPosition == 0 {
            bytes.append(byte)
        } else {
            // Write bits
            for i in 0..<8 {
                writeBit(Int((byte >> i) & 1))
            }
        }
    }

    mutating func flush() {
        if bitPosition > 0 {
            bytes.append(currentByte)
            currentByte = 0
            bitPosition = 0
        }
    }
}

// MARK: - Boolean Writer (VP8 Range Coder)

private struct BoolWriter {
    private var range: UInt32 = 255
    private var bottom: UInt32 = 0
    private var bitCount: Int = 24
    private var bytes: [UInt8] = []

    mutating func init_() {
        range = 255
        bottom = 0
        bitCount = 24
        bytes = []
    }

    mutating func writeBool(prob: UInt8, value: Int) {
        let split = 1 + (((range - 1) * UInt32(prob)) >> 8)

        if value != 0 {
            bottom += split
            range -= split
        } else {
            range = split
        }

        // Renormalize
        while range < 128 {
            range <<= 1
            if bottom & (1 << 31) != 0 {
                carryPropagation()
            }
            bottom <<= 1
            bitCount -= 1

            if bitCount == 16 {
                bytes.append(UInt8((bottom >> 24) & 0xFF))
                bottom &= 0x00FFFFFF
                bitCount = 24
            }
        }
    }

    mutating func writeLiteral(bits: Int, value: Int) {
        for i in stride(from: bits - 1, through: 0, by: -1) {
            writeBool(prob: 128, value: (value >> i) & 1)
        }
    }

    private mutating func carryPropagation() {
        var i = bytes.count - 1
        while i >= 0 && bytes[i] == 0xFF {
            bytes[i] = 0
            i -= 1
        }
        if i >= 0 {
            bytes[i] += 1
        }
    }

    mutating func flush() -> [UInt8] {
        // Flush remaining bits
        for _ in 0..<32 {
            writeBool(prob: 128, value: 0)
        }
        return bytes
    }
}
