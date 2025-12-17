// JPEGDecoder.swift
// OpenImageIO
//
// JPEG image format decoder (Baseline DCT)

import Foundation

/// JPEG image decoder supporting baseline DCT
internal struct JPEGDecoder {

    // MARK: - JPEG Markers

    private static let SOI: UInt16 = 0xFFD8   // Start of Image
    private static let EOI: UInt16 = 0xFFD9   // End of Image
    private static let SOS: UInt8 = 0xDA      // Start of Scan
    private static let DQT: UInt8 = 0xDB      // Define Quantization Table
    private static let DHT: UInt8 = 0xC4      // Define Huffman Table
    private static let SOF0: UInt8 = 0xC0     // Baseline DCT
    private static let SOF2: UInt8 = 0xC2     // Progressive DCT
    private static let APP0: UInt8 = 0xE0     // JFIF
    private static let APP1: UInt8 = 0xE1     // EXIF
    private static let DRI: UInt8 = 0xDD      // Define Restart Interval
    private static let RST0: UInt8 = 0xD0     // Restart marker 0
    private static let RST7: UInt8 = 0xD7     // Restart marker 7

    // MARK: - Decode Result

    struct DecodeResult {
        let pixels: Data
        let width: Int
        let height: Int
    }

    // MARK: - Internal Types

    private struct QuantizationTable {
        var values: [Int] = Array(repeating: 0, count: 64)
    }

    private struct HuffmanTable {
        var codes: [Int: Int] = [:]  // code -> value
        var maxBits: Int = 0
    }

    private struct Component {
        let id: Int
        let hSampling: Int
        let vSampling: Int
        let quantTableId: Int
        var dcTableId: Int = 0
        var acTableId: Int = 0
    }

    private struct FrameInfo {
        let precision: Int
        let height: Int
        let width: Int
        var components: [Component]
    }

    // MARK: - Public API

    static func decode(data: Data) -> DecodeResult? {
        guard data.count >= 2 else { return nil }

        return data.withUnsafeBytes { buffer -> DecodeResult? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Verify JPEG signature
            guard ptr[0] == 0xFF && ptr[1] == 0xD8 else { return nil }

            var offset = 2
            var quantTables: [Int: QuantizationTable] = [:]
            var dcHuffmanTables: [Int: HuffmanTable] = [:]
            var acHuffmanTables: [Int: HuffmanTable] = [:]
            var frameInfo: FrameInfo?
            var restartInterval = 0

            // Parse markers
            while offset < data.count - 1 {
                guard ptr[offset] == 0xFF else {
                    offset += 1
                    continue
                }

                let marker = ptr[offset + 1]
                offset += 2

                // Skip padding FF bytes
                if marker == 0xFF || marker == 0x00 {
                    continue
                }

                // EOI
                if marker == 0xD9 {
                    break
                }

                // Restart markers
                if marker >= RST0 && marker <= RST7 {
                    continue
                }

                // Read segment length
                guard offset + 2 <= data.count else { break }
                let length = (Int(ptr[offset]) << 8) | Int(ptr[offset + 1])
                guard length >= 2 else { break }

                let segmentStart = offset + 2
                let segmentEnd = offset + length

                guard segmentEnd <= data.count else { break }

                switch marker {
                case DQT:
                    parseQuantizationTable(ptr: ptr, offset: segmentStart, length: length - 2, tables: &quantTables)

                case DHT:
                    parseHuffmanTable(ptr: ptr, offset: segmentStart, length: length - 2, dcTables: &dcHuffmanTables, acTables: &acHuffmanTables)

                case SOF0:
                    frameInfo = parseFrameHeader(ptr: ptr, offset: segmentStart, length: length - 2)

                case SOF2:
                    // Progressive not supported
                    return nil

                case DRI:
                    if length >= 4 {
                        restartInterval = (Int(ptr[segmentStart]) << 8) | Int(ptr[segmentStart + 1])
                    }

                case SOS:
                    guard var frame = frameInfo else { return nil }

                    // Parse scan header
                    guard segmentStart < segmentEnd else { return nil }
                    let numComponents = Int(ptr[segmentStart])

                    var scanOffset = segmentStart + 1
                    for i in 0..<numComponents {
                        guard scanOffset + 1 < segmentEnd else { break }
                        let compId = Int(ptr[scanOffset])
                        let tableIds = ptr[scanOffset + 1]
                        let dcTableId = Int(tableIds >> 4)
                        let acTableId = Int(tableIds & 0x0F)

                        for j in 0..<frame.components.count {
                            if frame.components[j].id == compId {
                                frame.components[j].dcTableId = dcTableId
                                frame.components[j].acTableId = acTableId
                            }
                        }
                        scanOffset += 2
                    }

                    // Skip spectral selection and successive approximation
                    let dataStart = segmentEnd

                    // Decode image data
                    return decodeImageData(
                        ptr: ptr,
                        dataStart: dataStart,
                        dataCount: data.count,
                        frame: frame,
                        quantTables: quantTables,
                        dcHuffmanTables: dcHuffmanTables,
                        acHuffmanTables: acHuffmanTables,
                        restartInterval: restartInterval
                    )

                default:
                    break
                }

                offset = segmentEnd
            }

            return nil
        }
    }

