// Deflate.swift
// OpenImageIO
//
// DEFLATE compression/decompression implementation (RFC 1951)
// with zlib wrapper support (RFC 1950)

import Foundation

/// DEFLATE compression and decompression
internal struct Deflate {

    // MARK: - Public API

    /// Decompress zlib-wrapped DEFLATE data
    static func inflate(data: Data) -> Data? {
        guard data.count >= 6 else { return nil }

        return data.withUnsafeBytes { buffer -> Data? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Parse zlib header
            let cmf = ptr[0]
            let flg = ptr[1]

            // Check compression method (must be 8 = deflate)
            let cm = cmf & 0x0F
            guard cm == 8 else { return nil }

            // Check header checksum
            let check = (UInt16(cmf) * 256 + UInt16(flg)) % 31
            guard check == 0 else { return nil }

            // Check for preset dictionary (not supported)
            let fdict = (flg >> 5) & 1
            guard fdict == 0 else { return nil }

            // Decompress DEFLATE data
            var inflater = Inflater(data: data, offset: 2)
            guard let decompressed = inflater.inflate() else {
                return nil
            }

            // Verify Adler-32 checksum
            let checksumOffset = inflater.currentByteOffset
            guard checksumOffset + 4 <= data.count else {
                return decompressed // Return data even if checksum is missing
            }

            let storedChecksum = (UInt32(ptr[checksumOffset]) << 24) |
                                 (UInt32(ptr[checksumOffset + 1]) << 16) |
                                 (UInt32(ptr[checksumOffset + 2]) << 8) |
                                 UInt32(ptr[checksumOffset + 3])

            let calculatedChecksum = adler32(decompressed)
            guard storedChecksum == calculatedChecksum else {
                return nil
            }

            return decompressed
        }
    }

    /// Decompress raw DEFLATE data (without zlib wrapper)
    static func inflateRaw(data: Data, offset: Int = 0) -> Data? {
        var inflater = Inflater(data: data, offset: offset)
        return inflater.inflate()
    }

    /// Compress data using DEFLATE with zlib wrapper
    static func deflate(data: Data, level: Int = 6) -> Data? {
        var output = Data()

        // zlib header
        let cmf: UInt8 = 0x78 // CM=8 (deflate), CINFO=7 (32K window)
        let flevel: UInt8 = level < 2 ? 0 : (level < 6 ? 1 : (level < 8 ? 2 : 3))
        var flg: UInt8 = flevel << 6
        // Adjust FLG so (CMF * 256 + FLG) % 31 == 0
        let remainder = (UInt16(cmf) * 256 + UInt16(flg)) % 31
        if remainder != 0 {
            flg += UInt8(31 - remainder)
        }

        output.append(cmf)
        output.append(flg)

        // Compress data
        let compressed = deflateRaw(data: data, level: level)
        output.append(compressed)

        // Adler-32 checksum
        let checksum = adler32(data)
        output.append(UInt8((checksum >> 24) & 0xFF))
        output.append(UInt8((checksum >> 16) & 0xFF))
        output.append(UInt8((checksum >> 8) & 0xFF))
        output.append(UInt8(checksum & 0xFF))

        return output
    }

    /// Compress data using raw DEFLATE (without zlib wrapper)
    static func deflateRaw(data: Data, level: Int = 6) -> Data {
        if level == 0 {
            return deflateStore(data: data)
        } else {
            return deflateFixed(data: data)
        }
    }

    // MARK: - Stored Blocks (No Compression)

    private static func deflateStore(data: Data) -> Data {
        var output = Data()
        var offset = 0
        let maxBlockSize = 65535

        while offset < data.count {
            let remaining = data.count - offset
            let blockSize = min(remaining, maxBlockSize)
            let isFinal = (offset + blockSize) >= data.count

            // Block header
            let bfinal: UInt8 = isFinal ? 1 : 0
            output.append(bfinal) // BFINAL=1/0, BTYPE=00 (stored)

            // Length and complement
            let len = UInt16(blockSize)
            let nlen = ~len
            output.append(UInt8(len & 0xFF))
            output.append(UInt8((len >> 8) & 0xFF))
            output.append(UInt8(nlen & 0xFF))
            output.append(UInt8((nlen >> 8) & 0xFF))

            // Data
            output.append(data[offset..<(offset + blockSize)])
            offset += blockSize
        }

        return output
    }

