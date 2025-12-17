// LZW.swift
// OpenImageIO
//
// LZW compression/decompression for GIF format

import Foundation

/// LZW compression and decompression (GIF variant)
internal struct LZW {

    // MARK: - Constants

    static let MAX_CODE_SIZE = 12
    static let MAX_TABLE_SIZE = 1 << MAX_CODE_SIZE // 4096

    // MARK: - Public API

    /// Decode LZW-compressed data
    /// - Parameters:
    ///   - data: Compressed data (sub-blocks concatenated)
    ///   - minCodeSize: Minimum code size (typically 2-8 for GIF)
    /// - Returns: Decompressed data or nil on error
    static func decode(data: Data, minCodeSize: Int) -> Data? {
        guard minCodeSize >= 2 && minCodeSize <= 8 else { return nil }
        guard !data.isEmpty else { return nil }

        var decoder = LZWDecoder(minCodeSize: minCodeSize)
        return decoder.decode(data: data)
    }

    /// Encode data using LZW compression
    /// - Parameters:
    ///   - data: Data to compress
    ///   - minCodeSize: Minimum code size (typically 2-8 for GIF)
    /// - Returns: Compressed data
    static func encode(data: Data, minCodeSize: Int) -> Data? {
        guard minCodeSize >= 2 && minCodeSize <= 8 else { return nil }

        var encoder = LZWEncoder(minCodeSize: minCodeSize)
        return encoder.encode(data: data)
    }
}

// MARK: - LZW Decoder

private struct LZWDecoder {
    private let minCodeSize: Int
    private let clearCode: Int
    private let endCode: Int

    private var codeSize: Int
    private var nextCode: Int
    private var table: [[UInt8]]

    init(minCodeSize: Int) {
        self.minCodeSize = minCodeSize
        self.clearCode = 1 << minCodeSize
        self.endCode = clearCode + 1
        self.codeSize = minCodeSize + 1
        self.nextCode = endCode + 1
        self.table = []

        initializeTable()
    }

    private mutating func initializeTable() {
        table = []
        // Initialize with single-byte entries
        for i in 0..<clearCode {
            table.append([UInt8(i)])
        }
        // Clear code and end code (not actual data)
        table.append([]) // clearCode
        table.append([]) // endCode

        codeSize = minCodeSize + 1
        nextCode = endCode + 1
    }

    mutating func decode(data: Data) -> Data? {
        var output: [UInt8] = []
        var bitReader = LZWBitReader(data: data)

        var prevCode: Int? = nil

        while true {
            guard let code = bitReader.readBits(codeSize) else {
                break
            }

            if code == clearCode {
                initializeTable()
                prevCode = nil
                continue
            }

            if code == endCode {
                break
            }

            var entry: [UInt8]

            if code < table.count {
                entry = table[code]
            } else if code == nextCode {
                // Special case: code not yet in table
                guard let prev = prevCode, prev < table.count else {
                    return nil
                }
                entry = table[prev]
                entry.append(entry[0])
            } else {
                // Invalid code
                return nil
            }

            output.append(contentsOf: entry)

            // Add new entry to table
            if let prev = prevCode, prev < table.count {
                var newEntry = table[prev]
                newEntry.append(entry[0])

                if nextCode < LZW.MAX_TABLE_SIZE {
                    table.append(newEntry)
                    nextCode += 1

                    // Increase code size if needed (when nextCode exceeds current code size capacity)
                    if nextCode >= (1 << codeSize) && codeSize < LZW.MAX_CODE_SIZE {
                        codeSize += 1
                    }
                }
            }

            prevCode = code
        }

        return Data(output)
    }
}

// MARK: - LZW Encoder

private struct LZWEncoder {
    private let minCodeSize: Int
    private let clearCode: Int
    private let endCode: Int

    init(minCodeSize: Int) {
        self.minCodeSize = minCodeSize
        self.clearCode = 1 << minCodeSize
        self.endCode = clearCode + 1
    }

    mutating func encode(data: Data) -> Data? {
        guard !data.isEmpty else { return nil }

        var bitWriter = LZWBitWriter()
        var codeSize = minCodeSize + 1
        var nextCode = endCode + 1

        // Build string table using dictionary for faster lookup
        var stringTable: [[UInt8]: Int] = [:]
        for i in 0..<clearCode {
            stringTable[[UInt8(i)]] = i
        }

        // Write clear code
        bitWriter.writeBits(clearCode, count: codeSize)

        var currentString: [UInt8] = []

        for byte in data {
            var testString = currentString
            testString.append(byte)

            if stringTable[testString] != nil {
                currentString = testString
            } else {
                // Output code for current string
                if let code = stringTable[currentString] {
                    bitWriter.writeBits(code, count: codeSize)
                }

                // Add new string to table
                if nextCode < LZW.MAX_TABLE_SIZE {
                    stringTable[testString] = nextCode
                    nextCode += 1

                    // Increase code size if needed (when nextCode exceeds current code size capacity)
                    if nextCode >= (1 << codeSize) && codeSize < LZW.MAX_CODE_SIZE {
                        codeSize += 1
                    }
                } else {
                    // Table full, emit clear code and reset
                    bitWriter.writeBits(clearCode, count: codeSize)
                    stringTable = [:]
                    for i in 0..<clearCode {
                        stringTable[[UInt8(i)]] = i
                    }
                    codeSize = minCodeSize + 1
                    nextCode = endCode + 1
                }

                currentString = [byte]
            }
        }

        // Output remaining string
        if !currentString.isEmpty {
            if let code = stringTable[currentString] {
                bitWriter.writeBits(code, count: codeSize)
            }
        }

        // Write end code
        bitWriter.writeBits(endCode, count: codeSize)

        return bitWriter.finish()
    }
}

// MARK: - Bit Reader for LZW

private struct LZWBitReader {
    private let data: Data
    private var byteOffset: Int = 0
    private var bitBuffer: UInt32 = 0
    private var bitsInBuffer: Int = 0

    init(data: Data) {
        self.data = data
    }

    mutating func readBits(_ count: Int) -> Int? {
        while bitsInBuffer < count {
            guard byteOffset < data.count else {
                if bitsInBuffer > 0 && bitsInBuffer >= count {
                    break
                }
                return nil
            }
            bitBuffer |= UInt32(data[byteOffset]) << bitsInBuffer
            byteOffset += 1
            bitsInBuffer += 8
        }

        let mask = (1 << count) - 1
        let result = Int(bitBuffer) & mask
        bitBuffer >>= count
        bitsInBuffer -= count

        return result
    }
}

// MARK: - Bit Writer for LZW

private struct LZWBitWriter {
    private var data: [UInt8] = []
    private var bitBuffer: UInt32 = 0
    private var bitsInBuffer: Int = 0

    mutating func writeBits(_ value: Int, count: Int) {
        bitBuffer |= UInt32(value) << bitsInBuffer
        bitsInBuffer += count

        while bitsInBuffer >= 8 {
            data.append(UInt8(bitBuffer & 0xFF))
            bitBuffer >>= 8
            bitsInBuffer -= 8
        }
    }

    mutating func finish() -> Data {
        if bitsInBuffer > 0 {
            data.append(UInt8(bitBuffer & 0xFF))
        }
        return Data(data)
    }
}
