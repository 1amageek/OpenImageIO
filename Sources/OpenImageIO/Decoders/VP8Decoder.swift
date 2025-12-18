// VP8Decoder.swift
// OpenImageIO
//
// VP8 (lossy WebP) decoder with boolean arithmetic decoding,
// intra prediction, inverse DCT/WHT, and loop filtering

import Foundation

/// VP8 lossy decoder for WebP format
internal struct VP8Decoder {

    // MARK: - Types

    struct DecodeResult {
        let pixels: [UInt8]  // RGBA pixels
        let width: Int
        let height: Int
    }

    // MARK: - Constants

    /// Default probabilities for coefficient decoding
    private static let defaultCoeffProbs: [[[[UInt8]]]] = createDefaultCoeffProbs()

    /// Zig-zag order for 4x4 DCT coefficients
    fileprivate static let zigzag: [Int] = [
        0, 1, 4, 8, 5, 2, 3, 6, 9, 12, 13, 10, 7, 11, 14, 15
    ]

    /// DC quantization lookup table
    fileprivate static let dcQLookup: [Int] = [
        4, 5, 6, 7, 8, 9, 10, 10, 11, 12, 13, 14, 15, 16, 17, 17,
        18, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 25, 25, 26, 27, 28,
        29, 30, 31, 32, 33, 34, 35, 36, 37, 37, 38, 39, 40, 41, 42, 43,
        44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58,
        59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
        75, 76, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
        91, 93, 95, 96, 98, 100, 101, 102, 104, 106, 108, 110, 112, 114, 116, 118,
        122, 124, 126, 128, 130, 132, 134, 136, 138, 140, 143, 145, 148, 151, 154, 157
    ]

    /// AC quantization lookup table
    fileprivate static let acQLookup: [Int] = [
        4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76,
        78, 80, 82, 84, 86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108,
        110, 112, 114, 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152,
        155, 158, 161, 164, 167, 170, 173, 177, 181, 185, 189, 193, 197, 201, 205, 209,
        213, 217, 221, 225, 229, 234, 239, 245, 249, 254, 259, 264, 269, 274, 279, 284
    ]

    // MARK: - Public API

    static func decode(ptr: UnsafePointer<UInt8>, count: Int) -> DecodeResult? {
        guard count >= 10 else { return nil }

        // Parse frame header
        let frameTag = UInt32(ptr[0]) | (UInt32(ptr[1]) << 8) | (UInt32(ptr[2]) << 16)
        let isKeyFrame = (frameTag & 1) == 0
        let version = Int((frameTag >> 1) & 7)
        let showFrame = ((frameTag >> 4) & 1) == 1
        let firstPartSize = Int(frameTag >> 5)

        _ = version
        _ = showFrame

        guard isKeyFrame else {
            // Only keyframes are supported for now
            return nil
        }

        var offset = 3

        // Keyframe header: check start code
        guard offset + 7 <= count else { return nil }
        guard ptr[offset] == 0x9D && ptr[offset + 1] == 0x01 && ptr[offset + 2] == 0x2A else {
            return nil
        }
        offset += 3

        // Read dimensions
        let widthData = UInt16(ptr[offset]) | (UInt16(ptr[offset + 1]) << 8)
        let heightData = UInt16(ptr[offset + 2]) | (UInt16(ptr[offset + 3]) << 8)
        offset += 4

        let width = Int(widthData & 0x3FFF)
        let height = Int(heightData & 0x3FFF)
        let hScale = Int(widthData >> 14)
        let vScale = Int(heightData >> 14)

        _ = hScale
        _ = vScale

        guard width > 0 && height > 0 else { return nil }
        guard width <= 16384 && height <= 16384 else { return nil }

        // Create decoder state
        var decoder = VP8DecoderState(
            ptr: ptr,
            count: count,
            offset: offset,
            firstPartSize: firstPartSize,
            width: width,
            height: height
        )

        // Decode the frame
        guard let yuvPixels = decoder.decodeFrame() else {
            return nil
        }

        // Convert YUV to RGBA
        let rgbaPixels = yuvToRGBA(yuv: yuvPixels, width: width, height: height)

        return DecodeResult(pixels: rgbaPixels, width: width, height: height)
    }

    // MARK: - YUV to RGBA Conversion