    // MARK: - Fixed Huffman Encoding

    private static func deflateFixed(data: Data) -> Data {
        var bitWriter = BitWriter()

        // Write single block with fixed Huffman
        bitWriter.writeBits(1, count: 1) // BFINAL = 1
        bitWriter.writeBits(1, count: 2) // BTYPE = 01 (fixed Huffman)

        // Encode data using fixed Huffman codes
        for byte in data {
            let code = fixedLiteralCode(Int(byte))
            bitWriter.writeBitsReversed(UInt32(code.bits), count: code.length)
        }

        // End of block
        let endCode = fixedLiteralCode(256)
        bitWriter.writeBitsReversed(UInt32(endCode.bits), count: endCode.length)

        return bitWriter.finish()
    }

    private static func fixedLiteralCode(_ value: Int) -> (bits: Int, length: Int) {
        switch value {
        case 0...143:
            return (0b00110000 + value, 8)
        case 144...255:
            return (0b110010000 + (value - 144), 9)
        case 256...279:
            return (value - 256, 7)
        case 280...287:
            return (0b11000000 + (value - 280), 8)
        default:
            return (0, 0)
        }
    }

    // MARK: - Adler-32

    static func adler32(_ data: Data) -> UInt32 {
        let BASE: UInt32 = 65521
        let NMAX = 5552

        var a: UInt32 = 1
        var b: UInt32 = 0

        data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }

            var index = 0
            let count = data.count

            while index < count {
                let chunkSize = min(NMAX, count - index)
                let end = index + chunkSize

                while index < end {
                    a &+= UInt32(ptr[index])
                    b &+= a
                    index += 1
                }

                a %= BASE
                b %= BASE
            }
        }

        return (b << 16) | a
    }
}

// MARK: - Inflater (Decompression)

private struct Inflater {
    private let data: Data
    private var bitReader: BitReader
    private var output: [UInt8] = []

    var currentByteOffset: Int {
        return bitReader.byteOffset
    }

    init(data: Data, offset: Int) {
        self.data = data
        self.bitReader = BitReader(data: data, offset: offset)
    }

    mutating func inflate() -> Data? {
        while true {
            guard let bfinal = bitReader.readBits(1) else { return nil }
            guard let btype = bitReader.readBits(2) else { return nil }

            switch btype {
            case 0:
                // Stored block
                guard inflateStored() else { return nil }
            case 1:
                // Fixed Huffman
                guard inflateFixed() else { return nil }
            case 2:
                // Dynamic Huffman
                guard inflateDynamic() else { return nil }
            default:
                return nil
            }

            if bfinal == 1 {
                break
            }
        }

        return Data(output)
    }

    private mutating func inflateStored() -> Bool {
        bitReader.alignToByte()

        guard let len = bitReader.readBytes(2),
              let nlen = bitReader.readBytes(2) else {
            return false
        }

        guard len == (~nlen & 0xFFFF) else {
            return false
        }

        for _ in 0..<len {
            guard let byte = bitReader.readByte() else { return false }
            output.append(byte)
        }

        return true
    }

    private mutating func inflateFixed() -> Bool {
        let litLenTree = HuffmanTree.fixedLiteralLengthTree
        let distTree = HuffmanTree.fixedDistanceTree

        return inflateWithTrees(litLenTree: litLenTree, distTree: distTree)
    }

