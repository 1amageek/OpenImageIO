// PNGDecoder.swift
// OpenImageIO
//
// PNG image format decoder

import Foundation

/// PNG image decoder
internal struct PNGDecoder {

    // MARK: - PNG Constants

    private static let PNG_SIGNATURE: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    // Color types
    private static let COLOR_TYPE_GRAYSCALE: UInt8 = 0
    private static let COLOR_TYPE_RGB: UInt8 = 2
    private static let COLOR_TYPE_INDEXED: UInt8 = 3
    private static let COLOR_TYPE_GRAYSCALE_ALPHA: UInt8 = 4
    private static let COLOR_TYPE_RGBA: UInt8 = 6

    // Filter types
    private static let FILTER_NONE: UInt8 = 0
    private static let FILTER_SUB: UInt8 = 1
    private static let FILTER_UP: UInt8 = 2
    private static let FILTER_AVERAGE: UInt8 = 3
    private static let FILTER_PAETH: UInt8 = 4

    // MARK: - Decode Result

    struct DecodeResult {
        let pixels: Data
        let width: Int
        let height: Int
        let hasAlpha: Bool
    }

    // MARK: - Public API

    /// Decode PNG data to RGBA pixels
    static func decode(data: Data) -> DecodeResult? {
        guard data.count >= 8 else { return nil }

        return data.withUnsafeBytes { buffer -> DecodeResult? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Verify PNG signature
            for i in 0..<8 {
                guard ptr[i] == PNG_SIGNATURE[i] else { return nil }
            }

            // Parse chunks
            var offset = 8
            var ihdr: IHDRChunk?
            var palette: [(r: UInt8, g: UInt8, b: UInt8)] = []
            var transparency: TransparencyInfo?
            var idatData = Data()

            while offset + 12 <= data.count {
                let length = Int(readUInt32BE(ptr, offset: offset))
                let chunkType = String(bytes: [ptr[offset + 4], ptr[offset + 5], ptr[offset + 6], ptr[offset + 7]], encoding: .ascii) ?? ""

                let chunkDataOffset = offset + 8
                guard chunkDataOffset + length <= data.count else { break }

                switch chunkType {
                case "IHDR":
                    guard length >= 13 else { return nil }
                    ihdr = parseIHDR(ptr, offset: chunkDataOffset)

                case "PLTE":
                    palette = parsePLTE(ptr, offset: chunkDataOffset, length: length)

                case "tRNS":
                    if let header = ihdr {
                        transparency = parseTRNS(ptr, offset: chunkDataOffset, length: length, colorType: header.colorType)
                    }

                case "IDAT":
                    idatData.append(Data(bytes: ptr.advanced(by: chunkDataOffset), count: length))

                case "IEND":
                    break

                default:
                    break
                }

                offset += 12 + length
            }

            guard let header = ihdr else { return nil }
            guard !idatData.isEmpty else { return nil }

            // Decompress IDAT data
            guard let decompressed = Deflate.inflate(data: idatData) else {
                return nil
            }

            // Decode image data
            guard let pixels = decodeImageData(
                data: decompressed,
                header: header,
                palette: palette,
                transparency: transparency
            ) else {
                return nil
            }

            let hasAlpha = header.colorType == COLOR_TYPE_RGBA ||
                           header.colorType == COLOR_TYPE_GRAYSCALE_ALPHA ||
                           transparency != nil

            return DecodeResult(
                pixels: Data(pixels),
                width: Int(header.width),
                height: Int(header.height),
                hasAlpha: hasAlpha
            )
        }
    }

    // MARK: - IHDR Parsing

    private struct IHDRChunk {
        let width: UInt32
        let height: UInt32
        let bitDepth: UInt8
        let colorType: UInt8
        let compressionMethod: UInt8
        let filterMethod: UInt8
        let interlaceMethod: UInt8
    }

    private static func parseIHDR(_ ptr: UnsafePointer<UInt8>, offset: Int) -> IHDRChunk {
        return IHDRChunk(
            width: readUInt32BE(ptr, offset: offset),
            height: readUInt32BE(ptr, offset: offset + 4),
            bitDepth: ptr[offset + 8],
            colorType: ptr[offset + 9],
            compressionMethod: ptr[offset + 10],
            filterMethod: ptr[offset + 11],
            interlaceMethod: ptr[offset + 12]
        )
    }