    // MARK: - Table Parsing

    private static func parseQuantizationTable(ptr: UnsafePointer<UInt8>, offset: Int, length: Int, tables: inout [Int: QuantizationTable]) {
        var pos = offset
        let end = offset + length

        while pos < end {
            let info = ptr[pos]
            let precision = Int(info >> 4)
            let tableId = Int(info & 0x0F)
            pos += 1

            var table = QuantizationTable()
            let bytesPerValue = precision == 0 ? 1 : 2

            for i in 0..<64 {
                guard pos < end else { break }
                if precision == 0 {
                    table.values[zigzagOrder[i]] = Int(ptr[pos])
                    pos += 1
                } else {
                    table.values[zigzagOrder[i]] = (Int(ptr[pos]) << 8) | Int(ptr[pos + 1])
                    pos += 2
                }
            }

            tables[tableId] = table
        }
    }

    private static func parseHuffmanTable(ptr: UnsafePointer<UInt8>, offset: Int, length: Int, dcTables: inout [Int: HuffmanTable], acTables: inout [Int: HuffmanTable]) {
        var pos = offset
        let end = offset + length

        while pos < end {
            let info = ptr[pos]
            let tableClass = Int(info >> 4)  // 0 = DC, 1 = AC
            let tableId = Int(info & 0x0F)
            pos += 1

            // Read code counts for each bit length
            var codeCounts = [Int](repeating: 0, count: 16)
            for i in 0..<16 {
                guard pos < end else { break }
                codeCounts[i] = Int(ptr[pos])
                pos += 1
            }

            // Build Huffman table
            var table = HuffmanTable()
            var code = 0

            for bits in 1...16 {
                for _ in 0..<codeCounts[bits - 1] {
                    guard pos < end else { break }
                    let value = Int(ptr[pos])
                    pos += 1

                    // Store code with bit length
                    let key = (bits << 16) | code
                    table.codes[key] = value
                    table.maxBits = max(table.maxBits, bits)

                    code += 1
                }
                code <<= 1
            }

            if tableClass == 0 {
                dcTables[tableId] = table
            } else {
                acTables[tableId] = table
            }
        }
    }

    private static func parseFrameHeader(ptr: UnsafePointer<UInt8>, offset: Int, length: Int) -> FrameInfo? {
        guard length >= 6 else { return nil }

        let precision = Int(ptr[offset])
        let height = (Int(ptr[offset + 1]) << 8) | Int(ptr[offset + 2])
        let width = (Int(ptr[offset + 3]) << 8) | Int(ptr[offset + 4])
        let numComponents = Int(ptr[offset + 5])

        var components: [Component] = []
        var pos = offset + 6

        for _ in 0..<numComponents {
            guard pos + 2 < offset + length else { break }
            let id = Int(ptr[pos])
            let sampling = ptr[pos + 1]
            let hSampling = Int(sampling >> 4)
            let vSampling = Int(sampling & 0x0F)
            let quantTableId = Int(ptr[pos + 2])

            components.append(Component(
                id: id,
                hSampling: hSampling,
                vSampling: vSampling,
                quantTableId: quantTableId
            ))
            pos += 3
        }

        return FrameInfo(
            precision: precision,
            height: height,
            width: width,
            components: components
        )
    }