    private mutating func inflateDynamic() -> Bool {
        // Read code lengths
        guard let hlit = bitReader.readBits(5),
              let hdist = bitReader.readBits(5),
              let hclen = bitReader.readBits(4) else {
            return false
        }

        let numLitLenCodes = Int(hlit) + 257
        let numDistCodes = Int(hdist) + 1
        let numCodeLenCodes = Int(hclen) + 4

        // Read code length code lengths
        let codeLenOrder = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
        var codeLenCodeLengths = [Int](repeating: 0, count: 19)

        for i in 0..<numCodeLenCodes {
            guard let len = bitReader.readBits(3) else { return false }
            codeLenCodeLengths[codeLenOrder[i]] = Int(len)
        }

        // Build code length tree
        guard let codeLenTree = HuffmanTree(codeLengths: codeLenCodeLengths) else {
            return false
        }

        // Decode literal/length and distance code lengths
        var allCodeLengths = [Int]()
        let totalCodes = numLitLenCodes + numDistCodes

        while allCodeLengths.count < totalCodes {
            guard let symbol = decodeSymbol(tree: codeLenTree) else {
                return false
            }

            if symbol < 16 {
                allCodeLengths.append(symbol)
            } else if symbol == 16 {
                guard let repeat_count = bitReader.readBits(2),
                      !allCodeLengths.isEmpty else {
                    return false
                }
                let lastLen = allCodeLengths.last!
                for _ in 0..<(Int(repeat_count) + 3) {
                    allCodeLengths.append(lastLen)
                }
            } else if symbol == 17 {
                guard let repeat_count = bitReader.readBits(3) else {
                    return false
                }
                for _ in 0..<(Int(repeat_count) + 3) {
                    allCodeLengths.append(0)
                }
            } else if symbol == 18 {
                guard let repeat_count = bitReader.readBits(7) else {
                    return false
                }
                for _ in 0..<(Int(repeat_count) + 11) {
                    allCodeLengths.append(0)
                }
            }
        }

        // Build trees
        let litLenCodeLengths = Array(allCodeLengths[0..<numLitLenCodes])
        let distCodeLengths = Array(allCodeLengths[numLitLenCodes..<totalCodes])

        guard let litLenTree = HuffmanTree(codeLengths: litLenCodeLengths),
              let distTree = HuffmanTree(codeLengths: distCodeLengths) else {
            return false
        }

        return inflateWithTrees(litLenTree: litLenTree, distTree: distTree)
    }

    private mutating func inflateWithTrees(litLenTree: HuffmanTree, distTree: HuffmanTree) -> Bool {
        while true {
            guard let symbol = decodeSymbol(tree: litLenTree) else {
                return false
            }

            if symbol < 256 {
                output.append(UInt8(symbol))
            } else if symbol == 256 {
                return true // End of block
            } else {
                // Length/distance pair
                let lengthCode = symbol - 257
                guard lengthCode < lengthTable.count else { return false }

                let (baseLength, extraLengthBits) = lengthTable[lengthCode]
                var length = baseLength

                if extraLengthBits > 0 {
                    guard let extra = bitReader.readBits(extraLengthBits) else {
                        return false
                    }
                    length += Int(extra)
                }

                guard let distSymbol = decodeSymbol(tree: distTree),
                      distSymbol < distanceTable.count else {
                    return false
                }

                let (baseDistance, extraDistBits) = distanceTable[distSymbol]
                var distance = baseDistance

                if extraDistBits > 0 {
                    guard let extra = bitReader.readBits(extraDistBits) else {
                        return false
                    }
                    distance += Int(extra)
                }

                // Copy from output buffer
                guard distance <= output.count else { return false }

                let startPos = output.count - distance
                for i in 0..<length {
                    output.append(output[startPos + (i % distance)])
                }
            }
        }
    }

    private mutating func decodeSymbol(tree: HuffmanTree) -> Int? {
        var node = tree.root

        while true {
            guard let bit = bitReader.readBits(1) else {
                return nil
            }

            if bit == 0 {
                guard let left = node.left else { return nil }
                node = left
            } else {
                guard let right = node.right else { return nil }
                node = right
            }

            if let symbol = node.symbol {
                return symbol
            }
        }
    }

    // Length table: (base length, extra bits)
    private let lengthTable: [(Int, Int)] = [
        (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),
        (11, 1), (13, 1), (15, 1), (17, 1),
        (19, 2), (23, 2), (27, 2), (31, 2),
        (35, 3), (43, 3), (51, 3), (59, 3),
        (67, 4), (83, 4), (99, 4), (115, 4),
        (131, 5), (163, 5), (195, 5), (227, 5),
        (258, 0)
    ]

    // Distance table: (base distance, extra bits)
    private let distanceTable: [(Int, Int)] = [
        (1, 0), (2, 0), (3, 0), (4, 0),
        (5, 1), (7, 1),
        (9, 2), (13, 2),
        (17, 3), (25, 3),
        (33, 4), (49, 4),
        (65, 5), (97, 5),
        (129, 6), (193, 6),
        (257, 7), (385, 7),
        (513, 8), (769, 8),
        (1025, 9), (1537, 9),
        (2049, 10), (3073, 10),
        (4097, 11), (6145, 11),
        (8193, 12), (12289, 12),
        (16385, 13), (24577, 13)
    ]
}

// MARK: - Huffman Tree

