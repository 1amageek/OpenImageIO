// GIFDecoder.swift
// OpenImageIO
//
// GIF image format decoder with full animation support

import Foundation

/// GIF image decoder with full animation support
internal struct GIFDecoder {

    // MARK: - GIF Constants

    private static let GIF_SIGNATURE_87A: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61] // "GIF87a"
    private static let GIF_SIGNATURE_89A: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] // "GIF89a"

    // Block types
    private static let IMAGE_SEPARATOR: UInt8 = 0x2C
    private static let EXTENSION_INTRODUCER: UInt8 = 0x21
    private static let TRAILER: UInt8 = 0x3B

    // Extension labels
    private static let GRAPHIC_CONTROL_EXTENSION: UInt8 = 0xF9
    private static let APPLICATION_EXTENSION: UInt8 = 0xFF
    private static let COMMENT_EXTENSION: UInt8 = 0xFE
    private static let PLAIN_TEXT_EXTENSION: UInt8 = 0x01

    // Dispose methods
    private static let DISPOSE_NONE: UInt8 = 0
    private static let DISPOSE_DO_NOT_DISPOSE: UInt8 = 1
    private static let DISPOSE_RESTORE_BACKGROUND: UInt8 = 2
    private static let DISPOSE_RESTORE_PREVIOUS: UInt8 = 3

    // MARK: - Decode Result

    struct DecodeResult {
        let pixels: Data
        let width: Int
        let height: Int
        let hasAlpha: Bool
    }

    // MARK: - Frame Info

    struct FrameInfo {
        let delay: Double // seconds
        let disposeMethod: UInt8
        let transparentColorIndex: Int?
        let left: Int
        let top: Int
        let width: Int
        let height: Int
        let localColorTable: [(r: UInt8, g: UInt8, b: UInt8)]?
        let interlaced: Bool
        let imageDataOffset: Int
        let imageDataLength: Int
    }

    // MARK: - GIF Info

    struct GIFInfo {
        let width: Int
        let height: Int
        let globalColorTable: [(r: UInt8, g: UInt8, b: UInt8)]
        let backgroundColorIndex: Int
        let frames: [FrameInfo]
    }

    // MARK: - Public API

    /// Parse GIF to extract frame count
    static func frameCount(data: Data) -> Int {
        guard let info = parseGIF(data: data) else { return 0 }
        return info.frames.count
    }

    /// Get frame delay in seconds
    static func frameDelay(data: Data, frameIndex: Int) -> Double {
        guard let info = parseGIF(data: data),
              frameIndex >= 0 && frameIndex < info.frames.count else {
            return 0.1 // Default
        }
        return info.frames[frameIndex].delay
    }

    /// Decode a specific frame
    static func decode(data: Data, frameIndex: Int = 0) -> DecodeResult? {
        guard let info = parseGIF(data: data) else { return nil }
        guard frameIndex >= 0 && frameIndex < info.frames.count else { return nil }

        // Decode all frames up to and including the requested frame
        var canvas = [UInt8](repeating: 0, count: info.width * info.height * 4)
        var previousCanvas: [UInt8]? = nil

        for i in 0...frameIndex {
            let frame = info.frames[i]

            // Save previous canvas for DISPOSE_RESTORE_PREVIOUS
            if frame.disposeMethod == DISPOSE_RESTORE_PREVIOUS {
                previousCanvas = canvas
            }

            // Decode frame
            guard let framePixels = decodeFrame(data: data, info: info, frame: frame) else {
                continue
            }

            // Composite frame onto canvas
            compositeFrame(
                framePixels: framePixels,
                frame: frame,
                canvas: &canvas,
                canvasWidth: info.width,
                canvasHeight: info.height
            )

            // Apply dispose method (for next frame, but we need to handle it now if not last)
            if i < frameIndex {
                applyDisposeMethod(
                    disposeMethod: frame.disposeMethod,
                    frame: frame,
                    canvas: &canvas,
                    previousCanvas: previousCanvas,
                    canvasWidth: info.width,
                    canvasHeight: info.height,
                    backgroundColorIndex: info.backgroundColorIndex,
                    globalColorTable: info.globalColorTable
                )
            }
        }

        let hasAlpha = info.frames[frameIndex].transparentColorIndex != nil

        return DecodeResult(
            pixels: Data(canvas),
            width: info.width,
            height: info.height,
            hasAlpha: hasAlpha
        )
    }

    // MARK: - GIF Parsing

    private static func parseGIF(data: Data) -> GIFInfo? {
        guard data.count >= 13 else { return nil }

        return data.withUnsafeBytes { buffer -> GIFInfo? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            // Verify GIF signature: "GIF87a" or "GIF89a"
            // Bytes 0-2: "GIF" (0x47, 0x49, 0x46)
            // Byte 3: "8" (0x38)
            // Byte 4: "7" or "9" (0x37 or 0x39)
            // Byte 5: "a" (0x61)
            guard ptr[0] == 0x47 &&  // 'G'
                  ptr[1] == 0x49 &&  // 'I'
                  ptr[2] == 0x46 &&  // 'F'
                  ptr[3] == 0x38 &&  // '8'
                  (ptr[4] == 0x37 || ptr[4] == 0x39) &&  // '7' or '9'
                  ptr[5] == 0x61     // 'a'
            else { return nil }

            // Logical Screen Descriptor
            let width = Int(ptr[6]) | (Int(ptr[7]) << 8)
            let height = Int(ptr[8]) | (Int(ptr[9]) << 8)
            let packedByte = ptr[10]
            let backgroundColorIndex = Int(ptr[11])

            let hasGlobalColorTable = (packedByte & 0x80) != 0
            let globalColorTableSize = 1 << ((packedByte & 0x07) + 1)

            var offset = 13
            var globalColorTable: [(r: UInt8, g: UInt8, b: UInt8)] = []

            // Read global color table
            if hasGlobalColorTable {
                for i in 0..<globalColorTableSize {
                    let entryOffset = offset + i * 3
                    guard entryOffset + 2 < data.count else { break }
                    globalColorTable.append((ptr[entryOffset], ptr[entryOffset + 1], ptr[entryOffset + 2]))
                }
                offset += globalColorTableSize * 3
            }

            // Parse frames
            var frames: [FrameInfo] = []
            var currentGraphicControl: (delay: Double, disposeMethod: UInt8, transparentColorIndex: Int?)? = nil

            while offset < data.count {
                let blockType = ptr[offset]
                offset += 1

                switch blockType {
                case IMAGE_SEPARATOR:
                    guard offset + 9 <= data.count else { break }

                    let left = Int(ptr[offset]) | (Int(ptr[offset + 1]) << 8)
                    let top = Int(ptr[offset + 2]) | (Int(ptr[offset + 3]) << 8)
                    let frameWidth = Int(ptr[offset + 4]) | (Int(ptr[offset + 5]) << 8)
                    let frameHeight = Int(ptr[offset + 6]) | (Int(ptr[offset + 7]) << 8)
                    let framePacked = ptr[offset + 8]
                    offset += 9

                    let hasLocalColorTable = (framePacked & 0x80) != 0
                    let interlaced = (framePacked & 0x40) != 0
                    let localColorTableSize = 1 << ((framePacked & 0x07) + 1)

                    var localColorTable: [(r: UInt8, g: UInt8, b: UInt8)]? = nil
                    if hasLocalColorTable {
                        var lct: [(r: UInt8, g: UInt8, b: UInt8)] = []
                        for i in 0..<localColorTableSize {
                            guard offset + i * 3 + 2 < data.count else { break }
                            lct.append((ptr[offset + i * 3], ptr[offset + i * 3 + 1], ptr[offset + i * 3 + 2]))
                        }
                        localColorTable = lct
                        offset += localColorTableSize * 3
                    }

                    // LZW minimum code size
                    guard offset < data.count else { break }
                    offset += 1

                    let imageDataOffset = offset

                    // Skip image data sub-blocks
                    while offset < data.count {
                        let blockSize = Int(ptr[offset])
                        offset += 1
                        if blockSize == 0 { break }
                        offset += blockSize
                    }

                    let imageDataLength = offset - imageDataOffset

                    let frame = FrameInfo(
                        delay: currentGraphicControl?.delay ?? 0.1,
                        disposeMethod: currentGraphicControl?.disposeMethod ?? DISPOSE_NONE,
                        transparentColorIndex: currentGraphicControl?.transparentColorIndex,
                        left: left,
                        top: top,
                        width: frameWidth,
                        height: frameHeight,
                        localColorTable: localColorTable,
                        interlaced: interlaced,
                        imageDataOffset: imageDataOffset,
                        imageDataLength: imageDataLength
                    )
                    frames.append(frame)

                    currentGraphicControl = nil

                case EXTENSION_INTRODUCER:
                    guard offset < data.count else { break }
                    let extensionLabel = ptr[offset]
                    offset += 1

                    switch extensionLabel {
                    case GRAPHIC_CONTROL_EXTENSION:
                        guard offset + 5 < data.count else { break }
                        let blockSize = Int(ptr[offset])
                        guard blockSize >= 4 else {
                            offset += 1
                            break
                        }
                        offset += 1

                        let gcPacked = ptr[offset]
                        let delayTime = Int(ptr[offset + 1]) | (Int(ptr[offset + 2]) << 8)
                        let transparentIndex = Int(ptr[offset + 3])

                        let disposeMethod = (gcPacked >> 2) & 0x07
                        let hasTransparent = (gcPacked & 0x01) != 0

                        currentGraphicControl = (
                            delay: Double(delayTime) / 100.0,
                            disposeMethod: disposeMethod,
                            transparentColorIndex: hasTransparent ? transparentIndex : nil
                        )

                        offset += blockSize
                        // Skip block terminator
                        if offset < data.count && ptr[offset] == 0 {
                            offset += 1
                        }

                    default:
                        // Skip other extensions
                        while offset < data.count {
                            let blockSize = Int(ptr[offset])
                            offset += 1
                            if blockSize == 0 { break }
                            offset += blockSize
                        }
                    }

                case TRAILER:
                    break

                default:
                    // Unknown block, try to skip
                    break
                }

                if blockType == TRAILER { break }
            }

            return GIFInfo(
                width: width,
                height: height,
                globalColorTable: globalColorTable,
                backgroundColorIndex: backgroundColorIndex,
                frames: frames
            )
        }
    }

    // MARK: - Frame Decoding

    private static func decodeFrame(data: Data, info: GIFInfo, frame: FrameInfo) -> [UInt8]? {
        return data.withUnsafeBytes { buffer -> [UInt8]? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }

            var offset = frame.imageDataOffset

            // Get LZW minimum code size (stored just before image data)
            guard offset > 0 else { return nil }
            // Note: The calculation below is not used directly but kept for documentation
            // let _ = Int(ptr[offset - 1 - (frame.imageDataLength - 1)])

            // Actually, need to re-read it properly
            // The imageDataOffset points to the first sub-block after LZW min code size
            // Let's fix this: go back to read LZW minimum code size
            let lzwOffset = frame.imageDataOffset - 1
            guard lzwOffset >= 0 && lzwOffset < data.count else { return nil }

            // Wait, our imageDataOffset is actually already after LZW min code size
            // Let me re-check the parsing logic...
            // In parseGIF, we do: offset += 1 (for LZW min code size), then imageDataOffset = offset
            // So imageDataOffset is the first sub-block

            // We need to re-read the LZW min code size
            let minCodeSizeOffset = frame.imageDataOffset - 1
            guard minCodeSizeOffset >= 0 && minCodeSizeOffset < data.count else { return nil }

            // Actually the parsing already skips it, so let's find it differently
            // The LZW min code size should be at a known position relative to frame data

            // Let me recalculate: after local color table (or image descriptor), we have:
            // 1 byte: LZW minimum code size
            // Then sub-blocks

            // Since we set imageDataOffset = offset after incrementing for min code size,
            // we need to look at offset - 1 relative to where sub-blocks start

            // Actually, let me re-examine: in the parsing:
            // offset += 1 (skip LZW min code size)
            // imageDataOffset = offset (points to first sub-block)

            // So to get min code size, we need imageDataOffset - 1
            // But we calculated imageDataLength from imageDataOffset to after all sub-blocks
            // So min code size byte is NOT included in imageDataLength

            // Let's read min code size correctly:
            var lzwMinSize = 8 // default
            let possibleMinCodeSizeOffset = frame.imageDataOffset - 1
            if possibleMinCodeSizeOffset >= 0 && possibleMinCodeSizeOffset < data.count {
                lzwMinSize = Int(ptr[possibleMinCodeSizeOffset])
            }

            // Read sub-blocks
            var compressedData = Data()
            offset = frame.imageDataOffset

            while offset < data.count {
                let blockSize = Int(ptr[offset])
                offset += 1
                if blockSize == 0 { break }
                guard offset + blockSize <= data.count else { break }

                compressedData.append(Data(bytes: ptr.advanced(by: offset), count: blockSize))
                offset += blockSize
            }

            // Decompress
            guard let decompressed = LZW.decode(data: compressedData, minCodeSize: lzwMinSize) else {
                return nil
            }

            // Convert indexed pixels to RGBA
            let colorTable = frame.localColorTable ?? info.globalColorTable
            var pixels = [UInt8](repeating: 0, count: frame.width * frame.height * 4)

            let decompressedArray = Array(decompressed)

            if frame.interlaced {
                // Adam7-like interlace for GIF
                let passStartRows = [0, 4, 2, 1]
                let passRowIncrements = [8, 8, 4, 2]

                var srcIndex = 0
                for pass in 0..<4 {
                    var y = passStartRows[pass]
                    while y < frame.height {
                        for x in 0..<frame.width {
                            guard srcIndex < decompressedArray.count else { break }

                            let colorIndex = Int(decompressedArray[srcIndex])
                            srcIndex += 1

                            let dstIndex = (y * frame.width + x) * 4

                            if let transparentIndex = frame.transparentColorIndex, colorIndex == transparentIndex {
                                pixels[dstIndex] = 0
                                pixels[dstIndex + 1] = 0
                                pixels[dstIndex + 2] = 0
                                pixels[dstIndex + 3] = 0
                            } else if colorIndex < colorTable.count {
                                let color = colorTable[colorIndex]
                                pixels[dstIndex] = color.r
                                pixels[dstIndex + 1] = color.g
                                pixels[dstIndex + 2] = color.b
                                pixels[dstIndex + 3] = 255
                            }
                        }
                        y += passRowIncrements[pass]
                    }
                }
            } else {
                for i in 0..<min(decompressedArray.count, frame.width * frame.height) {
                    let colorIndex = Int(decompressedArray[i])
                    let dstIndex = i * 4

                    if let transparentIndex = frame.transparentColorIndex, colorIndex == transparentIndex {
                        pixels[dstIndex] = 0
                        pixels[dstIndex + 1] = 0
                        pixels[dstIndex + 2] = 0
                        pixels[dstIndex + 3] = 0
                    } else if colorIndex < colorTable.count {
                        let color = colorTable[colorIndex]
                        pixels[dstIndex] = color.r
                        pixels[dstIndex + 1] = color.g
                        pixels[dstIndex + 2] = color.b
                        pixels[dstIndex + 3] = 255
                    }
                }
            }

            return pixels
        }
    }

    // MARK: - Frame Compositing

    private static func compositeFrame(
        framePixels: [UInt8],
        frame: FrameInfo,
        canvas: inout [UInt8],
        canvasWidth: Int,
        canvasHeight: Int
    ) {
        for y in 0..<frame.height {
            let canvasY = frame.top + y
            guard canvasY >= 0 && canvasY < canvasHeight else { continue }

            for x in 0..<frame.width {
                let canvasX = frame.left + x
                guard canvasX >= 0 && canvasX < canvasWidth else { continue }

                let srcIndex = (y * frame.width + x) * 4
                let dstIndex = (canvasY * canvasWidth + canvasX) * 4

                // Only composite if source pixel is not transparent
                let alpha = framePixels[srcIndex + 3]
                if alpha > 0 {
                    canvas[dstIndex] = framePixels[srcIndex]
                    canvas[dstIndex + 1] = framePixels[srcIndex + 1]
                    canvas[dstIndex + 2] = framePixels[srcIndex + 2]
                    canvas[dstIndex + 3] = alpha
                }
            }
        }
    }

    // MARK: - Dispose Method

    private static func applyDisposeMethod(
        disposeMethod: UInt8,
        frame: FrameInfo,
        canvas: inout [UInt8],
        previousCanvas: [UInt8]?,
        canvasWidth: Int,
        canvasHeight: Int,
        backgroundColorIndex: Int,
        globalColorTable: [(r: UInt8, g: UInt8, b: UInt8)]
    ) {
        switch disposeMethod {
        case DISPOSE_NONE, DISPOSE_DO_NOT_DISPOSE:
            // Keep canvas as-is
            break

        case DISPOSE_RESTORE_BACKGROUND:
            // Clear frame area to background color
            let bgColor: (r: UInt8, g: UInt8, b: UInt8)
            if backgroundColorIndex < globalColorTable.count {
                bgColor = globalColorTable[backgroundColorIndex]
            } else {
                bgColor = (0, 0, 0)
            }

            for y in 0..<frame.height {
                let canvasY = frame.top + y
                guard canvasY >= 0 && canvasY < canvasHeight else { continue }

                for x in 0..<frame.width {
                    let canvasX = frame.left + x
                    guard canvasX >= 0 && canvasX < canvasWidth else { continue }

                    let dstIndex = (canvasY * canvasWidth + canvasX) * 4
                    canvas[dstIndex] = bgColor.r
                    canvas[dstIndex + 1] = bgColor.g
                    canvas[dstIndex + 2] = bgColor.b
                    canvas[dstIndex + 3] = 0 // Transparent background
                }
            }

        case DISPOSE_RESTORE_PREVIOUS:
            // Restore previous canvas state
            if let previous = previousCanvas {
                for y in 0..<frame.height {
                    let canvasY = frame.top + y
                    guard canvasY >= 0 && canvasY < canvasHeight else { continue }

                    for x in 0..<frame.width {
                        let canvasX = frame.left + x
                        guard canvasX >= 0 && canvasX < canvasWidth else { continue }

                        let index = (canvasY * canvasWidth + canvasX) * 4
                        canvas[index] = previous[index]
                        canvas[index + 1] = previous[index + 1]
                        canvas[index + 2] = previous[index + 2]
                        canvas[index + 3] = previous[index + 3]
                    }
                }
            }

        default:
            break
        }
    }
}
