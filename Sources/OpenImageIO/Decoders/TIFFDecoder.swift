// TIFFDecoder.swift
// OpenImageIO
//
// TIFF image format decoder (basic support)

import OpenFoundation

/// TIFF image decoder supporting basic uncompressed and LZW-compressed TIFF
internal struct TIFFDecoder {

    private static let maximumDecodedByteCount = 512 * 1024 * 1024

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
    private static let TAG_PREDICTOR: UInt16 = 317
    private static let TAG_EXTRA_SAMPLES: UInt16 = 338

    // Predictor values (TIFF 6.0 / TIFF Technical Note 3)
    private static let PREDICTOR_NONE: UInt16 = 1
    private static let PREDICTOR_HORIZONTAL: UInt16 = 2
    // PREDICTOR_FLOATING_POINT (3) is deliberately not implemented.

    // Compression types
    private static let COMPRESSION_NONE: UInt16 = 1
    private static let COMPRESSION_LZW: UInt16 = 5
    private static let COMPRESSION_PACKBITS: UInt16 = 32773

    // Photometric interpretation
    private static let PHOTOMETRIC_WHITE_IS_ZERO: UInt16 = 0
    private static let PHOTOMETRIC_BLACK_IS_ZERO: UInt16 = 1
    private static let PHOTOMETRIC_RGB: UInt16 = 2
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
        /// Predictor tag (317). 1 = no predictor (default), 2 = horizontal
        /// differencing. Floating-point predictor (3) is not implemented.
        var predictor: UInt16 = 1
    }

    // MARK: - Public API

    /// Decode TIFF data to RGBA pixels. Multi-page TIFFs are supported via
    /// `frameIndex:` (0-based), matching the pattern used by GIFDecoder.
    static func decode(data: Data, frameIndex: Int = 0) -> DecodeResult? {
        guard data.count >= 8 else { return nil }
        guard frameIndex >= 0 else { return nil }

        return data.withUnsafeBytes { buffer -> DecodeResult? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            guard let endianness = readHeader(ptr: ptr, dataCount: data.count) else {
                return nil
            }
            let isLittleEndian = endianness.isLittleEndian
            let firstIFDOffset = endianness.firstIFDOffset

            // Walk the IFD chain to locate the requested page. Each IFD ends
            // with a 4-byte `nextIFDOffset`; 0 terminates the chain.
            guard let ifdOffset = locateIFD(
                ptr: ptr,
                dataCount: data.count,
                firstIFDOffset: firstIFDOffset,
                targetIndex: frameIndex,
                littleEndian: isLittleEndian
            ) else { return nil }

            guard let info = parseIFD(ptr: ptr, dataCount: data.count, offset: ifdOffset, littleEndian: isLittleEndian) else {
                return nil
            }

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

    /// Returns the number of pages (IFDs) in the TIFF container, or 0 if the
    /// container is malformed.
    static func pageCount(data: Data) -> Int {
        guard data.count >= 8 else { return 0 }

        return data.withUnsafeBytes { buffer -> Int in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            guard let endianness = readHeader(ptr: ptr, dataCount: data.count) else {
                return 0
            }

            var count = 0
            var offset = endianness.firstIFDOffset
            var visited: Set<Int> = []

            while offset != 0 {
                guard offset > 0,
                      offset <= data.count - 2,
                      !visited.contains(offset) else {
                    return 0
                }
                visited.insert(offset)
                let numEntries = Int(readUInt16(ptr, offset: offset, littleEndian: endianness.isLittleEndian))
                let entriesByteCount = numEntries * 12
                guard entriesByteCount <= data.count - offset - 2 else { return 0 }
                let nextOffsetPos = offset + 2 + entriesByteCount
                guard nextOffsetPos <= data.count - 4 else { return 0 }
                count += 1
                let nextOffset = readUInt32(
                    ptr,
                    offset: nextOffsetPos,
                    littleEndian: endianness.isLittleEndian
                )
                guard let convertedOffset = exactInt(nextOffset) else { return 0 }
                offset = convertedOffset
            }
            return count
        }
    }

    // MARK: - Header & IFD Chain

    private struct TIFFHeader {
        let isLittleEndian: Bool
        let firstIFDOffset: Int
    }

    private static func readHeader(ptr: UnsafePointer<UInt8>, dataCount: Int) -> TIFFHeader? {
        guard dataCount >= 8 else { return nil }

        let byteOrder = UInt16(ptr[0]) | (UInt16(ptr[1]) << 8)
        let isLittleEndian: Bool
        if byteOrder == LITTLE_ENDIAN_MARKER {
            isLittleEndian = true
        } else if byteOrder == BIG_ENDIAN_MARKER {
            isLittleEndian = false
        } else {
            return nil
        }

        let magic = readUInt16(ptr, offset: 2, littleEndian: isLittleEndian)
        guard magic == TIFF_MAGIC else { return nil }

        let rawFirstIFDOffset = readUInt32(ptr, offset: 4, littleEndian: isLittleEndian)
        guard let firstIFDOffset = exactInt(rawFirstIFDOffset),
              firstIFDOffset > 0,
              firstIFDOffset <= dataCount - 2 else {
            return nil
        }

        return TIFFHeader(isLittleEndian: isLittleEndian, firstIFDOffset: firstIFDOffset)
    }

    /// Walks the IFD chain to find the byte offset of the Nth IFD (0-based).
    /// Returns nil if the chain is shorter than `targetIndex + 1`.
    private static func locateIFD(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        firstIFDOffset: Int,
        targetIndex: Int,
        littleEndian: Bool
    ) -> Int? {
        var offset = firstIFDOffset
        var visited: Set<Int> = []
        for index in 0...targetIndex {
            guard offset > 0 && offset <= dataCount - 2 else { return nil }
            if visited.contains(offset) { return nil }
            visited.insert(offset)
            if index == targetIndex { return offset }

            let numEntries = Int(readUInt16(ptr, offset: offset, littleEndian: littleEndian))
            let entriesByteCount = numEntries * 12
            guard entriesByteCount <= dataCount - offset - 2 else { return nil }
            let nextOffsetPos = offset + 2 + entriesByteCount
            guard nextOffsetPos <= dataCount - 4 else { return nil }
            let rawNextOffset = readUInt32(ptr, offset: nextOffsetPos, littleEndian: littleEndian)
            guard let nextOffset = exactInt(rawNextOffset) else { return nil }
            offset = nextOffset
        }
        return nil
    }

    // MARK: - IFD Parsing

    private static func parseIFD(ptr: UnsafePointer<UInt8>, dataCount: Int, offset: Int, littleEndian: Bool) -> ImageInfo? {
        guard offset >= 0, offset <= dataCount - 2 else { return nil }

        let numEntries = Int(readUInt16(ptr, offset: offset, littleEndian: littleEndian))
        var info = ImageInfo()

        var entryOffset = offset + 2

        for _ in 0..<numEntries {
            guard entryOffset <= dataCount - 12 else { return nil }

            let tag = readUInt16(ptr, offset: entryOffset, littleEndian: littleEndian)
            let type = readUInt16(ptr, offset: entryOffset + 2, littleEndian: littleEndian)
            let count = readUInt32(ptr, offset: entryOffset + 4, littleEndian: littleEndian)
            let valueOffset = readUInt32(ptr, offset: entryOffset + 8, littleEndian: littleEndian)

            let entry = IFDEntry(tag: tag, type: type, count: count, valueOffset: valueOffset)

            switch tag {
            case TAG_IMAGE_WIDTH:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = exactInt(rawValue) else { return nil }
                info.width = value

            case TAG_IMAGE_LENGTH:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = exactInt(rawValue) else { return nil }
                info.height = value

            case TAG_BITS_PER_SAMPLE:
                guard let rawValues = getEntryValues(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ) else { return nil }
                var values: [Int] = []
                values.reserveCapacity(rawValues.count)
                for rawValue in rawValues {
                    guard let value = exactInt(rawValue) else { return nil }
                    values.append(value)
                }
                info.bitsPerSample = values

            case TAG_COMPRESSION:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = UInt16(exactly: rawValue) else { return nil }
                info.compression = value

            case TAG_PHOTOMETRIC:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = UInt16(exactly: rawValue) else { return nil }
                info.photometric = value

            case TAG_STRIP_OFFSETS:
                guard let values = getEntryValues(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ) else { return nil }
                info.stripOffsets = values

            case TAG_SAMPLES_PER_PIXEL:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = exactInt(rawValue) else { return nil }
                info.samplesPerPixel = value

            case TAG_ROWS_PER_STRIP:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = exactInt(rawValue) else { return nil }
                info.rowsPerStrip = value

            case TAG_STRIP_BYTE_COUNTS:
                guard let values = getEntryValues(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ) else { return nil }
                info.stripByteCounts = values

            case TAG_EXTRA_SAMPLES:
                guard let values = getEntryValues(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ) else { return nil }
                info.hasAlpha = !values.isEmpty

            case TAG_PREDICTOR:
                guard let rawValue = getEntryValue(
                    ptr: ptr,
                    dataCount: dataCount,
                    entry: entry,
                    littleEndian: littleEndian
                ), let value = UInt16(exactly: rawValue) else { return nil }
                info.predictor = value

            default:
                break
            }

            entryOffset += 12
        }

        // Set default rows per strip if not specified
        if info.rowsPerStrip == 0 {
            info.rowsPerStrip = info.height
        }

        guard info.width > 0,
              info.height > 0,
              info.samplesPerPixel > 0,
              info.rowsPerStrip > 0,
              !info.stripOffsets.isEmpty,
              info.stripByteCounts.count == info.stripOffsets.count,
              info.bitsPerSample.count == 1 || info.bitsPerSample.count == info.samplesPerPixel,
              info.bitsPerSample.allSatisfy({ $0 == 8 || $0 == 16 }),
              info.bitsPerSample.allSatisfy({ $0 == info.bitsPerSample[0] }),
              [COMPRESSION_NONE, COMPRESSION_LZW, COMPRESSION_PACKBITS].contains(info.compression),
              [PHOTOMETRIC_WHITE_IS_ZERO, PHOTOMETRIC_BLACK_IS_ZERO, PHOTOMETRIC_RGB].contains(info.photometric),
              [PREDICTOR_NONE, PREDICTOR_HORIZONTAL].contains(info.predictor) else {
            return nil
        }

        if info.photometric == PHOTOMETRIC_RGB {
            guard info.samplesPerPixel == 3 || info.samplesPerPixel == 4 else { return nil }
        } else {
            guard info.samplesPerPixel == 1 || info.samplesPerPixel == 2 else { return nil }
        }

        // Determine if has alpha from samples per pixel
        if info.samplesPerPixel == 4 && info.photometric == PHOTOMETRIC_RGB {
            info.hasAlpha = true
        } else if info.samplesPerPixel == 2 && (info.photometric == PHOTOMETRIC_BLACK_IS_ZERO || info.photometric == PHOTOMETRIC_WHITE_IS_ZERO) {
            info.hasAlpha = true
        }

        return info
    }

    private static func getEntryValue(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        entry: IFDEntry,
        littleEndian: Bool
    ) -> UInt32? {
        getEntryValues(
            ptr: ptr,
            dataCount: dataCount,
            entry: entry,
            littleEndian: littleEndian
        )?.first
    }

    private static func getEntryValues(
        ptr: UnsafePointer<UInt8>,
        dataCount: Int,
        entry: IFDEntry,
        littleEndian: Bool
    ) -> [UInt32]? {
        var values: [UInt32] = []
        guard let count = exactInt(entry.count),
              count > 0,
              let elementSize = typeSize(entry.type) else {
            return nil
        }
        let (valueSize, valueSizeOverflow) = elementSize.multipliedReportingOverflow(by: count)
        guard !valueSizeOverflow else { return nil }

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
        guard let dataOffset = exactInt(entry.valueOffset),
              dataOffset >= 0,
              valueSize <= dataCount,
              dataOffset <= dataCount - valueSize else {
            return nil
        }
        values.reserveCapacity(count)

        for i in 0..<count {
            let offset = dataOffset + i * elementSize

            switch entry.type {
            case 1, 2: // BYTE, ASCII
                values.append(UInt32(ptr[offset]))
            case 3: // SHORT
                values.append(UInt32(readUInt16(ptr, offset: offset, littleEndian: littleEndian)))
            case 4: // LONG
                values.append(readUInt32(ptr, offset: offset, littleEndian: littleEndian))
            default:
                return nil
            }
        }

        return values
    }

    private static func typeSize(_ type: UInt16) -> Int? {
        switch type {
        case 1, 2: return 1  // BYTE, ASCII
        case 3: return 2     // SHORT
        case 4: return 4     // LONG
        default: return nil
        }
    }

    // MARK: - Image Data Decoding

    private static func decodeImageData(ptr: UnsafePointer<UInt8>, dataCount: Int, info: ImageInfo, littleEndian: Bool) -> [UInt8]? {
        guard info.width > 0 && info.height > 0 else { return nil }
        guard !info.stripOffsets.isEmpty else { return nil }

        let (pixelCount, pixelCountOverflow) = info.width.multipliedReportingOverflow(by: info.height)
        let (decodedByteCount, decodedByteCountOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !pixelCountOverflow,
              !decodedByteCountOverflow,
              decodedByteCount <= maximumDecodedByteCount else {
            return nil
        }
        var pixels = [UInt8](repeating: 0, count: decodedByteCount)

        let bitsPerSample = info.bitsPerSample.first ?? 8
        let bytesPerSample = (bitsPerSample + 7) / 8
        let (samplesPerRow, samplesPerRowOverflow) = info.width.multipliedReportingOverflow(
            by: info.samplesPerPixel
        )
        let (bytesPerRow, bytesPerRowOverflow) = samplesPerRow.multipliedReportingOverflow(
            by: bytesPerSample
        )
        guard !samplesPerRowOverflow, !bytesPerRowOverflow else { return nil }

        var rowsDecoded = 0

        for (stripIndex, stripOffset) in info.stripOffsets.enumerated() {
            guard rowsDecoded < info.height,
                  let offset = exactInt(stripOffset),
                  let byteCount = exactInt(info.stripByteCounts[stripIndex]),
                  byteCount > 0,
                  offset >= 0,
                  byteCount <= dataCount,
                  offset <= dataCount - byteCount else {
                return nil
            }

            let rowsInStrip = min(info.rowsPerStrip, info.height - rowsDecoded)
            let (requiredStripByteCount, requiredStripByteCountOverflow) = bytesPerRow
                .multipliedReportingOverflow(by: rowsInStrip)
            guard !requiredStripByteCountOverflow,
                  requiredStripByteCount <= maximumDecodedByteCount else {
                return nil
            }

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

            guard stripData.count >= requiredStripByteCount else { return nil }

            // Apply predictor (TIFF tag 317) BEFORE sample conversion.
            // Predictor operates on each scanline independently, component-wise.
            if info.predictor == PREDICTOR_HORIZONTAL {
                applyHorizontalPredictor(
                    stripData: &stripData,
                    rows: rowsInStrip,
                    width: info.width,
                    samplesPerPixel: info.samplesPerPixel,
                    bitsPerSample: bitsPerSample,
                    littleEndian: littleEndian
                )
            }

            // Convert strip data to RGBA
            for row in 0..<rowsInStrip {
                let srcRowOffset = row * bytesPerRow
                let dstY = rowsDecoded + row

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

        return rowsDecoded == info.height ? pixels : nil
    }

    // MARK: - Horizontal Predictor (TIFF tag 317, value 2)

    /// Reverses horizontal differencing encoded by the TIFF horizontal
    /// predictor. For each row, each sample is the sum of all preceding
    /// samples of the same channel in that row (wrapping modulo 2^bits).
    /// Operates in-place on the decompressed strip before RGBA conversion.
    private static func applyHorizontalPredictor(
        stripData: inout [UInt8],
        rows: Int,
        width: Int,
        samplesPerPixel: Int,
        bitsPerSample: Int,
        littleEndian: Bool
    ) {
        let bytesPerSample = (bitsPerSample + 7) / 8
        let bytesPerRow = width * samplesPerPixel * bytesPerSample

        for row in 0..<rows {
            let rowStart = row * bytesPerRow
            guard rowStart + bytesPerRow <= stripData.count else { return }

            switch bitsPerSample {
            case 8:
                // 8-bit: each byte is an independent sample. Start at the
                // second pixel (x=1) and accumulate per-channel.
                for x in 1..<width {
                    for s in 0..<samplesPerPixel {
                        let idx = rowStart + x * samplesPerPixel + s
                        let prevIdx = rowStart + (x - 1) * samplesPerPixel + s
                        stripData[idx] = stripData[idx] &+ stripData[prevIdx]
                    }
                }
            case 16:
                // 16-bit: accumulate per-sample with native endianness.
                for x in 1..<width {
                    for s in 0..<samplesPerPixel {
                        let base = rowStart + x * samplesPerPixel * 2 + s * 2
                        let prevBase = rowStart + (x - 1) * samplesPerPixel * 2 + s * 2
                        let loOffset = littleEndian ? 0 : 1
                        let hiOffset = littleEndian ? 1 : 0
                        let cur = UInt16(stripData[base + loOffset]) | (UInt16(stripData[base + hiOffset]) << 8)
                        let prev = UInt16(stripData[prevBase + loOffset]) | (UInt16(stripData[prevBase + hiOffset]) << 8)
                        let sum = cur &+ prev
                        stripData[base + loOffset] = UInt8(sum & 0xFF)
                        stripData[base + hiOffset] = UInt8((sum >> 8) & 0xFF)
                    }
                }
            default:
                // Non-byte-aligned bit depths are not supported by this decoder.
                return
            }
        }
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

    private static func exactInt(_ value: UInt32) -> Int? {
        guard UInt64(value) <= UInt64(Int.max) else { return nil }
        return Int(value)
    }

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
