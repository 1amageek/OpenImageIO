// TIFFDecoder.swift
// OpenImageIO
//
// TIFF image format decoder (basic support)

import Foundation

/// TIFF image decoder supporting basic uncompressed and LZW-compressed TIFF
internal struct TIFFDecoder {

    // MARK: - TIFF Constants

    // Byte order markers
    private static let LITTLE_ENDIAN_MARKER: UInt16 = 0x4949 // "II"
    private static let BIG_ENDIAN_MARKER: UInt16 = 0x4D4D    // "MM"
    private static let TIFF_MAGIC: UInt16 = 42

    // Tag IDs
    private static let TAG_IMAGE_WIDTH: UInt16 = 256
    private static let TAG_IMAGE_LENGTH: UInt16 = 257
    private static let TAG_BITS_PER_SAMPLE: UInt16 = 258
    private static let TAG_COMPRESSION: UInt16 = 259
    private static let TAG_PHOTOMETRIC: UInt16 = 262
    private static let TAG_STRIP_OFFSETS: UInt16 = 273
    private static let TAG_SAMPLES_PER_PIXEL: UInt16 = 277
    private static let TAG_ROWS_PER_STRIP: UInt16 = 278
    private static let TAG_STRIP_BYTE_COUNTS: UInt16 = 279
    private static let TAG_EXTRA_SAMPLES: UInt16 = 338

    // Compression types
    private static let COMPRESSION_NONE: UInt16 = 1
    private static let COMPRESSION_LZW: UInt16 = 5
    private static let COMPRESSION_PACKBITS: UInt16 = 32773

    // Photometric interpretation
    private static let PHOTOMETRIC_WHITE_IS_ZERO: UInt16 = 0
    private static let PHOTOMETRIC_BLACK_IS_ZERO: UInt16 = 1
    private static let PHOTOMETRIC_RGB: UInt16 = 2
    private static let PHOTOMETRIC_PALETTE: UInt16 = 3

    // MARK: - Decode Result

    struct DecodeResult {
        let pixels: Data
        let width: Int
        let height: Int
        let hasAlpha: Bool
    }

    // MARK: - IFD Entry

    private struct IFDEntry {
        let tag: UInt16
        let type: UInt16
        let count: UInt32
        let valueOffset: UInt32
    }

    // MARK: - Image Info

    private struct ImageInfo {
        var width: Int = 0
        var height: Int = 0
        var bitsPerSample: [Int] = [8]
        var compression: UInt16 = 1
        var photometric: UInt16 = 2
        var stripOffsets: [UInt32] = []
        var samplesPerPixel: Int = 1
        var rowsPerStrip: Int = 0
        var stripByteCounts: [UInt32] = []
        var hasAlpha: Bool = false
    }

    // MARK: - Public API

    /// Decode TIFF data to RGBA pixels
    static func decode(data: Data) -> DecodeResult? {
        guard data.count >= 8 else { return nil }

        return data.withUnsafeBytes { buffer -> DecodeResult? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Check byte order
            let byteOrder = UInt16(ptr[0]) | (UInt16(ptr[1]) << 8)
            let isLittleEndian: Bool

            if byteOrder == LITTLE_ENDIAN_MARKER {
                isLittleEndian = true
            } else if byteOrder == BIG_ENDIAN_MARKER {
                isLittleEndian = false
            } else {
                return nil
            }

            // Verify TIFF magic number
            let magic = readUInt16(ptr, offset: 2, littleEndian: isLittleEndian)
            guard magic == TIFF_MAGIC else { return nil }

            // Get IFD offset
            let ifdOffset = Int(readUInt32(ptr, offset: 4, littleEndian: isLittleEndian))
            guard ifdOffset > 0 && ifdOffset + 2 < data.count else { return nil }

            // Parse IFD
            guard let info = parseIFD(ptr: ptr, dataCount: data.count, offset: ifdOffset, littleEndian: isLittleEndian) else {
                return nil
            }

            // Decode image data
            guard let pixels = decodeImageData(ptr: ptr, dataCount: data.count, info: info, littleEndian: isLittleEndian) else {
                return nil
            }

            return DecodeResult(
                pixels: Data(pixels),
                width: info.width,
                height: info.height,
                hasAlpha: info.hasAlpha
            )
        }
    }