    // MARK: - PLTE Parsing

    private static func parsePLTE(_ ptr: UnsafePointer<UInt8>, offset: Int, length: Int) -> [(r: UInt8, g: UInt8, b: UInt8)] {
        var palette: [(r: UInt8, g: UInt8, b: UInt8)] = []
        let numColors = length / 3

        for i in 0..<numColors {
            let entryOffset = offset + i * 3
            palette.append((ptr[entryOffset], ptr[entryOffset + 1], ptr[entryOffset + 2]))
        }

        return palette
    }

    // MARK: - tRNS Parsing

    private enum TransparencyInfo {
        case grayscale(UInt16)
        case rgb(UInt16, UInt16, UInt16)
        case indexed([UInt8])
    }

    private static func parseTRNS(_ ptr: UnsafePointer<UInt8>, offset: Int, length: Int, colorType: UInt8) -> TransparencyInfo? {
        switch colorType {
        case COLOR_TYPE_GRAYSCALE:
            guard length >= 2 else { return nil }
            let gray = readUInt16BE(ptr, offset: offset)
            return .grayscale(gray)

        case COLOR_TYPE_RGB:
            guard length >= 6 else { return nil }
            let r = readUInt16BE(ptr, offset: offset)
            let g = readUInt16BE(ptr, offset: offset + 2)
            let b = readUInt16BE(ptr, offset: offset + 4)
            return .rgb(r, g, b)

        case COLOR_TYPE_INDEXED:
            var alphas: [UInt8] = []
            for i in 0..<length {
                alphas.append(ptr[offset + i])
            }
            return .indexed(alphas)

        default:
            return nil
        }
    }

    // MARK: - Image Data Decoding

    private static func decodeImageData(
        data: Data,
        header: IHDRChunk,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        transparency: TransparencyInfo?
    ) -> [UInt8]? {
        let width = Int(header.width)
        let height = Int(header.height)

        if header.interlaceMethod == 1 {
            return decodeInterlaced(data: data, header: header, palette: palette, transparency: transparency)
        }

        // Calculate bytes per pixel and row
        let samplesPerPixel = samplesPerPixelForColorType(header.colorType)
        let bitsPerPixel = Int(header.bitDepth) * samplesPerPixel
        let bytesPerPixel = max(1, bitsPerPixel / 8)
        let scanlineBytes = (width * bitsPerPixel + 7) / 8
        let expectedBytes = height * (1 + scanlineBytes)

        guard data.count >= expectedBytes else { return nil }

        var output = [UInt8](repeating: 0, count: width * height * 4)
        var prevRow = [UInt8](repeating: 0, count: scanlineBytes)
        var currentRow = [UInt8](repeating: 0, count: scanlineBytes)

        return data.withUnsafeBytes { buffer -> [UInt8]? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            var dataOffset = 0

            for y in 0..<height {
                guard dataOffset < data.count else { return nil }

                let filterType = ptr[dataOffset]
                dataOffset += 1

                // Read filtered row
                for x in 0..<scanlineBytes {
                    guard dataOffset < data.count else { return nil }
                    currentRow[x] = ptr[dataOffset]
                    dataOffset += 1
                }

                // Apply filter
                applyFilter(
                    filterType: filterType,
                    currentRow: &currentRow,
                    prevRow: prevRow,
                    bytesPerPixel: bytesPerPixel
                )

                // Convert to RGBA
                convertRowToRGBA(
                    row: currentRow,
                    y: y,
                    width: width,
                    header: header,
                    palette: palette,
                    transparency: transparency,
                    output: &output
                )

                // Swap rows
                swap(&prevRow, &currentRow)
            }

            return output
        }
    }

    // MARK: - Filter Application