    // MARK: - Image Data Decoding

    private static func decodeImageData(
        ptr: UnsafePointer<UInt8>,
        dataStart: Int,
        dataCount: Int,
        frame: FrameInfo,
        quantTables: [Int: QuantizationTable],
        dcHuffmanTables: [Int: HuffmanTable],
        acHuffmanTables: [Int: HuffmanTable],
        restartInterval: Int
    ) -> DecodeResult? {
        let width = frame.width
        let height = frame.height

        guard frame.components.count >= 1 else { return nil }

        // Determine sampling factors
        let maxH = frame.components.map { $0.hSampling }.max() ?? 1
        let maxV = frame.components.map { $0.vSampling }.max() ?? 1

        let mcuWidth = maxH * 8
        let mcuHeight = maxV * 8
        let mcuCountX = (width + mcuWidth - 1) / mcuWidth
        let mcuCountY = (height + mcuHeight - 1) / mcuHeight

        // Create bit reader
        var bitReader = JPEGBitReader(ptr: ptr, start: dataStart, count: dataCount)

        // DC predictors for each component
        var dcPredictors = [Int](repeating: 0, count: frame.components.count)

        // Output buffers for each component
        var componentBuffers: [[Int]] = frame.components.map { comp in
            let bufWidth = mcuCountX * comp.hSampling * 8
            let bufHeight = mcuCountY * comp.vSampling * 8
            return [Int](repeating: 0, count: bufWidth * bufHeight)
        }

        var mcusDecoded = 0

        // Decode MCUs
        for mcuY in 0..<mcuCountY {
            for mcuX in 0..<mcuCountX {
                // Check for restart marker
                if restartInterval > 0 && mcusDecoded > 0 && mcusDecoded % restartInterval == 0 {
                    bitReader.alignToByte()
                    // Skip restart marker (0xFF 0xDn)
                    if bitReader.peekByte() == 0xFF {
                        _ = bitReader.readByte()
                        _ = bitReader.readByte()
                    }
                    // Reset DC predictors
                    dcPredictors = [Int](repeating: 0, count: frame.components.count)
                }

                // Decode each component's blocks in this MCU
                for (compIndex, component) in frame.components.enumerated() {
                    guard let quantTable = quantTables[component.quantTableId],
                          let dcTable = dcHuffmanTables[component.dcTableId],
                          let acTable = acHuffmanTables[component.acTableId] else {
                        return nil
                    }

                    let bufWidth = mcuCountX * component.hSampling * 8

                    for blockY in 0..<component.vSampling {
                        for blockX in 0..<component.hSampling {
                            // Decode 8x8 block
                            var block = [Int](repeating: 0, count: 64)

                            // Decode DC coefficient
                            guard let dcValue = decodeHuffmanValue(bitReader: &bitReader, table: dcTable) else {
                                return nil
                            }

                            if dcValue > 0 {
                                guard let dcDiff = bitReader.readSignedBits(dcValue) else {
                                    return nil
                                }
                                dcPredictors[compIndex] += dcDiff
                            }
                            block[0] = dcPredictors[compIndex]

                            // Decode AC coefficients
                            var acIndex = 1
                            while acIndex < 64 {
                                guard let acValue = decodeHuffmanValue(bitReader: &bitReader, table: acTable) else {
                                    return nil
                                }

                                if acValue == 0 {
                                    // EOB - End of Block
                                    break
                                }

                                let runLength = acValue >> 4
                                let size = acValue & 0x0F

                                if size == 0 && runLength == 15 {
                                    // ZRL - 16 zeros
                                    acIndex += 16
                                    continue
                                }

                                acIndex += runLength

                                if acIndex >= 64 { break }

                                if size > 0 {
                                    guard let acCoeff = bitReader.readSignedBits(size) else {
                                        return nil
                                    }
                                    block[zigzagOrder[acIndex]] = acCoeff
                                }

                                acIndex += 1
                            }

                            // Dequantize
                            for i in 0..<64 {
                                block[i] *= quantTable.values[i]
                            }

                            // Inverse DCT
                            var idctBlock = [Int](repeating: 0, count: 64)
                            inverseDCT(block: block, output: &idctBlock)

                            // Store in component buffer
                            let baseX = mcuX * component.hSampling * 8 + blockX * 8
                            let baseY = mcuY * component.vSampling * 8 + blockY * 8

                            for y in 0..<8 {
                                for x in 0..<8 {
                                    let bufIndex = (baseY + y) * bufWidth + (baseX + x)
                                    if bufIndex < componentBuffers[compIndex].count {
                                        componentBuffers[compIndex][bufIndex] = idctBlock[y * 8 + x]
                                    }
                                }
                            }
                        }
                    }
                }

                mcusDecoded += 1
            }
        }

        // Convert to RGB
        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        if frame.components.count == 1 {
            // Grayscale
            let buffer = componentBuffers[0]
            let bufWidth = mcuCountX * frame.components[0].hSampling * 8

            for y in 0..<height {
                for x in 0..<width {
                    let srcIndex = y * bufWidth + x
                    let dstIndex = (y * width + x) * 4
                    let gray = clamp(buffer[srcIndex] + 128, 0, 255)
                    pixels[dstIndex] = UInt8(gray)
                    pixels[dstIndex + 1] = UInt8(gray)
                    pixels[dstIndex + 2] = UInt8(gray)
                    pixels[dstIndex + 3] = 255
                }
            }
        } else if frame.components.count >= 3 {
            // YCbCr to RGB
            let yComp = frame.components[0]
            let cbComp = frame.components[1]
            let crComp = frame.components[2]

            let yBufWidth = mcuCountX * yComp.hSampling * 8
            let cbBufWidth = mcuCountX * cbComp.hSampling * 8
            let crBufWidth = mcuCountX * crComp.hSampling * 8

            let yBuffer = componentBuffers[0]
            let cbBuffer = componentBuffers[1]
            let crBuffer = componentBuffers[2]

            for y in 0..<height {
                for x in 0..<width {
                    // Calculate source positions with upsampling
                    let yIndex = y * yBufWidth + x

                    // Chroma upsampling
                    let cbX = x * cbComp.hSampling / maxH
                    let cbY = y * cbComp.vSampling / maxV
                    let cbIndex = cbY * cbBufWidth + cbX

                    let crX = x * crComp.hSampling / maxH
                    let crY = y * crComp.vSampling / maxV
                    let crIndex = crY * crBufWidth + crX

                    guard yIndex < yBuffer.count &&
                          cbIndex < cbBuffer.count &&
                          crIndex < crBuffer.count else {
                        continue
                    }

                    let yVal = Double(yBuffer[yIndex])
                    let cbVal = Double(cbBuffer[cbIndex])
                    let crVal = Double(crBuffer[crIndex])

                    // YCbCr to RGB conversion
                    let r = yVal + 1.402 * crVal + 128
                    let g = yVal - 0.344136 * cbVal - 0.714136 * crVal + 128
                    let b = yVal + 1.772 * cbVal + 128

                    let dstIndex = (y * width + x) * 4
                    pixels[dstIndex] = UInt8(clamp(Int(r), 0, 255))
                    pixels[dstIndex + 1] = UInt8(clamp(Int(g), 0, 255))
                    pixels[dstIndex + 2] = UInt8(clamp(Int(b), 0, 255))
                    pixels[dstIndex + 3] = 255
                }
            }
        }

        return DecodeResult(
            pixels: Data(pixels),
            width: width,
            height: height
        )
    }

