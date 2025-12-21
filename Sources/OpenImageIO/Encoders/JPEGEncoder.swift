// JPEGEncoder.swift
// OpenImageIO
//
// Full JPEG encoder with DCT, quantization, and Huffman coding

import Foundation

/// JPEG image encoder with baseline DCT compression
internal struct JPEGEncoder {

    // MARK: - Constants

    /// Standard JPEG luminance quantization table
    private static let luminanceQuantTable: [Int] = [
        16, 11, 10, 16,  24,  40,  51,  61,
        12, 12, 14, 19,  26,  58,  60,  55,
        14, 13, 16, 24,  40,  57,  69,  56,
        14, 17, 22, 29,  51,  87,  80,  62,
        18, 22, 37, 56,  68, 109, 103,  77,
        24, 35, 55, 64,  81, 104, 113,  92,
        49, 64, 78, 87, 103, 121, 120, 101,
        72, 92, 95, 98, 112, 100, 103,  99
    ]

    /// Standard JPEG chrominance quantization table
    private static let chrominanceQuantTable: [Int] = [
        17, 18, 24, 47, 99, 99, 99, 99,
        18, 21, 26, 66, 99, 99, 99, 99,
        24, 26, 56, 99, 99, 99, 99, 99,
        47, 66, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99
    ]

    /// Zig-zag order for 8x8 block
    private static let zigzagOrder: [Int] = [
         0,  1,  8, 16,  9,  2,  3, 10,
        17, 24, 32, 25, 18, 11,  4,  5,
        12, 19, 26, 33, 40, 48, 41, 34,
        27, 20, 13,  6,  7, 14, 21, 28,
        35, 42, 49, 56, 57, 50, 43, 36,
        29, 22, 15, 23, 30, 37, 44, 51,
        58, 59, 52, 45, 38, 31, 39, 46,
        53, 60, 61, 54, 47, 55, 62, 63
    ]