    private static func applyFilter(
        filterType: UInt8,
        currentRow: inout [UInt8],
        prevRow: [UInt8],
        bytesPerPixel: Int
    ) {
        switch filterType {
        case FILTER_NONE:
            break

        case FILTER_SUB:
            for i in bytesPerPixel..<currentRow.count {
                currentRow[i] = currentRow[i] &+ currentRow[i - bytesPerPixel]
            }

        case FILTER_UP:
            for i in 0..<currentRow.count {
                currentRow[i] = currentRow[i] &+ prevRow[i]
            }

        case FILTER_AVERAGE:
            for i in 0..<currentRow.count {
                let a = i >= bytesPerPixel ? Int(currentRow[i - bytesPerPixel]) : 0
                let b = Int(prevRow[i])
                currentRow[i] = currentRow[i] &+ UInt8((a + b) / 2)
            }

        case FILTER_PAETH:
            for i in 0..<currentRow.count {
                let a = i >= bytesPerPixel ? Int(currentRow[i - bytesPerPixel]) : 0
                let b = Int(prevRow[i])
                let c = i >= bytesPerPixel ? Int(prevRow[i - bytesPerPixel]) : 0
                currentRow[i] = currentRow[i] &+ UInt8(paethPredictor(a: a, b: b, c: c))
            }

        default:
            break
        }
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

    // MARK: - RGBA Conversion

    private static func convertRowToRGBA(
        row: [UInt8],
        y: Int,
        width: Int,
        header: IHDRChunk,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        transparency: TransparencyInfo?,
        output: inout [UInt8]
    ) {
        let bitDepth = Int(header.bitDepth)

        switch header.colorType {
        case COLOR_TYPE_GRAYSCALE:
            convertGrayscaleRow(row: row, y: y, width: width, bitDepth: bitDepth, transparency: transparency, output: &output)

        case COLOR_TYPE_RGB:
            convertRGBRow(row: row, y: y, width: width, bitDepth: bitDepth, transparency: transparency, output: &output)

        case COLOR_TYPE_INDEXED:
            convertIndexedRow(row: row, y: y, width: width, bitDepth: bitDepth, palette: palette, transparency: transparency, output: &output)

        case COLOR_TYPE_GRAYSCALE_ALPHA:
            convertGrayscaleAlphaRow(row: row, y: y, width: width, bitDepth: bitDepth, output: &output)

        case COLOR_TYPE_RGBA:
            convertRGBARow(row: row, y: y, width: width, bitDepth: bitDepth, output: &output)

        default:
            break
        }
    }

    private static func convertGrayscaleRow(
        row: [UInt8],
        y: Int,
        width: Int,
        bitDepth: Int,
        transparency: TransparencyInfo?,
        output: inout [UInt8]
    ) {
        let transparentGray: UInt16?
        if case .grayscale(let g) = transparency {
            transparentGray = g
        } else {
            transparentGray = nil
        }

        for x in 0..<width {
            let gray: UInt8
            let grayValue: Int

            switch bitDepth {
            case 1:
                let byteIndex = x / 8
                let bitIndex = 7 - (x % 8)
                grayValue = Int((row[byteIndex] >> bitIndex) & 0x01)
                gray = grayValue == 0 ? 0 : 255

            case 2:
                let byteIndex = x / 4
                let bitIndex = 6 - (x % 4) * 2
                grayValue = Int((row[byteIndex] >> bitIndex) & 0x03)
                gray = UInt8(grayValue * 85)

            case 4:
                let byteIndex = x / 2
                let bitIndex = 4 - (x % 2) * 4
                grayValue = Int((row[byteIndex] >> bitIndex) & 0x0F)
                gray = UInt8(grayValue * 17)

            case 8:
                grayValue = Int(row[x])
                gray = row[x]

            case 16:
                let byteIndex = x * 2
                grayValue = (Int(row[byteIndex]) << 8) | Int(row[byteIndex + 1])
                gray = row[byteIndex] // Use high byte

            default:
                grayValue = 0
                gray = 0
            }

            let outputIndex = (y * width + x) * 4
            output[outputIndex] = gray
            output[outputIndex + 1] = gray
            output[outputIndex + 2] = gray

            if let tg = transparentGray, grayValue == Int(tg) {
                output[outputIndex + 3] = 0
            } else {
                output[outputIndex + 3] = 255
            }
        }
    }

    private static func convertRGBRow(
        row: [UInt8],
        y: Int,
        width: Int,
        bitDepth: Int,
        transparency: TransparencyInfo?,
        output: inout [UInt8]
    ) {
        let transparentRGB: (UInt16, UInt16, UInt16)?
        if case .rgb(let r, let g, let b) = transparency {
            transparentRGB = (r, g, b)
        } else {
            transparentRGB = nil
        }

        for x in 0..<width {
            let r: UInt8, g: UInt8, b: UInt8
            let rv: Int, gv: Int, bv: Int

            switch bitDepth {
            case 8:
                let index = x * 3
                r = row[index]
                g = row[index + 1]
                b = row[index + 2]
                rv = Int(r)
                gv = Int(g)
                bv = Int(b)

            case 16:
                let index = x * 6
                rv = (Int(row[index]) << 8) | Int(row[index + 1])
                gv = (Int(row[index + 2]) << 8) | Int(row[index + 3])
                bv = (Int(row[index + 4]) << 8) | Int(row[index + 5])
                r = row[index]
                g = row[index + 2]
                b = row[index + 4]

            default:
                r = 0; g = 0; b = 0
                rv = 0; gv = 0; bv = 0
            }

            let outputIndex = (y * width + x) * 4
            output[outputIndex] = r
            output[outputIndex + 1] = g
            output[outputIndex + 2] = b

            if let (tr, tg, tb) = transparentRGB,
               rv == Int(tr) && gv == Int(tg) && bv == Int(tb) {
                output[outputIndex + 3] = 0
            } else {
                output[outputIndex + 3] = 255
            }
        }
    }

    private static func convertIndexedRow(
        row: [UInt8],
        y: Int,
        width: Int,
        bitDepth: Int,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        transparency: TransparencyInfo?,
        output: inout [UInt8]
    ) {
        let alphas: [UInt8]?
        if case .indexed(let a) = transparency {
            alphas = a
        } else {
            alphas = nil
        }

        for x in 0..<width {
            let index: Int

            switch bitDepth {
            case 1:
                let byteIndex = x / 8
                let bitIndex = 7 - (x % 8)
                index = Int((row[byteIndex] >> bitIndex) & 0x01)

            case 2:
                let byteIndex = x / 4
                let bitIndex = 6 - (x % 4) * 2
                index = Int((row[byteIndex] >> bitIndex) & 0x03)

            case 4:
                let byteIndex = x / 2
                let bitIndex = 4 - (x % 2) * 4
                index = Int((row[byteIndex] >> bitIndex) & 0x0F)

            case 8:
                index = Int(row[x])

            default:
                index = 0
            }

            let outputIndex = (y * width + x) * 4

            if index < palette.count {
                let color = palette[index]
                output[outputIndex] = color.r
                output[outputIndex + 1] = color.g
                output[outputIndex + 2] = color.b
            }

            if let a = alphas, index < a.count {
                output[outputIndex + 3] = a[index]
            } else {
                output[outputIndex + 3] = 255
            }
        }
    }

    private static func convertGrayscaleAlphaRow(
        row: [UInt8],
        y: Int,
        width: Int,
        bitDepth: Int,
        output: inout [UInt8]
    ) {
        for x in 0..<width {
            let gray: UInt8, alpha: UInt8

            switch bitDepth {
            case 8:
                let index = x * 2
                gray = row[index]
                alpha = row[index + 1]

            case 16:
                let index = x * 4
                gray = row[index]
                alpha = row[index + 2]

            default:
                gray = 0
                alpha = 255
            }

            let outputIndex = (y * width + x) * 4
            output[outputIndex] = gray
            output[outputIndex + 1] = gray
            output[outputIndex + 2] = gray
            output[outputIndex + 3] = alpha
        }
    }

    private static func convertRGBARow(
        row: [UInt8],
        y: Int,
        width: Int,
        bitDepth: Int,
        output: inout [UInt8]
    ) {
        for x in 0..<width {
            let outputIndex = (y * width + x) * 4

            switch bitDepth {
            case 8:
                let index = x * 4
                output[outputIndex] = row[index]
                output[outputIndex + 1] = row[index + 1]
                output[outputIndex + 2] = row[index + 2]
                output[outputIndex + 3] = row[index + 3]

            case 16:
                let index = x * 8
                output[outputIndex] = row[index]
                output[outputIndex + 1] = row[index + 2]
                output[outputIndex + 2] = row[index + 4]
                output[outputIndex + 3] = row[index + 6]

            default:
                break
            }
        }
    }

    // MARK: - Interlaced Decoding (Adam7)

    private static func decodeInterlaced(
        data: Data,
        header: IHDRChunk,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        transparency: TransparencyInfo?
    ) -> [UInt8]? {
        let width = Int(header.width)
        let height = Int(header.height)

        var output = [UInt8](repeating: 0, count: width * height * 4)

        // Adam7 interlace pattern
        let startingRow = [0, 0, 4, 0, 2, 0, 1]
        let startingCol = [0, 4, 0, 2, 0, 1, 0]
        let rowIncrement = [8, 8, 8, 4, 4, 2, 2]
        let colIncrement = [8, 8, 4, 4, 2, 2, 1]

        let samplesPerPixel = samplesPerPixelForColorType(header.colorType)
        let bitsPerPixel = Int(header.bitDepth) * samplesPerPixel
        let bytesPerPixel = max(1, bitsPerPixel / 8)

        return data.withUnsafeBytes { buffer -> [UInt8]? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            var dataOffset = 0

            for pass in 0..<7 {
                let passWidth = (width - startingCol[pass] + colIncrement[pass] - 1) / colIncrement[pass]
                let passHeight = (height - startingRow[pass] + rowIncrement[pass] - 1) / rowIncrement[pass]

                guard passWidth > 0 && passHeight > 0 else { continue }

                let scanlineBytes = (passWidth * bitsPerPixel + 7) / 8
                var prevRow = [UInt8](repeating: 0, count: scanlineBytes)
                var currentRow = [UInt8](repeating: 0, count: scanlineBytes)

                for passY in 0..<passHeight {
                    guard dataOffset < data.count else { return nil }

                    let filterType = ptr[dataOffset]
                    dataOffset += 1

                    for i in 0..<scanlineBytes {
                        guard dataOffset < data.count else { return nil }
                        currentRow[i] = ptr[dataOffset]
                        dataOffset += 1
                    }

                    applyFilter(
                        filterType: filterType,
                        currentRow: &currentRow,
                        prevRow: prevRow,
                        bytesPerPixel: bytesPerPixel
                    )

                    // Map to final image
                    let y = startingRow[pass] + passY * rowIncrement[pass]

                    for passX in 0..<passWidth {
                        let x = startingCol[pass] + passX * colIncrement[pass]
                        let outputIndex = (y * width + x) * 4

                        // Extract pixel from currentRow at passX
                        let pixelRGBA = extractPixel(
                            row: currentRow,
                            x: passX,
                            header: header,
                            palette: palette,
                            transparency: transparency
                        )

                        output[outputIndex] = pixelRGBA.r
                        output[outputIndex + 1] = pixelRGBA.g
                        output[outputIndex + 2] = pixelRGBA.b
                        output[outputIndex + 3] = pixelRGBA.a
                    }

                    swap(&prevRow, &currentRow)
                }
            }

            return output
        }
    }

    private static func extractPixel(
        row: [UInt8],
        x: Int,
        header: IHDRChunk,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        transparency: TransparencyInfo?
    ) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let bitDepth = Int(header.bitDepth)

        switch header.colorType {
        case COLOR_TYPE_GRAYSCALE:
            let gray = extractGray(row: row, x: x, bitDepth: bitDepth)
            var alpha: UInt8 = 255
            if case .grayscale(let tg) = transparency {
                let grayValue = bitDepth < 8 ? Int(gray) : Int(gray) * 256 / 255
                if grayValue == Int(tg) { alpha = 0 }
            }
            return (gray, gray, gray, alpha)

        case COLOR_TYPE_RGB:
            let (r, g, b) = extractRGB(row: row, x: x, bitDepth: bitDepth)
            var alpha: UInt8 = 255
            if case .rgb(let tr, let tg, let tb) = transparency {
                let rv = bitDepth == 16 ? (Int(r) << 8) : Int(r)
                let gv = bitDepth == 16 ? (Int(g) << 8) : Int(g)
                let bv = bitDepth == 16 ? (Int(b) << 8) : Int(b)
                if rv == Int(tr) && gv == Int(tg) && bv == Int(tb) { alpha = 0 }
            }
            return (r, g, b, alpha)

        case COLOR_TYPE_INDEXED:
            let index = extractIndex(row: row, x: x, bitDepth: bitDepth)
            var r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0, a: UInt8 = 255
            if index < palette.count {
                let color = palette[index]
                r = color.r; g = color.g; b = color.b
            }
            if case .indexed(let alphas) = transparency, index < alphas.count {
                a = alphas[index]
            }
            return (r, g, b, a)

        case COLOR_TYPE_GRAYSCALE_ALPHA:
            let (gray, alpha) = extractGrayAlpha(row: row, x: x, bitDepth: bitDepth)
            return (gray, gray, gray, alpha)

        case COLOR_TYPE_RGBA:
            return extractRGBA(row: row, x: x, bitDepth: bitDepth)

        default:
            return (0, 0, 0, 255)
        }
    }