    // MARK: - Huffman Decoding

    private static func decodeHuffmanValue(bitReader: inout JPEGBitReader, table: HuffmanTable) -> Int? {
        var code = 0

        for bits in 1...16 {
            guard let bit = bitReader.readBit() else {
                return nil
            }
            code = (code << 1) | bit

            let key = (bits << 16) | code
            if let value = table.codes[key] {
                return value
            }
        }

        return nil
    }

    // MARK: - Inverse DCT

    private static func inverseDCT(block: [Int], output: inout [Int]) {
        var temp = [Double](repeating: 0, count: 64)

        // 1D IDCT on rows
        for y in 0..<8 {
            for x in 0..<8 {
                var sum = 0.0
                for u in 0..<8 {
                    let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let cos_val = cos((2.0 * Double(x) + 1.0) * Double(u) * Double.pi / 16.0)
                    sum += cu * Double(block[y * 8 + u]) * cos_val
                }
                temp[y * 8 + x] = sum * 0.5
            }
        }

        // 1D IDCT on columns
        for x in 0..<8 {
            for y in 0..<8 {
                var sum = 0.0
                for v in 0..<8 {
                    let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let cos_val = cos((2.0 * Double(y) + 1.0) * Double(v) * Double.pi / 16.0)
                    sum += cv * temp[v * 8 + x] * cos_val
                }
                output[y * 8 + x] = Int(round(sum * 0.5))
            }
        }
    }