    private static func yuvToRGBA(yuv: YUVBuffer, width: Int, height: Int) -> [UInt8] {
        var rgba = [UInt8](repeating: 255, count: width * height * 4)

        let uvWidth = (width + 1) / 2
        let uvHeight = (height + 1) / 2
        _ = uvHeight

        for y in 0..<height {
            for x in 0..<width {
                let yIdx = y * width + x
                let uvIdx = (y / 2) * uvWidth + (x / 2)

                let yVal = Int(yuv.y[yIdx])
                let uVal = Int(yuv.u[min(uvIdx, yuv.u.count - 1)]) - 128
                let vVal = Int(yuv.v[min(uvIdx, yuv.v.count - 1)]) - 128

                // BT.601 conversion
                let r = yVal + ((91881 * vVal) >> 16)
                let g = yVal - ((22554 * uVal + 46802 * vVal) >> 16)
                let b = yVal + ((116130 * uVal) >> 16)

                let rgbaIdx = yIdx * 4
                rgba[rgbaIdx] = UInt8(clamping: max(0, min(255, r)))
                rgba[rgbaIdx + 1] = UInt8(clamping: max(0, min(255, g)))
                rgba[rgbaIdx + 2] = UInt8(clamping: max(0, min(255, b)))
                rgba[rgbaIdx + 3] = 255
            }
        }

        return rgba
    }

    // MARK: - Default Coefficient Probabilities

    fileprivate static func createDefaultCoeffProbs() -> [[[[UInt8]]]] {
        // Simplified default probabilities (4 types x 8 bands x 3 contexts x 11 probs)
        var probs = [[[[UInt8]]]](repeating:
            [[[UInt8]]](repeating:
                [[UInt8]](repeating:
                    [UInt8](repeating: 128, count: 11),
                    count: 3),
                count: 8),
            count: 4)

        // Set more realistic default values for common patterns
        for t in 0..<4 {
            for b in 0..<8 {
                for c in 0..<3 {
                    probs[t][b][c][0] = 128  // More zeros at higher bands
                    probs[t][b][c][1] = 128
                    probs[t][b][c][2] = 180
                    probs[t][b][c][3] = 180
                    probs[t][b][c][4] = 180
                }
            }
        }

        return probs
    }
}

// MARK: - YUV Buffer

private struct YUVBuffer {
    var y: [UInt8]
    var u: [UInt8]
    var v: [UInt8]
}

// MARK: - VP8 Decoder State

private struct VP8DecoderState {
    let ptr: UnsafePointer<UInt8>
    let count: Int
    var offset: Int
    let firstPartSize: Int
    let width: Int
    let height: Int

    // Boolean decoder state
    private var boolRange: UInt32 = 255
    private var boolValue: UInt32 = 0
    private var boolCount: Int = 0
    private var boolOffset: Int = 0

    // Macroblock dimensions
    private let mbWidth: Int
    private let mbHeight: Int

    // Quantization parameters
    private var yDcQ: Int = 4
    private var yAcQ: Int = 4
    private var y2DcQ: Int = 4
    private var y2AcQ: Int = 4
    private var uvDcQ: Int = 4
    private var uvAcQ: Int = 4

    // Segment parameters
    private var segmentationEnabled = false
    private var updateMbSegmentation = false

    // Filter parameters
    private var filterType: Int = 0
    private var filterLevel: Int = 0
    private var sharpness: Int = 0

    // Coefficient probabilities
    private var coeffProbs: [[[[UInt8]]]]

    init(ptr: UnsafePointer<UInt8>, count: Int, offset: Int, firstPartSize: Int, width: Int, height: Int) {
        self.ptr = ptr
        self.count = count
        self.offset = offset
        self.firstPartSize = firstPartSize
        self.width = width
        self.height = height
        self.mbWidth = (width + 15) / 16
        self.mbHeight = (height + 15) / 16
        self.boolOffset = offset
        self.coeffProbs = VP8Decoder.createDefaultCoeffProbs()
    }

    // MARK: - Frame Decoding