private class HuffmanNode {
    var symbol: Int?
    var left: HuffmanNode?
    var right: HuffmanNode?

    init(symbol: Int? = nil) {
        self.symbol = symbol
    }
}

private struct HuffmanTree {
    let root: HuffmanNode

    init?(codeLengths: [Int]) {
        let maxBits = codeLengths.max() ?? 0
        guard maxBits > 0 else {
            // Empty tree
            root = HuffmanNode()
            return
        }

        // Count codes of each length
        var blCount = [Int](repeating: 0, count: maxBits + 1)
        for len in codeLengths where len > 0 {
            blCount[len] += 1
        }

        // Calculate starting codes for each length
        var nextCode = [Int](repeating: 0, count: maxBits + 1)
        var code = 0
        for bits in 1...maxBits {
            code = (code + blCount[bits - 1]) << 1
            nextCode[bits] = code
        }

        // Build tree
        root = HuffmanNode()

        for (symbol, length) in codeLengths.enumerated() {
            guard length > 0 else { continue }

            let code = nextCode[length]
            nextCode[length] += 1

            // Insert into tree
            var node = root
            for i in stride(from: length - 1, through: 0, by: -1) {
                let bit = (code >> i) & 1
                if bit == 0 {
                    if node.left == nil {
                        node.left = HuffmanNode()
                    }
                    node = node.left!
                } else {
                    if node.right == nil {
                        node.right = HuffmanNode()
                    }
                    node = node.right!
                }
            }
            node.symbol = symbol
        }
    }

    // Fixed literal/length tree (codes 0-287)
    nonisolated(unsafe) static let fixedLiteralLengthTree: HuffmanTree = {
        var codeLengths = [Int](repeating: 0, count: 288)
        for i in 0...143 { codeLengths[i] = 8 }
        for i in 144...255 { codeLengths[i] = 9 }
        for i in 256...279 { codeLengths[i] = 7 }
        for i in 280...287 { codeLengths[i] = 8 }
        return HuffmanTree(codeLengths: codeLengths)!
    }()

    // Fixed distance tree (codes 0-31)
    nonisolated(unsafe) static let fixedDistanceTree: HuffmanTree = {
        let codeLengths = [Int](repeating: 5, count: 32)
        return HuffmanTree(codeLengths: codeLengths)!
    }()
}

// MARK: - Bit Reader

private struct BitReader {
    private let data: Data
    private var offset: Int
    private var bitBuffer: UInt32 = 0
    private var bitCount: Int = 0

    var byteOffset: Int { offset }

    init(data: Data, offset: Int) {
        self.data = data
        self.offset = offset
    }

    mutating func readBits(_ count: Int) -> UInt32? {
        while bitCount < count {
            guard offset < data.count else { return nil }
            bitBuffer |= UInt32(data[offset]) << bitCount
            offset += 1
            bitCount += 8
        }

        let result = bitBuffer & ((1 << count) - 1)
        bitBuffer >>= count
        bitCount -= count
        return result
    }

    mutating func readByte() -> UInt8? {
        guard offset < data.count else { return nil }
        let byte = data[offset]
        offset += 1
        return byte
    }

    mutating func readBytes(_ count: Int) -> UInt32? {
        var result: UInt32 = 0
        for i in 0..<count {
            guard let byte = readByte() else { return nil }
            result |= UInt32(byte) << (i * 8)
        }
        return result
    }

    mutating func alignToByte() {
        bitBuffer = 0
        bitCount = 0
    }
}

// MARK: - Bit Writer

private struct BitWriter {
    private var data: [UInt8] = []
    private var bitBuffer: UInt32 = 0
    private var bitCount: Int = 0

    mutating func writeBits(_ value: UInt32, count: Int) {
        bitBuffer |= value << bitCount
        bitCount += count

        while bitCount >= 8 {
            data.append(UInt8(bitBuffer & 0xFF))
            bitBuffer >>= 8
            bitCount -= 8
        }
    }

    mutating func writeBitsReversed(_ value: UInt32, count: Int) {
        // Reverse bits before writing
        var reversed: UInt32 = 0
        var v = value
        for _ in 0..<count {
            reversed = (reversed << 1) | (v & 1)
            v >>= 1
        }
        writeBits(reversed, count: count)
    }

    mutating func finish() -> Data {
        if bitCount > 0 {
            data.append(UInt8(bitBuffer & 0xFF))
        }
        return Data(data)
    }
}