    private static func extractGray(row: [UInt8], x: Int, bitDepth: Int) -> UInt8 {
        switch bitDepth {
        case 1:
            let byteIndex = x / 8
            let bitIndex = 7 - (x % 8)
            return ((row[byteIndex] >> bitIndex) & 0x01) == 0 ? 0 : 255
        case 2:
            let byteIndex = x / 4
            let bitIndex = 6 - (x % 4) * 2
            return UInt8(Int((row[byteIndex] >> bitIndex) & 0x03) * 85)
        case 4:
            let byteIndex = x / 2
            let bitIndex = 4 - (x % 2) * 4
            return UInt8(Int((row[byteIndex] >> bitIndex) & 0x0F) * 17)
        case 8:
            return row[x]
        case 16:
            return row[x * 2]
        default:
            return 0
        }
    }

    private static func extractRGB(row: [UInt8], x: Int, bitDepth: Int) -> (UInt8, UInt8, UInt8) {
        switch bitDepth {
        case 8:
            let index = x * 3
            return (row[index], row[index + 1], row[index + 2])
        case 16:
            let index = x * 6
            return (row[index], row[index + 2], row[index + 4])
        default:
            return (0, 0, 0)
        }
    }

    private static func extractIndex(row: [UInt8], x: Int, bitDepth: Int) -> Int {
        switch bitDepth {
        case 1:
            let byteIndex = x / 8
            let bitIndex = 7 - (x % 8)
            return Int((row[byteIndex] >> bitIndex) & 0x01)
        case 2:
            let byteIndex = x / 4
            let bitIndex = 6 - (x % 4) * 2
            return Int((row[byteIndex] >> bitIndex) & 0x03)
        case 4:
            let byteIndex = x / 2
            let bitIndex = 4 - (x % 2) * 4
            return Int((row[byteIndex] >> bitIndex) & 0x0F)
        case 8:
            return Int(row[x])
        default:
            return 0
        }
    }