    mutating func decodeFrame() -> YUVBuffer? {
        // Initialize boolean decoder
        guard initBoolDecoder() else { return nil }

        // Parse frame header
        guard parseFrameHeader() else { return nil }

        // Allocate YUV buffers
        let ySize = width * height
        let uvSize = ((width + 1) / 2) * ((height + 1) / 2)

        var yuv = YUVBuffer(
            y: [UInt8](repeating: 128, count: ySize),
            u: [UInt8](repeating: 128, count: uvSize),
            v: [UInt8](repeating: 128, count: uvSize)
        )

        // Decode macroblocks
        for mbY in 0..<mbHeight {
            for mbX in 0..<mbWidth {
                guard decodeMacroblock(mbX: mbX, mbY: mbY, yuv: &yuv) else {
                    continue
                }
            }
        }

        // Apply loop filter
        applyLoopFilter(yuv: &yuv)

        return yuv
    }

    // MARK: - Boolean Decoder

    private mutating func initBoolDecoder() -> Bool {
        guard boolOffset + 2 <= count else { return false }

        boolValue = UInt32(ptr[boolOffset]) << 8
        boolOffset += 1

        if boolOffset < count {
            boolValue |= UInt32(ptr[boolOffset])
            boolOffset += 1
        }

        boolRange = 255
        boolCount = 8

        return true
    }

    private mutating func readBool(prob: UInt8) -> Int {
        let split = 1 + (((boolRange - 1) * UInt32(prob)) >> 8)

        let bit: Int
        if boolValue < (split << 8) {
            boolRange = split
            bit = 0
        } else {
            boolRange -= split
            boolValue -= split << 8
            bit = 1
        }

        // Renormalize
        while boolRange < 128 {
            boolRange <<= 1
            boolValue <<= 1
            boolCount -= 1

            if boolCount == 0 {
                if boolOffset < count {
                    boolValue |= UInt32(ptr[boolOffset])
                    boolOffset += 1
                }
                boolCount = 8
            }
        }

        return bit
    }

    private mutating func readLiteral(bits: Int) -> Int {
        var value = 0
        for _ in 0..<bits {
            value = (value << 1) | readBool(prob: 128)
        }
        return value
    }

    private mutating func readSignedLiteral(bits: Int) -> Int {
        let value = readLiteral(bits: bits)
        if readBool(prob: 128) == 1 {
            return -value
        }
        return value
    }

    // MARK: - Frame Header Parsing

    private mutating func parseFrameHeader() -> Bool {
        // Color space and clamping (keyframe only)
        let colorSpace = readBool(prob: 128)
        let clampType = readBool(prob: 128)
        _ = colorSpace
        _ = clampType

        // Segmentation
        segmentationEnabled = readBool(prob: 128) == 1
        if segmentationEnabled {
            updateMbSegmentation = readBool(prob: 128) == 1
            if updateMbSegmentation {
                // Skip segment feature data
                let updateData = readBool(prob: 128) == 1
                if updateData {
                    _ = readBool(prob: 128) // Abs/delta
                    for _ in 0..<4 {
                        if readBool(prob: 128) == 1 {
                            _ = readSignedLiteral(bits: 7)
                        }
                    }
                    for _ in 0..<4 {
                        if readBool(prob: 128) == 1 {
                            _ = readSignedLiteral(bits: 6)
                        }
                    }
                }
            }
            // Skip segment probability update
            if readBool(prob: 128) == 1 {
                for _ in 0..<3 {
                    if readBool(prob: 128) == 1 {
                        _ = readLiteral(bits: 8)
                    }
                }
            }
        }

        // Filter parameters
        filterType = readBool(prob: 128)
        filterLevel = readLiteral(bits: 6)
        sharpness = readLiteral(bits: 3)

        // Loop filter adjustments
        let modeRefLfDeltaEnabled = readBool(prob: 128) == 1
        if modeRefLfDeltaEnabled {
            let modeRefLfDeltaUpdate = readBool(prob: 128) == 1
            if modeRefLfDeltaUpdate {
                for _ in 0..<4 {
                    if readBool(prob: 128) == 1 {
                        _ = readSignedLiteral(bits: 6)
                    }
                }
                for _ in 0..<4 {
                    if readBool(prob: 128) == 1 {
                        _ = readSignedLiteral(bits: 6)
                    }
                }
            }
        }

        // Partitions
        let logPartitions = readLiteral(bits: 2)
        _ = logPartitions

        // Quantization
        let yAcQi = readLiteral(bits: 7)
        yAcQ = VP8Decoder.acQLookup[min(yAcQi, 127)]
        yDcQ = VP8Decoder.dcQLookup[min(yAcQi, 127)]

        if readBool(prob: 128) == 1 {
            let delta = readSignedLiteral(bits: 4)
            yDcQ = VP8Decoder.dcQLookup[min(max(yAcQi + delta, 0), 127)]
        }

        if readBool(prob: 128) == 1 {
            let delta = readSignedLiteral(bits: 4)
            y2DcQ = VP8Decoder.dcQLookup[min(max(yAcQi + delta, 0), 127)]
        } else {
            y2DcQ = yDcQ
        }

        if readBool(prob: 128) == 1 {
            let delta = readSignedLiteral(bits: 4)
            y2AcQ = VP8Decoder.acQLookup[min(max(yAcQi + delta, 0), 127)]
        } else {
            y2AcQ = yAcQ
        }

        if readBool(prob: 128) == 1 {
            let delta = readSignedLiteral(bits: 4)
            uvDcQ = VP8Decoder.dcQLookup[min(max(yAcQi + delta, 0), 127)]
        } else {
            uvDcQ = yDcQ
        }

        if readBool(prob: 128) == 1 {
            let delta = readSignedLiteral(bits: 4)
            uvAcQ = VP8Decoder.acQLookup[min(max(yAcQi + delta, 0), 127)]
        } else {
            uvAcQ = yAcQ
        }

        // Refresh entropy probs
        _ = readBool(prob: 128)

        // Update coefficient probabilities
        updateCoeffProbs()

        // Skip MB no coeff
        _ = readLiteral(bits: 8)

        return true
    }