    /// Standard DC luminance Huffman table
    private static let dcLuminanceHuffmanBits: [Int] = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0]
    private static let dcLuminanceHuffmanValues: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

    /// Standard DC chrominance Huffman table
    private static let dcChrominanceHuffmanBits: [Int] = [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
    private static let dcChrominanceHuffmanValues: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

    /// Standard AC luminance Huffman table
    private static let acLuminanceHuffmanBits: [Int] = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125]
    private static let acLuminanceHuffmanValues: [Int] = [
        0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
        0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
        0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
        0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0,
        0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0A, 0x16,
        0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
        0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
        0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
        0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
        0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
        0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
        0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
        0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
        0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
        0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
        0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5,
        0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2, 0xD3, 0xD4,
        0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
        0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA,
        0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
        0xF9, 0xFA
    ]

    /// Standard AC chrominance Huffman table
    private static let acChrominanceHuffmanBits: [Int] = [0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119]
    private static let acChrominanceHuffmanValues: [Int] = [
        0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
        0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
        0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
        0xA1, 0xB1, 0xC1, 0x09, 0x23, 0x33, 0x52, 0xF0,
        0x15, 0x62, 0x72, 0xD1, 0x0A, 0x16, 0x24, 0x34,
        0xE1, 0x25, 0xF1, 0x17, 0x18, 0x19, 0x1A, 0x26,
        0x27, 0x28, 0x29, 0x2A, 0x35, 0x36, 0x37, 0x38,
        0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
        0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
        0x59, 0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
        0x69, 0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
        0x79, 0x7A, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
        0x88, 0x89, 0x8A, 0x92, 0x93, 0x94, 0x95, 0x96,
        0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5,
        0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4,
        0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3,
        0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2,
        0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA,
        0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9,
        0xEA, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
        0xF9, 0xFA
    ]

    // MARK: - Huffman Code Table

    private struct HuffmanCode {
        let code: UInt16
        let length: Int
    }

    // MARK: - Public API

    /// Encode a CGImage to JPEG data
    /// - Parameters:
    ///   - image: The image to encode
    ///   - options: Encoding options (optional). Supports:
    ///     - `kCGImageDestinationLossyCompressionQuality`: Quality (0.0 to 1.0, default 0.8)
    /// - Returns: JPEG data or nil if encoding fails
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        let width = image.width
        let height = image.height

        guard width > 0 && height > 0 else { return nil }

        // Extract quality from options (default 0.8)
        let quality: Double
        if let q = options?[kCGImageDestinationLossyCompressionQuality] as? Double {
            quality = max(0.0, min(1.0, q))
        } else if let q = options?[kCGImageDestinationLossyCompressionQuality] as? Float {
            quality = Double(max(0.0, min(1.0, q)))
        } else if let q = options?[kCGImageDestinationLossyCompressionQuality] as? NSNumber {
            quality = max(0.0, min(1.0, q.doubleValue))
        } else {
            quality = 0.8
        }

        // Get pixel data
        guard let pixelData = getPixelData(from: image) else { return nil }

        // Convert RGB to YCbCr
        let ycbcr = rgbToYCbCr(pixels: pixelData, width: width, height: height)

        // Scale quantization tables based on quality
        let scaledLumQuant = scaleQuantTable(luminanceQuantTable, quality: quality)
        let scaledChromQuant = scaleQuantTable(chrominanceQuantTable, quality: quality)

        // Build Huffman code tables
        let dcLumCodes = buildHuffmanCodes(bits: dcLuminanceHuffmanBits, values: dcLuminanceHuffmanValues)
        let dcChromCodes = buildHuffmanCodes(bits: dcChrominanceHuffmanBits, values: dcChrominanceHuffmanValues)
        let acLumCodes = buildHuffmanCodes(bits: acLuminanceHuffmanBits, values: acLuminanceHuffmanValues)
        let acChromCodes = buildHuffmanCodes(bits: acChrominanceHuffmanBits, values: acChrominanceHuffmanValues)

        // Encode image data
        var bitWriter = BitWriter()

        // Pad dimensions to multiple of 8
        let paddedWidth = (width + 7) & ~7
        let paddedHeight = (height + 7) & ~7

        var prevDCY = 0
        var prevDCCb = 0
        var prevDCCr = 0

        // Process 8x8 blocks
        for by in stride(from: 0, to: paddedHeight, by: 8) {
            for bx in stride(from: 0, to: paddedWidth, by: 8) {
                // Extract Y block
                var yBlock = [Double](repeating: 0, count: 64)
                var cbBlock = [Double](repeating: 0, count: 64)
                var crBlock = [Double](repeating: 0, count: 64)

                for y in 0..<8 {
                    for x in 0..<8 {
                        let px = min(bx + x, width - 1)
                        let py = min(by + y, height - 1)
                        let idx = py * width + px

                        yBlock[y * 8 + x] = ycbcr.y[idx] - 128.0
                        cbBlock[y * 8 + x] = ycbcr.cb[idx] - 128.0
                        crBlock[y * 8 + x] = ycbcr.cr[idx] - 128.0
                    }
                }

                // DCT transform
                let dctY = forwardDCT(yBlock)
                let dctCb = forwardDCT(cbBlock)
                let dctCr = forwardDCT(crBlock)

                // Quantize
                let quantY = quantize(dctY, quantTable: scaledLumQuant)
                let quantCb = quantize(dctCb, quantTable: scaledChromQuant)
                let quantCr = quantize(dctCr, quantTable: scaledChromQuant)

                // Encode Y block
                prevDCY = encodeBlock(quantY, prevDC: prevDCY, dcCodes: dcLumCodes, acCodes: acLumCodes, writer: &bitWriter)

                // Encode Cb block
                prevDCCb = encodeBlock(quantCb, prevDC: prevDCCb, dcCodes: dcChromCodes, acCodes: acChromCodes, writer: &bitWriter)

                // Encode Cr block
                prevDCCr = encodeBlock(quantCr, prevDC: prevDCCr, dcCodes: dcChromCodes, acCodes: acChromCodes, writer: &bitWriter)
            }
        }

        // Flush remaining bits
        bitWriter.flush()

        // Build JPEG file
        return buildJPEGFile(
            width: width,
            height: height,
            lumQuant: scaledLumQuant,
            chromQuant: scaledChromQuant,
            imageData: bitWriter.bytes
        )
    }

    // MARK: - Pixel Data Extraction

    private static func getPixelData(from image: CGImage) -> [UInt8]? {
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data else {
            return nil
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        // Detect pixel format
        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let isARGB = (alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst)

        var pixels = [UInt8](repeating: 0, count: width * height * 3)

        for y in 0..<height {
            for x in 0..<width {
                let srcIdx = y * bytesPerRow + x * bytesPerPixel
                let dstIdx = (y * width + x) * 3

                // Extract RGB values based on source format
                var r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0

                if bytesPerPixel == 4 && srcIdx + 3 < data.count {
                    if isARGB {
                        // ARGB format
                        r = data[srcIdx + 1]
                        g = data[srcIdx + 2]
                        b = data[srcIdx + 3]
                    } else {
                        // RGBA format (default)
                        r = data[srcIdx]
                        g = data[srcIdx + 1]
                        b = data[srcIdx + 2]
                    }
                } else if bytesPerPixel == 3 && srcIdx + 2 < data.count {
                    // RGB format (no alpha)
                    r = data[srcIdx]
                    g = data[srcIdx + 1]
                    b = data[srcIdx + 2]
                } else if bytesPerPixel == 1 && srcIdx < data.count {
                    // Grayscale
                    let gray = data[srcIdx]
                    r = gray
                    g = gray
                    b = gray
                }

                pixels[dstIdx] = r
                pixels[dstIdx + 1] = g
                pixels[dstIdx + 2] = b
            }
        }

        return pixels
    }

    // MARK: - Color Space Conversion

    private struct YCbCrData {
        let y: [Double]
        let cb: [Double]
        let cr: [Double]
    }

    private static func rgbToYCbCr(pixels: [UInt8], width: Int, height: Int) -> YCbCrData {
        let count = width * height
        var y = [Double](repeating: 0, count: count)
        var cb = [Double](repeating: 0, count: count)
        var cr = [Double](repeating: 0, count: count)

        for i in 0..<count {
            let r = Double(pixels[i * 3])
            let g = Double(pixels[i * 3 + 1])
            let b = Double(pixels[i * 3 + 2])

            // ITU-R BT.601 conversion
            y[i] = 0.299 * r + 0.587 * g + 0.114 * b
            cb[i] = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b
            cr[i] = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b
        }

        return YCbCrData(y: y, cb: cb, cr: cr)
    }

    // MARK: - Quantization Table Scaling

    private static func scaleQuantTable(_ table: [Int], quality: Double) -> [Int] {
        let q = max(1, min(100, Int(quality * 100)))
        let scale: Int
        if q < 50 {
            scale = 5000 / q
        } else {
            scale = 200 - q * 2
        }

        return table.map { value in
            let scaled = (value * scale + 50) / 100
            return max(1, min(255, scaled))
        }
    }

    // MARK: - DCT Transform

    /// Forward DCT on 8x8 block
    private static func forwardDCT(_ block: [Double]) -> [Double] {
        var result = [Double](repeating: 0, count: 64)

        // Precompute cosine values
        let cosTable = (0..<8).map { u in
            (0..<8).map { x in
                cos((2.0 * Double(x) + 1.0) * Double(u) * .pi / 16.0)
            }
        }

        for v in 0..<8 {
            for u in 0..<8 {
                var sum = 0.0
                for y in 0..<8 {
                    for x in 0..<8 {
                        sum += block[y * 8 + x] * cosTable[u][x] * cosTable[v][y]
                    }
                }

                let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0

                result[v * 8 + u] = 0.25 * cu * cv * sum
            }
        }

        return result
    }

    // MARK: - Quantization

    private static func quantize(_ dct: [Double], quantTable: [Int]) -> [Int] {
        return (0..<64).map { i in
            Int(round(dct[i] / Double(quantTable[i])))
        }
    }

    // MARK: - Huffman Code Building

    private static func buildHuffmanCodes(bits: [Int], values: [Int]) -> [Int: HuffmanCode] {
        var codes = [Int: HuffmanCode]()
        var code: UInt16 = 0
        var valueIndex = 0

        for length in 1...16 {
            for _ in 0..<bits[length - 1] {
                if valueIndex < values.count {
                    codes[values[valueIndex]] = HuffmanCode(code: code, length: length)
                    valueIndex += 1
                }
                code += 1
            }
            code <<= 1
        }

        return codes
    }

    // MARK: - Block Encoding

    private static func encodeBlock(
        _ block: [Int],
        prevDC: Int,
        dcCodes: [Int: HuffmanCode],
        acCodes: [Int: HuffmanCode],
        writer: inout BitWriter
    ) -> Int {
        // Zig-zag reorder
        var zigzag = [Int](repeating: 0, count: 64)
        for i in 0..<64 {
            zigzag[i] = block[zigzagOrder[i]]
        }

        // Encode DC coefficient (differential)
        let dc = zigzag[0]
        let dcDiff = dc - prevDC
        encodeDCCoefficient(dcDiff, codes: dcCodes, writer: &writer)

        // Encode AC coefficients
        encodeACCoefficients(Array(zigzag[1...]), codes: acCodes, writer: &writer)

        return dc
    }

    private static func encodeDCCoefficient(_ diff: Int, codes: [Int: HuffmanCode], writer: inout BitWriter) {
        let (category, bits) = getCategoryAndBits(diff)

        if let huffCode = codes[category] {
            writer.write(bits: Int(huffCode.code), count: huffCode.length)
            if category > 0 {
                writer.write(bits: bits, count: category)
            }
        }
    }

    private static func encodeACCoefficients(_ coeffs: [Int], codes: [Int: HuffmanCode], writer: inout BitWriter) {
        var zeroCount = 0

        for i in 0..<coeffs.count {
            if coeffs[i] == 0 {
                zeroCount += 1
            } else {
                // Emit ZRL (16 zeros) codes as needed
                while zeroCount >= 16 {
                    if let zrlCode = codes[0xF0] {
                        writer.write(bits: Int(zrlCode.code), count: zrlCode.length)
                    }
                    zeroCount -= 16
                }

                let (category, bits) = getCategoryAndBits(coeffs[i])
                let symbol = (zeroCount << 4) | category

                if let huffCode = codes[symbol] {
                    writer.write(bits: Int(huffCode.code), count: huffCode.length)
                    writer.write(bits: bits, count: category)
                }

                zeroCount = 0
            }
        }

        // End of block
        if zeroCount > 0 {
            if let eobCode = codes[0x00] {
                writer.write(bits: Int(eobCode.code), count: eobCode.length)
            }
        }
    }

    private static func getCategoryAndBits(_ value: Int) -> (category: Int, bits: Int) {
        if value == 0 {
            return (0, 0)
        }

        let absValue = abs(value)
        var category = 0
        var temp = absValue

        while temp > 0 {
            category += 1
            temp >>= 1
        }

        let bits = value >= 0 ? value : value + (1 << category) - 1

        return (category, bits)
    }

    // MARK: - JPEG File Building

    private static func buildJPEGFile(
        width: Int,
        height: Int,
        lumQuant: [Int],
        chromQuant: [Int],
        imageData: [UInt8]
    ) -> Data {
        var output = Data()
        output.reserveCapacity(imageData.count + 1024)

        // SOI
        output.append(contentsOf: [0xFF, 0xD8])

        // APP0 (JFIF)
        output.append(contentsOf: buildAPP0Marker())

        // DQT (Quantization tables)
        output.append(contentsOf: buildDQTMarker(tableId: 0, table: lumQuant))
        output.append(contentsOf: buildDQTMarker(tableId: 1, table: chromQuant))

        // SOF0 (Start of Frame - Baseline DCT)
        output.append(contentsOf: buildSOF0Marker(width: width, height: height))

        // DHT (Huffman tables)
        output.append(contentsOf: buildDHTMarker(tableClass: 0, tableId: 0, bits: dcLuminanceHuffmanBits, values: dcLuminanceHuffmanValues))
        output.append(contentsOf: buildDHTMarker(tableClass: 1, tableId: 0, bits: acLuminanceHuffmanBits, values: acLuminanceHuffmanValues))
        output.append(contentsOf: buildDHTMarker(tableClass: 0, tableId: 1, bits: dcChrominanceHuffmanBits, values: dcChrominanceHuffmanValues))
        output.append(contentsOf: buildDHTMarker(tableClass: 1, tableId: 1, bits: acChrominanceHuffmanBits, values: acChrominanceHuffmanValues))

        // SOS (Start of Scan)
        output.append(contentsOf: buildSOSMarker())

        // Image data (with byte stuffing)
        for byte in imageData {
            output.append(byte)
            if byte == 0xFF {
                output.append(0x00) // Byte stuffing
            }
        }

        // EOI
        output.append(contentsOf: [0xFF, 0xD9])

        return output
    }

    private static func buildAPP0Marker() -> [UInt8] {
        var marker: [UInt8] = [0xFF, 0xE0]
        marker.append(contentsOf: [0x00, 0x10]) // Length = 16
        marker.append(contentsOf: [0x4A, 0x46, 0x49, 0x46, 0x00]) // "JFIF\0"
        marker.append(contentsOf: [0x01, 0x01]) // Version 1.1
        marker.append(0x00) // Aspect ratio units (0 = no units)
        marker.append(contentsOf: [0x00, 0x01]) // X density = 1
        marker.append(contentsOf: [0x00, 0x01]) // Y density = 1
        marker.append(contentsOf: [0x00, 0x00]) // No thumbnail
        return marker
    }

    private static func buildDQTMarker(tableId: Int, table: [Int]) -> [UInt8] {
        var marker: [UInt8] = [0xFF, 0xDB]
        let length = 2 + 1 + 64
        marker.append(UInt8(length >> 8))
        marker.append(UInt8(length & 0xFF))
        marker.append(UInt8(tableId)) // 0 = 8-bit values, table ID
        for i in 0..<64 {
            marker.append(UInt8(table[zigzagOrder[i]]))
        }
        return marker
    }

    private static func buildSOF0Marker(width: Int, height: Int) -> [UInt8] {
        var marker: [UInt8] = [0xFF, 0xC0]
        let length = 2 + 1 + 2 + 2 + 1 + 3 * 3
        marker.append(UInt8(length >> 8))
        marker.append(UInt8(length & 0xFF))
        marker.append(0x08) // Precision = 8 bits
        marker.append(UInt8(height >> 8))
        marker.append(UInt8(height & 0xFF))
        marker.append(UInt8(width >> 8))
        marker.append(UInt8(width & 0xFF))
        marker.append(0x03) // Number of components = 3

        // Y component: ID=1, sampling=1x1, quant table=0
        marker.append(contentsOf: [0x01, 0x11, 0x00])
        // Cb component: ID=2, sampling=1x1, quant table=1
        marker.append(contentsOf: [0x02, 0x11, 0x01])
        // Cr component: ID=3, sampling=1x1, quant table=1
        marker.append(contentsOf: [0x03, 0x11, 0x01])

        return marker
    }

    private static func buildDHTMarker(tableClass: Int, tableId: Int, bits: [Int], values: [Int]) -> [UInt8] {
        var marker: [UInt8] = [0xFF, 0xC4]
        let length = 2 + 1 + 16 + values.count
        marker.append(UInt8(length >> 8))
        marker.append(UInt8(length & 0xFF))
        marker.append(UInt8((tableClass << 4) | tableId))

        for i in 0..<16 {
            marker.append(UInt8(bits[i]))
        }
        for value in values {
            marker.append(UInt8(value))
        }

        return marker
    }

    private static func buildSOSMarker() -> [UInt8] {
        var marker: [UInt8] = [0xFF, 0xDA]
        let length = 2 + 1 + 2 * 3 + 3
        marker.append(UInt8(length >> 8))
        marker.append(UInt8(length & 0xFF))
        marker.append(0x03) // Number of components = 3

        // Y: DC table 0, AC table 0
        marker.append(contentsOf: [0x01, 0x00])
        // Cb: DC table 1, AC table 1
        marker.append(contentsOf: [0x02, 0x11])
        // Cr: DC table 1, AC table 1
        marker.append(contentsOf: [0x03, 0x11])

        // Spectral selection and successive approximation
        marker.append(contentsOf: [0x00, 0x3F, 0x00])

        return marker
    }
}

// MARK: - Bit Writer

private struct BitWriter {
    private(set) var bytes: [UInt8] = []
    private var currentByte: UInt8 = 0
    private var bitPosition: Int = 7

    mutating func write(bits: Int, count: Int) {
        var remaining = count
        let value = bits

        while remaining > 0 {
            let bitsToWrite = min(remaining, bitPosition + 1)
            let shift = remaining - bitsToWrite
            let mask = (1 << bitsToWrite) - 1
            let extracted = (value >> shift) & mask

            currentByte |= UInt8(extracted << (bitPosition + 1 - bitsToWrite))
            bitPosition -= bitsToWrite
            remaining -= bitsToWrite

            if bitPosition < 0 {
                bytes.append(currentByte)
                currentByte = 0
                bitPosition = 7
            }
        }
    }

    mutating func flush() {
        if bitPosition < 7 {
            // Fill remaining bits with 1s
            currentByte |= UInt8((1 << (bitPosition + 1)) - 1)
            bytes.append(currentByte)
            currentByte = 0
            bitPosition = 7
        }
    }
}