    // MARK: - Helpers

    private static func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
        return Swift.min(Swift.max(value, min), max)
    }

    // Zigzag order for 8x8 block
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
}

// MARK: - JPEG Bit Reader

private struct JPEGBitReader {
    private let ptr: UnsafePointer<UInt8>
    private var offset: Int
    private let endOffset: Int
    private var bitBuffer: UInt32 = 0
    private var bitsInBuffer: Int = 0

    init(ptr: UnsafePointer<UInt8>, start: Int, count: Int) {
        self.ptr = ptr
        self.offset = start
        self.endOffset = count
    }

    mutating func readBit() -> Int? {
        if bitsInBuffer == 0 {
            guard loadByte() else { return nil }
        }

        bitsInBuffer -= 1
        let bit = Int((bitBuffer >> bitsInBuffer) & 1)
        return bit
    }

    mutating func readBits(_ count: Int) -> Int? {
        var result = 0
        for _ in 0..<count {
            guard let bit = readBit() else { return nil }
            result = (result << 1) | bit
        }
        return result
    }

    mutating func readSignedBits(_ count: Int) -> Int? {
        guard count > 0 else { return 0 }
        guard let value = readBits(count) else { return nil }

        // Convert to signed value
        let threshold = 1 << (count - 1)
        if value < threshold {
            return value - (threshold * 2 - 1)
        }
        return value
    }

    mutating func readByte() -> UInt8? {
        guard offset < endOffset else { return nil }
        let byte = ptr[offset]
        offset += 1

        // Handle byte stuffing (0xFF 0x00 -> 0xFF)
        if byte == 0xFF && offset < endOffset && ptr[offset] == 0x00 {
            offset += 1
        }

        return byte
    }

    mutating func peekByte() -> UInt8? {
        guard offset < endOffset else { return nil }
        return ptr[offset]
    }

    mutating func alignToByte() {
        bitBuffer = 0
        bitsInBuffer = 0
    }

    private mutating func loadByte() -> Bool {
        guard offset < endOffset else { return false }

        var byte = ptr[offset]
        offset += 1

        // Handle byte stuffing (0xFF 0x00 -> 0xFF)
        if byte == 0xFF {
            if offset < endOffset {
                let nextByte = ptr[offset]
                if nextByte == 0x00 {
                    offset += 1
                } else if nextByte >= 0xD0 && nextByte <= 0xD7 {
                    // Restart marker - skip and continue
                    offset += 1
                    return loadByte()
                } else if nextByte == 0xD9 {
                    // EOI marker
                    return false
                }
            }
        }

        bitBuffer = UInt32(byte)
        bitsInBuffer = 8
        return true
    }
}