    // MARK: - IFD Parsing

    private static func parseIFD(ptr: UnsafePointer<UInt8>, dataCount: Int, offset: Int, littleEndian: Bool) -> ImageInfo? {
        guard offset + 2 <= dataCount else { return nil }

        let numEntries = Int(readUInt16(ptr, offset: offset, littleEndian: littleEndian))
        var info = ImageInfo()

        var entryOffset = offset + 2

        for _ in 0..<numEntries {
            guard entryOffset + 12 <= dataCount else { break }

            let tag = readUInt16(ptr, offset: entryOffset, littleEndian: littleEndian)
            let type = readUInt16(ptr, offset: entryOffset + 2, littleEndian: littleEndian)
            let count = readUInt32(ptr, offset: entryOffset + 4, littleEndian: littleEndian)
            let valueOffset = readUInt32(ptr, offset: entryOffset + 8, littleEndian: littleEndian)

            let entry = IFDEntry(tag: tag, type: type, count: count, valueOffset: valueOffset)

            switch tag {
            case TAG_IMAGE_WIDTH:
                info.width = Int(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_IMAGE_LENGTH:
                info.height = Int(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_BITS_PER_SAMPLE:
                info.bitsPerSample = getEntryValues(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian).map { Int($0) }

            case TAG_COMPRESSION:
                info.compression = UInt16(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_PHOTOMETRIC:
                info.photometric = UInt16(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_STRIP_OFFSETS:
                info.stripOffsets = getEntryValues(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian)

            case TAG_SAMPLES_PER_PIXEL:
                info.samplesPerPixel = Int(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_ROWS_PER_STRIP:
                info.rowsPerStrip = Int(getEntryValue(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian))

            case TAG_STRIP_BYTE_COUNTS:
                info.stripByteCounts = getEntryValues(ptr: ptr, dataCount: dataCount, entry: entry, littleEndian: littleEndian)

            case TAG_EXTRA_SAMPLES:
                // If there are extra samples, assume alpha
                info.hasAlpha = count > 0

            default:
                break
            }

            entryOffset += 12
        }

        // Set default rows per strip if not specified
        if info.rowsPerStrip == 0 {
            info.rowsPerStrip = info.height
        }

        // Determine if has alpha from samples per pixel
        if info.samplesPerPixel == 4 && info.photometric == PHOTOMETRIC_RGB {
            info.hasAlpha = true
        } else if info.samplesPerPixel == 2 && (info.photometric == PHOTOMETRIC_BLACK_IS_ZERO || info.photometric == PHOTOMETRIC_WHITE_IS_ZERO) {
            info.hasAlpha = true
        }

        return info
    }

    private static func getEntryValue(ptr: UnsafePointer<UInt8>, dataCount: Int, entry: IFDEntry, littleEndian: Bool) -> UInt32 {
        let valueSize = typeSize(entry.type) * Int(entry.count)

        if valueSize <= 4 {
            // Value is stored in the offset field itself
            return entry.valueOffset
        } else {
            // Value is stored at the offset location
            let offset = Int(entry.valueOffset)
            guard offset >= 0 && offset < dataCount else { return 0 }

            switch entry.type {
            case 1, 2: // BYTE, ASCII
                return UInt32(ptr[offset])
            case 3: // SHORT
                return UInt32(readUInt16(ptr, offset: offset, littleEndian: littleEndian))
            case 4: // LONG
                return readUInt32(ptr, offset: offset, littleEndian: littleEndian)
            default:
                return 0
            }
        }
    }

    private static func getEntryValues(ptr: UnsafePointer<UInt8>, dataCount: Int, entry: IFDEntry, littleEndian: Bool) -> [UInt32] {
        var values: [UInt32] = []
        let count = Int(entry.count)
        let valueSize = typeSize(entry.type) * count

        if valueSize <= 4 {
            // Values stored inline in the valueOffset field
            // The valueOffset was read with readUInt32, so we need to extract values
            // considering the endianness
            let packed = entry.valueOffset

            switch entry.type {
            case 1, 2: // BYTE, ASCII
                // Bytes are stored in order regardless of endianness after readUInt32
                if littleEndian {
                    // Little-endian: bytes in order [b0, b1, b2, b3] -> packed = b0 | (b1<<8) | (b2<<16) | (b3<<24)
                    for i in 0..<count {
                        values.append((packed >> (i * 8)) & 0xFF)
                    }
                } else {
                    // Big-endian: bytes [b0, b1, b2, b3] -> packed = (b0<<24) | (b1<<16) | (b2<<8) | b3
                    // Extract in reverse order to get b0 first
                    for i in 0..<count {
                        values.append((packed >> ((3 - i) * 8)) & 0xFF)
                    }
                }

            case 3: // SHORT
                if littleEndian {
                    // Little-endian: [s1_lo, s1_hi, s2_lo, s2_hi] -> packed = s1 | (s2 << 16)
                    for i in 0..<count {
                        values.append((packed >> (i * 16)) & 0xFFFF)
                    }
                } else {
                    // Big-endian: [s1_hi, s1_lo, s2_hi, s2_lo] -> packed = (s1 << 16) | s2
                    // Extract s1 first (high 16 bits), then s2 (low 16 bits)
                    for i in 0..<count {
                        values.append((packed >> ((1 - i) * 16)) & 0xFFFF)
                    }
                }

            case 4: // LONG (only 1 can fit)
                values.append(packed)

            default:
                values.append(packed)
            }

            return values
        }

        // Values stored at external offset
        let dataOffset = Int(entry.valueOffset)

        for i in 0..<count {
            let offset = dataOffset + i * typeSize(entry.type)
            guard offset >= 0 && offset < dataCount else { break }

            switch entry.type {
            case 1, 2: // BYTE, ASCII
                values.append(UInt32(ptr[offset]))
            case 3: // SHORT
                guard offset + 1 < dataCount else { break }
                values.append(UInt32(readUInt16(ptr, offset: offset, littleEndian: littleEndian)))
            case 4: // LONG
                guard offset + 3 < dataCount else { break }
                values.append(readUInt32(ptr, offset: offset, littleEndian: littleEndian))
            default:
                break
            }
        }

        return values
    }

    private static func typeSize(_ type: UInt16) -> Int {
        switch type {
        case 1, 2: return 1  // BYTE, ASCII
        case 3: return 2     // SHORT
        case 4: return 4     // LONG
        case 5: return 8     // RATIONAL
        default: return 1
        }
    }

    // MARK: - Image Data Decoding

    private static func decodeImageData(ptr: UnsafePointer<UInt8>, dataCount: Int, info: ImageInfo, littleEndian: Bool) -> [UInt8]? {
        guard info.width > 0 && info.height > 0 else { return nil }
        guard !info.stripOffsets.isEmpty else { return nil }

        var pixels = [UInt8](repeating: 0, count: info.width * info.height * 4)

        let bitsPerSample = info.bitsPerSample.first ?? 8
        let bytesPerSample = (bitsPerSample + 7) / 8

        var rowsDecoded = 0

        for (stripIndex, stripOffset) in info.stripOffsets.enumerated() {
            let offset = Int(stripOffset)
            guard offset >= 0 && offset < dataCount else { continue }

            let byteCount: Int
            if stripIndex < info.stripByteCounts.count {
                byteCount = Int(info.stripByteCounts[stripIndex])
            } else {
                byteCount = dataCount - offset
            }

            guard offset + byteCount <= dataCount else { continue }

            // Decompress strip if needed
            var stripData: [UInt8]

            switch info.compression {
            case COMPRESSION_NONE:
                stripData = Array(UnsafeBufferPointer(start: ptr.advanced(by: offset), count: byteCount))

            case COMPRESSION_LZW:
                // Use TIFF-specific LZW decompression
                guard let decompressed = decompressTIFFLZW(ptr: ptr.advanced(by: offset), count: byteCount) else {
                    return nil
                }
                stripData = decompressed

            case COMPRESSION_PACKBITS:
                guard let decompressed = decompressPackBits(ptr: ptr.advanced(by: offset), count: byteCount) else {
                    return nil
                }
                stripData = decompressed

            default:
                // Unsupported compression
                return nil
            }

            // Convert strip data to RGBA
            let rowsInStrip = min(info.rowsPerStrip, info.height - rowsDecoded)
            let bytesPerRow = info.width * info.samplesPerPixel * bytesPerSample

            for row in 0..<rowsInStrip {
                let srcRowOffset = row * bytesPerRow
                let dstY = rowsDecoded + row

                guard srcRowOffset + bytesPerRow <= stripData.count else { break }
                guard dstY < info.height else { break }

                for x in 0..<info.width {
                    let dstIndex = (dstY * info.width + x) * 4

                    switch info.photometric {
                    case PHOTOMETRIC_RGB:
                        let srcIndex = srcRowOffset + x * info.samplesPerPixel * bytesPerSample
                        if bitsPerSample == 8 {
                            pixels[dstIndex] = stripData[srcIndex]         // R
                            pixels[dstIndex + 1] = stripData[srcIndex + 1] // G
                            pixels[dstIndex + 2] = stripData[srcIndex + 2] // B
                            pixels[dstIndex + 3] = info.samplesPerPixel >= 4 ? stripData[srcIndex + 3] : 255 // A
                        } else if bitsPerSample == 16 {
                            // For 16-bit samples, read the full 16-bit value and use high byte
                            // High byte position depends on endianness:
                            // - Little-endian: high byte is at offset+1
                            // - Big-endian: high byte is at offset+0
                            let highByteOffset = littleEndian ? 1 : 0
                            pixels[dstIndex] = stripData[srcIndex + highByteOffset]           // R
                            pixels[dstIndex + 1] = stripData[srcIndex + 2 + highByteOffset]   // G
                            pixels[dstIndex + 2] = stripData[srcIndex + 4 + highByteOffset]   // B
                            pixels[dstIndex + 3] = info.samplesPerPixel >= 4 ? stripData[srcIndex + 6 + highByteOffset] : 255 // A
                        }

                    case PHOTOMETRIC_BLACK_IS_ZERO:
                        let srcIndex = srcRowOffset + x * info.samplesPerPixel * bytesPerSample
                        let gray: UInt8
                        if bitsPerSample == 16 {
                            let highByteOffset = littleEndian ? 1 : 0
                            gray = stripData[srcIndex + highByteOffset]
                        } else {
                            gray = stripData[srcIndex]
                        }
                        pixels[dstIndex] = gray
                        pixels[dstIndex + 1] = gray
                        pixels[dstIndex + 2] = gray
                        if info.samplesPerPixel >= 2 {
                            if bitsPerSample == 16 {
                                let highByteOffset = littleEndian ? 1 : 0
                                pixels[dstIndex + 3] = stripData[srcIndex + bytesPerSample + highByteOffset]
                            } else {
                                pixels[dstIndex + 3] = stripData[srcIndex + bytesPerSample]
                            }
                        } else {
                            pixels[dstIndex + 3] = 255
                        }

                    case PHOTOMETRIC_WHITE_IS_ZERO:
                        let srcIndex = srcRowOffset + x * info.samplesPerPixel * bytesPerSample
                        let gray: UInt8
                        if bitsPerSample == 16 {
                            let highByteOffset = littleEndian ? 1 : 0
                            gray = 255 - stripData[srcIndex + highByteOffset]
                        } else {
                            gray = 255 - stripData[srcIndex]
                        }
                        pixels[dstIndex] = gray
                        pixels[dstIndex + 1] = gray
                        pixels[dstIndex + 2] = gray
                        if info.samplesPerPixel >= 2 {
                            if bitsPerSample == 16 {
                                let highByteOffset = littleEndian ? 1 : 0
                                pixels[dstIndex + 3] = stripData[srcIndex + bytesPerSample + highByteOffset]
                            } else {
                                pixels[dstIndex + 3] = stripData[srcIndex + bytesPerSample]
                            }
                        } else {
                            pixels[dstIndex + 3] = 255
                        }

                    default:
                        // Default to treating as grayscale
                        let srcIndex = srcRowOffset + x * bytesPerSample
                        if srcIndex < stripData.count {
                            let gray: UInt8
                            if bitsPerSample == 16 && srcIndex + 1 < stripData.count {
                                let highByteOffset = littleEndian ? 1 : 0
                                gray = stripData[srcIndex + highByteOffset]
                            } else {
                                gray = stripData[srcIndex]
                            }
                            pixels[dstIndex] = gray
                            pixels[dstIndex + 1] = gray
                            pixels[dstIndex + 2] = gray
                            pixels[dstIndex + 3] = 255
                        }
                    }
                }
            }

            rowsDecoded += rowsInStrip
        }

        return pixels
    }

    // MARK: - TIFF LZW Decompression

    private static func decompressTIFFLZW(ptr: UnsafePointer<UInt8>, count: Int) -> [UInt8]? {
        // TIFF LZW uses big-endian bit packing (unlike GIF)
        var output: [UInt8] = []

        let clearCode = 256
        let endCode = 257

        var codeSize = 9
        var nextCode = 258

        // Initialize dictionary with single-byte entries
        var table: [[UInt8]] = []
        for i in 0..<256 {
            table.append([UInt8(i)])
        }
        table.append([]) // clearCode
        table.append([]) // endCode

        var bitBuffer: UInt32 = 0
        var bitsInBuffer = 0
        var byteOffset = 0

        func readCode() -> Int? {
            // TIFF LZW uses big-endian bit packing
            while bitsInBuffer < codeSize {
                guard byteOffset < count else { return nil }
                bitBuffer = (bitBuffer << 8) | UInt32(ptr[byteOffset])
                byteOffset += 1
                bitsInBuffer += 8
            }

            bitsInBuffer -= codeSize
            let code = Int((bitBuffer >> bitsInBuffer) & UInt32((1 << codeSize) - 1))
            return code
        }

        var prevCode: Int? = nil

        while true {
            guard let code = readCode() else { break }

            if code == clearCode {
                // Reset
                table = []
                for i in 0..<256 {
                    table.append([UInt8(i)])
                }
                table.append([])
                table.append([])
                codeSize = 9
                nextCode = 258
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
                guard let prev = prevCode, prev < table.count else { return nil }
                entry = table[prev]
                entry.append(entry[0])
            } else {
                return nil
            }

            output.append(contentsOf: entry)

            if let prev = prevCode, prev < table.count {
                var newEntry = table[prev]
                newEntry.append(entry[0])

                if nextCode < 4096 {
                    // TIFF LZW uses "early change" - increase code size BEFORE the
                    // code that requires the new size is read
                    // Check if adding this entry will require a larger code size
                    if nextCode >= (1 << codeSize) - 1 && codeSize < 12 {
                        codeSize += 1
                    }

                    table.append(newEntry)
                    nextCode += 1
                }
            }

            prevCode = code
        }

        return output
    }

    // MARK: - PackBits Decompression

    private static func decompressPackBits(ptr: UnsafePointer<UInt8>, count: Int) -> [UInt8]? {
        var output: [UInt8] = []
        var offset = 0

        while offset < count {
            let header = Int8(bitPattern: ptr[offset])
            offset += 1

            if header >= 0 {
                // Literal run: copy next (header + 1) bytes
                let runLength = Int(header) + 1
                guard offset + runLength <= count else { break }
                for i in 0..<runLength {
                    output.append(ptr[offset + i])
                }
                offset += runLength
            } else if header > -128 {
                // Repeat run: repeat next byte (-header + 1) times
                let runLength = Int(-header) + 1
                guard offset < count else { break }
                let value = ptr[offset]
                offset += 1
                for _ in 0..<runLength {
                    output.append(value)
                }
            }
            // header == -128 is a no-op
        }

        return output
    }

    // MARK: - Helper Functions

    private static func readUInt16(_ ptr: UnsafePointer<UInt8>, offset: Int, littleEndian: Bool) -> UInt16 {
        if littleEndian {
            return UInt16(ptr[offset]) | (UInt16(ptr[offset + 1]) << 8)
        } else {
            return (UInt16(ptr[offset]) << 8) | UInt16(ptr[offset + 1])
        }
    }

    private static func readUInt32(_ ptr: UnsafePointer<UInt8>, offset: Int, littleEndian: Bool) -> UInt32 {
        if littleEndian {
            return UInt32(ptr[offset]) |
                   (UInt32(ptr[offset + 1]) << 8) |
                   (UInt32(ptr[offset + 2]) << 16) |
                   (UInt32(ptr[offset + 3]) << 24)
        } else {
            return (UInt32(ptr[offset]) << 24) |
                   (UInt32(ptr[offset + 1]) << 16) |
                   (UInt32(ptr[offset + 2]) << 8) |
                   UInt32(ptr[offset + 3])
        }
    }
}