    private mutating func updateCoeffProbs() {
        // Read coefficient probability updates
        for t in 0..<4 {
            for b in 0..<8 {
                for c in 0..<3 {
                    for p in 0..<11 {
                        if readBool(prob: coeffUpdateProbs[t][b][c][p]) == 1 {
                            coeffProbs[t][b][c][p] = UInt8(readLiteral(bits: 8))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Macroblock Decoding

    private mutating func decodeMacroblock(mbX: Int, mbY: Int, yuv: inout YUVBuffer) -> Bool {
        // Read segment ID (if segmentation enabled)
        var segmentId = 0
        if segmentationEnabled && updateMbSegmentation {
            if readBool(prob: 128) == 1 {
                segmentId = readBool(prob: 128) | (readBool(prob: 128) << 1)
            }
        }
        _ = segmentId

        // Read MB skip coeff flag
        let mbSkipCoeff = readBool(prob: 128) == 1

        // Intra prediction mode
        let yMode = readIntraModeY()
        var uvMode = 0

        if yMode == 4 {
            // B_PRED: read 16 sub-block modes
            for _ in 0..<16 {
                _ = readSubBlockMode()
            }
            uvMode = readIntraModeUV()
        } else {
            uvMode = readIntraModeUV()
        }

        // Decode coefficients
        var yCoeffs = [[Int16]](repeating: [Int16](repeating: 0, count: 16), count: 16)
        var uCoeffs = [[Int16]](repeating: [Int16](repeating: 0, count: 16), count: 4)
        var vCoeffs = [[Int16]](repeating: [Int16](repeating: 0, count: 16), count: 4)
        var y2Coeffs = [Int16](repeating: 0, count: 16)

        if !mbSkipCoeff {
            // Decode Y2 (DC) coefficients for Y plane
            if yMode != 4 {
                decodeCoefficients(coeffs: &y2Coeffs, type: 1)
                // Inverse WHT for Y2
                inverseWHT(coeffs: &y2Coeffs)
            }

            // Decode Y coefficients
            for i in 0..<16 {
                decodeCoefficients(coeffs: &yCoeffs[i], type: yMode == 4 ? 3 : 0)
                if yMode != 4 {
                    // Add DC from Y2
                    yCoeffs[i][0] = y2Coeffs[i]
                }
            }

            // Decode U coefficients
            for i in 0..<4 {
                decodeCoefficients(coeffs: &uCoeffs[i], type: 2)
            }

            // Decode V coefficients
            for i in 0..<4 {
                decodeCoefficients(coeffs: &vCoeffs[i], type: 2)
            }
        }

        // Reconstruct Y plane (16x16)
        reconstructYPlane(mbX: mbX, mbY: mbY, mode: yMode, coeffs: yCoeffs, yuv: &yuv)

        // Reconstruct UV planes (8x8 each)
        reconstructUVPlane(mbX: mbX, mbY: mbY, mode: uvMode, uCoeffs: uCoeffs, vCoeffs: vCoeffs, yuv: &yuv)

        return true
    }

    // MARK: - Intra Prediction Mode Reading

    private mutating func readIntraModeY() -> Int {
        // 0: DC_PRED, 1: V_PRED, 2: H_PRED, 3: TM_PRED, 4: B_PRED
        if readBool(prob: 145) == 0 {
            return 0  // DC_PRED
        }
        if readBool(prob: 156) == 0 {
            return 1  // V_PRED
        }
        if readBool(prob: 163) == 0 {
            return 2  // H_PRED
        }
        if readBool(prob: 128) == 0 {
            return 3  // TM_PRED
        }
        return 4  // B_PRED
    }

    private mutating func readIntraModeUV() -> Int {
        if readBool(prob: 142) == 0 {
            return 0  // DC_PRED
        }
        if readBool(prob: 114) == 0 {
            return 1  // V_PRED
        }
        if readBool(prob: 183) == 0 {
            return 2  // H_PRED
        }
        return 3  // TM_PRED
    }

    private mutating func readSubBlockMode() -> Int {
        // Simplified: read 4x4 intra mode
        if readBool(prob: 120) == 0 {
            return 0
        }
        return readLiteral(bits: 3) + 1
    }

    // MARK: - Coefficient Decoding

    private mutating func decodeCoefficients(coeffs: inout [Int16], type: Int) {
        var band = 0
        var ctx = 0

        for i in 0..<16 {
            let zzIdx = VP8Decoder.zigzag[i]

            // Read if coefficient is non-zero
            if readBool(prob: coeffProbs[type][band][ctx][0]) == 0 {
                ctx = 0
                if band < 7 { band += 1 }
                continue
            }

            // Read if coefficient is > 1
            if readBool(prob: coeffProbs[type][band][ctx][1]) == 0 {
                coeffs[zzIdx] = 1
                ctx = 1
            } else {
                // Read token value
                let level = readCoeffToken(type: type, band: band, ctx: ctx)
                coeffs[zzIdx] = Int16(level)
                ctx = 2
            }

            // Read sign
            if readBool(prob: 128) == 1 {
                coeffs[zzIdx] = -coeffs[zzIdx]
            }

            if band < 7 { band += 1 }
        }

        // Dequantize
        let dcQ = type == 2 ? uvDcQ : (type == 1 ? y2DcQ : yDcQ)
        let acQ = type == 2 ? uvAcQ : (type == 1 ? y2AcQ : yAcQ)

        coeffs[0] = Int16(Int(coeffs[0]) * dcQ)
        for i in 1..<16 {
            coeffs[i] = Int16(Int(coeffs[i]) * acQ)
        }
    }

    private mutating func readCoeffToken(type: Int, band: Int, ctx: Int) -> Int {
        let probs = coeffProbs[type][band][ctx]

        // Token tree
        if readBool(prob: probs[2]) == 0 {
            return 2
        }
        if readBool(prob: probs[3]) == 0 {
            return 3
        }
        if readBool(prob: probs[4]) == 0 {
            return 4
        }
        if readBool(prob: probs[5]) == 0 {
            if readBool(prob: probs[6]) == 0 {
                return 5 + readLiteral(bits: 1)
            }
            return 7 + readLiteral(bits: 2)
        }
        if readBool(prob: probs[7]) == 0 {
            return 11 + readLiteral(bits: 3)
        }
        if readBool(prob: probs[8]) == 0 {
            return 19 + readLiteral(bits: 4)
        }
        if readBool(prob: probs[9]) == 0 {
            return 35 + readLiteral(bits: 5)
        }
        return 67 + readLiteral(bits: 11)
    }

    // MARK: - Inverse Transforms

    private func inverseWHT(coeffs: inout [Int16]) {
        // Walsh-Hadamard Transform for DC coefficients
        var tmp = [Int](repeating: 0, count: 16)

        // Horizontal pass
        for i in 0..<4 {
            let a0 = Int(coeffs[i * 4])
            let a1 = Int(coeffs[i * 4 + 1])
            let a2 = Int(coeffs[i * 4 + 2])
            let a3 = Int(coeffs[i * 4 + 3])

            let b0 = a0 + a2
            let b1 = a0 - a2
            let b2 = a1 - a3
            let b3 = a1 + a3

            tmp[i * 4] = b0 + b3
            tmp[i * 4 + 1] = b1 + b2
            tmp[i * 4 + 2] = b1 - b2
            tmp[i * 4 + 3] = b0 - b3
        }

        // Vertical pass
        for i in 0..<4 {
            let a0 = tmp[i]
            let a1 = tmp[i + 4]
            let a2 = tmp[i + 8]
            let a3 = tmp[i + 12]

            let b0 = a0 + a2
            let b1 = a0 - a2
            let b2 = a1 - a3
            let b3 = a1 + a3

            coeffs[i] = Int16((b0 + b3 + 3) >> 3)
            coeffs[i + 4] = Int16((b1 + b2 + 3) >> 3)
            coeffs[i + 8] = Int16((b1 - b2 + 3) >> 3)
            coeffs[i + 12] = Int16((b0 - b3 + 3) >> 3)
        }
    }

    private func inverseDCT4x4(coeffs: [Int16]) -> [Int16] {
        var out = [Int16](repeating: 0, count: 16)
        var tmp = [Int](repeating: 0, count: 16)

        // Constants for DCT
        let c1: Int = 20091  // cos(pi/8) * 2^14
        let c2: Int = 35468  // sin(pi/8) * 2^14

        // Horizontal pass
        for i in 0..<4 {
            let a0 = Int(coeffs[i * 4])
            let a1 = Int(coeffs[i * 4 + 1])
            let a2 = Int(coeffs[i * 4 + 2])
            let a3 = Int(coeffs[i * 4 + 3])

            let b0 = a0 + a2
            let b1 = a0 - a2
            let b2 = ((a1 * c2) >> 16) - ((a3 * c1) >> 16) - a3
            let b3 = ((a1 * c1) >> 16) + a1 + ((a3 * c2) >> 16)

            tmp[i * 4] = b0 + b3
            tmp[i * 4 + 1] = b1 + b2
            tmp[i * 4 + 2] = b1 - b2
            tmp[i * 4 + 3] = b0 - b3
        }

        // Vertical pass
        for i in 0..<4 {
            let a0 = tmp[i]
            let a1 = tmp[i + 4]
            let a2 = tmp[i + 8]
            let a3 = tmp[i + 12]

            let b0 = a0 + a2
            let b1 = a0 - a2
            let b2 = ((a1 * c2) >> 16) - ((a3 * c1) >> 16) - a3
            let b3 = ((a1 * c1) >> 16) + a1 + ((a3 * c2) >> 16)

            out[i] = Int16((b0 + b3 + 4) >> 3)
            out[i + 4] = Int16((b1 + b2 + 4) >> 3)
            out[i + 8] = Int16((b1 - b2 + 4) >> 3)
            out[i + 12] = Int16((b0 - b3 + 4) >> 3)
        }

        return out
    }

    // MARK: - Reconstruction

    private func reconstructYPlane(mbX: Int, mbY: Int, mode: Int, coeffs: [[Int16]], yuv: inout YUVBuffer) {
        let baseX = mbX * 16
        let baseY = mbY * 16

        // Apply intra prediction based on mode
        for sbY in 0..<4 {
            for sbX in 0..<4 {
                let sbIdx = sbY * 4 + sbX
                let dct = inverseDCT4x4(coeffs: coeffs[sbIdx])

                // Get prediction
                let pred = getPrediction4x4(
                    x: baseX + sbX * 4,
                    y: baseY + sbY * 4,
                    mode: mode,
                    yuv: yuv,
                    plane: .y
                )

                // Add residual to prediction
                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = baseX + sbX * 4 + x
                        let py = baseY + sbY * 4 + y

                        guard px < width && py < height else { continue }

                        let idx = py * width + px
                        let predVal = Int(pred[y * 4 + x])
                        let residual = Int(dct[y * 4 + x])
                        yuv.y[idx] = UInt8(clamping: max(0, min(255, predVal + residual)))
                    }
                }
            }
        }
    }

    private func reconstructUVPlane(mbX: Int, mbY: Int, mode: Int, uCoeffs: [[Int16]], vCoeffs: [[Int16]], yuv: inout YUVBuffer) {
        let baseX = mbX * 8
        let baseY = mbY * 8
        let uvWidth = (width + 1) / 2

        for sbY in 0..<2 {
            for sbX in 0..<2 {
                let sbIdx = sbY * 2 + sbX

                // U plane
                let uDct = inverseDCT4x4(coeffs: uCoeffs[sbIdx])
                let uPred = getPrediction4x4(
                    x: baseX + sbX * 4,
                    y: baseY + sbY * 4,
                    mode: mode,
                    yuv: yuv,
                    plane: .u
                )

                // V plane
                let vDct = inverseDCT4x4(coeffs: vCoeffs[sbIdx])
                let vPred = getPrediction4x4(
                    x: baseX + sbX * 4,
                    y: baseY + sbY * 4,
                    mode: mode,
                    yuv: yuv,
                    plane: .v
                )

                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = baseX + sbX * 4 + x
                        let py = baseY + sbY * 4 + y

                        guard px < uvWidth && py < (height + 1) / 2 else { continue }

                        let idx = py * uvWidth + px

                        let uVal = Int(uPred[y * 4 + x]) + Int(uDct[y * 4 + x])
                        let vVal = Int(vPred[y * 4 + x]) + Int(vDct[y * 4 + x])

                        yuv.u[idx] = UInt8(clamping: max(0, min(255, uVal)))
                        yuv.v[idx] = UInt8(clamping: max(0, min(255, vVal)))
                    }
                }
            }
        }
    }

    private enum Plane {
        case y, u, v
    }

    private func getPrediction4x4(x: Int, y: Int, mode: Int, yuv: YUVBuffer, plane: Plane) -> [UInt8] {
        var pred = [UInt8](repeating: 128, count: 16)

        let buffer: [UInt8]
        let w: Int
        let h: Int

        switch plane {
        case .y:
            buffer = yuv.y
            w = width
            h = height
        case .u:
            buffer = yuv.u
            w = (width + 1) / 2
            h = (height + 1) / 2
        case .v:
            buffer = yuv.v
            w = (width + 1) / 2
            h = (height + 1) / 2
        }

        switch mode {
        case 0: // DC_PRED
            var sum = 0
            var count = 0

            // Left pixels
            if x > 0 {
                for i in 0..<4 {
                    if y + i < h {
                        sum += Int(buffer[(y + i) * w + x - 1])
                        count += 1
                    }
                }
            }

            // Top pixels
            if y > 0 {
                for i in 0..<4 {
                    if x + i < w {
                        sum += Int(buffer[(y - 1) * w + x + i])
                        count += 1
                    }
                }
            }

            let dc = count > 0 ? UInt8(sum / count) : 128
            pred = [UInt8](repeating: dc, count: 16)

        case 1: // V_PRED (vertical)
            if y > 0 {
                for py in 0..<4 {
                    for px in 0..<4 {
                        if x + px < w {
                            pred[py * 4 + px] = buffer[(y - 1) * w + x + px]
                        }
                    }
                }
            }

        case 2: // H_PRED (horizontal)
            if x > 0 {
                for py in 0..<4 {
                    for px in 0..<4 {
                        if y + py < h {
                            pred[py * 4 + px] = buffer[(y + py) * w + x - 1]
                        }
                    }
                }
            }

        case 3: // TM_PRED (TrueMotion)
            let topLeft: Int
            if x > 0 && y > 0 {
                topLeft = Int(buffer[(y - 1) * w + x - 1])
            } else {
                topLeft = 128
            }

            for py in 0..<4 {
                for px in 0..<4 {
                    var top = 128
                    var left = 128

                    if y > 0 && x + px < w {
                        top = Int(buffer[(y - 1) * w + x + px])
                    }
                    if x > 0 && y + py < h {
                        left = Int(buffer[(y + py) * w + x - 1])
                    }

                    let val = left + top - topLeft
                    pred[py * 4 + px] = UInt8(clamping: max(0, min(255, val)))
                }
            }

        default:
            break
        }

        return pred
    }

    // MARK: - Loop Filter

    private func applyLoopFilter(yuv: inout YUVBuffer) {
        guard filterLevel > 0 else { return }

        // Simplified loop filter - smooth edges between macroblocks
        let limit = filterLevel * 2 + sharpness

        // Apply to Y plane
        for mbY in 0..<mbHeight {
            for mbX in 0..<mbWidth {
                filterMacroblockEdges(mbX: mbX, mbY: mbY, buffer: &yuv.y, stride: width, limit: limit)
            }
        }

        // Apply to UV planes
        let uvWidth = (width + 1) / 2
        for mbY in 0..<mbHeight {
            for mbX in 0..<mbWidth {
                filterMacroblockEdgesUV(mbX: mbX, mbY: mbY, uBuffer: &yuv.u, vBuffer: &yuv.v, stride: uvWidth, limit: limit)
            }
        }
    }

    private func filterMacroblockEdges(mbX: Int, mbY: Int, buffer: inout [UInt8], stride: Int, limit: Int) {
        let baseX = mbX * 16
        let baseY = mbY * 16

        // Vertical edges (left side of macroblock)
        if mbX > 0 {
            for y in 0..<16 {
                let py = baseY + y
                guard py < height else { continue }

                for offset in 0..<4 {
                    let px = baseX + offset
                    guard px < width && px > 0 else { continue }

                    let idx = py * stride + px
                    let left = Int(buffer[idx - 1])
                    let right = Int(buffer[idx])
                    let diff = abs(left - right)

                    if diff < limit {
                        let avg = (left + right + 1) / 2
                        buffer[idx - 1] = UInt8(clamping: (Int(buffer[idx - 1]) * 3 + avg) / 4)
                        buffer[idx] = UInt8(clamping: (Int(buffer[idx]) * 3 + avg) / 4)
                    }
                }
            }
        }

        // Horizontal edges (top side of macroblock)
        if mbY > 0 {
            for x in 0..<16 {
                let px = baseX + x
                guard px < width else { continue }

                for offset in 0..<4 {
                    let py = baseY + offset
                    guard py < height && py > 0 else { continue }

                    let idx = py * stride + px
                    let top = Int(buffer[idx - stride])
                    let bottom = Int(buffer[idx])
                    let diff = abs(top - bottom)

                    if diff < limit {
                        let avg = (top + bottom + 1) / 2
                        buffer[idx - stride] = UInt8(clamping: (Int(buffer[idx - stride]) * 3 + avg) / 4)
                        buffer[idx] = UInt8(clamping: (Int(buffer[idx]) * 3 + avg) / 4)
                    }
                }
            }
        }
    }

    private func filterMacroblockEdgesUV(mbX: Int, mbY: Int, uBuffer: inout [UInt8], vBuffer: inout [UInt8], stride: Int, limit: Int) {
        let baseX = mbX * 8
        let baseY = mbY * 8
        let uvHeight = (height + 1) / 2
        let uvWidth = (width + 1) / 2

        // Apply simplified filter to U and V planes
        if mbX > 0 {
            for y in 0..<8 {
                let py = baseY + y
                guard py < uvHeight else { continue }

                let px = baseX
                guard px < uvWidth && px > 0 else { continue }

                let idx = py * stride + px

                // U plane
                let uLeft = Int(uBuffer[idx - 1])
                let uRight = Int(uBuffer[idx])
                if abs(uLeft - uRight) < limit {
                    let uAvg = (uLeft + uRight + 1) / 2
                    uBuffer[idx - 1] = UInt8(clamping: (uLeft * 3 + uAvg) / 4)
                    uBuffer[idx] = UInt8(clamping: (uRight * 3 + uAvg) / 4)
                }

                // V plane
                let vLeft = Int(vBuffer[idx - 1])
                let vRight = Int(vBuffer[idx])
                if abs(vLeft - vRight) < limit {
                    let vAvg = (vLeft + vRight + 1) / 2
                    vBuffer[idx - 1] = UInt8(clamping: (vLeft * 3 + vAvg) / 4)
                    vBuffer[idx] = UInt8(clamping: (vRight * 3 + vAvg) / 4)
                }
            }
        }
    }
}

// MARK: - Coefficient Update Probabilities

private let coeffUpdateProbs: [[[[UInt8]]]] = [
    // Type 0 (Y with Y2)
    [
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[176, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [223, 241, 252, 255, 255, 255, 255, 255, 255, 255, 255],
         [249, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 244, 252, 255, 255, 255, 255, 255, 255, 255, 255],
         [234, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 246, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [239, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [251, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [251, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255],
         [254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 254, 253, 255, 254, 255, 255, 255, 255, 255, 255],
         [250, 255, 254, 255, 254, 255, 255, 255, 255, 255, 255],
         [254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]]
    ],
    // Types 1-3 (simplified - same structure)
    [
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]]
    ],
    [
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]]
    ],
    [
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]],
        [[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
         [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]]
    ]
]