    private static func extractGrayAlpha(row: [UInt8], x: Int, bitDepth: Int) -> (UInt8, UInt8) {
        switch bitDepth {
        case 8:
            let index = x * 2
            return (row[index], row[index + 1])
        case 16:
            let index = x * 4
            return (row[index], row[index + 2])
        default:
            return (0, 255)
        }
    }

    private static func extractRGBA(row: [UInt8], x: Int, bitDepth: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        switch bitDepth {
        case 8:
            let index = x * 4
            return (row[index], row[index + 1], row[index + 2], row[index + 3])
        case 16:
            let index = x * 8
            return (row[index], row[index + 2], row[index + 4], row[index + 6])
        default:
            return (0, 0, 0, 255)
        }
    }

    // MARK: - Helper Functions

    private static func samplesPerPixelForColorType(_ colorType: UInt8) -> Int {
        switch colorType {
        case COLOR_TYPE_GRAYSCALE: return 1
        case COLOR_TYPE_RGB: return 3
        case COLOR_TYPE_INDEXED: return 1
        case COLOR_TYPE_GRAYSCALE_ALPHA: return 2
        case COLOR_TYPE_RGBA: return 4
        default: return 1
        }
    }

    private static func readUInt32BE(_ ptr: UnsafePointer<UInt8>, offset: Int) -> UInt32 {
        return (UInt32(ptr[offset]) << 24) |
               (UInt32(ptr[offset + 1]) << 16) |
               (UInt32(ptr[offset + 2]) << 8) |
               UInt32(ptr[offset + 3])
    }

    private static func readUInt16BE(_ ptr: UnsafePointer<UInt8>, offset: Int) -> UInt16 {
        return (UInt16(ptr[offset]) << 8) | UInt16(ptr[offset + 1])
    }
}
