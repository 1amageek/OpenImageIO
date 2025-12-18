// BMPEncoder.swift
// OpenImageIO
//
// BMP image format encoder with 24-bit RGB and 32-bit RGBA support

import Foundation
import OpenCoreGraphics

/// BMP image encoder
internal struct BMPEncoder {

    // MARK: - Constants

    /// BMP file signature ("BM")
    private static let BMP_SIGNATURE: [UInt8] = [0x42, 0x4D]

    /// BITMAPINFOHEADER size
    private static let DIB_HEADER_SIZE: UInt32 = 40

    /// BITMAPV4HEADER size (for alpha support)
    private static let DIB_V4_HEADER_SIZE: UInt32 = 108

    // Compression types
    private static let BI_RGB: UInt32 = 0
    private static let BI_BITFIELDS: UInt32 = 3

    // MARK: - Public API

    /// Encode CGImage to BMP data
    /// - Parameters:
    ///   - image: The image to encode
    ///   - options: Encoding options (optional)
    ///     - "preserveAlpha": Bool - If true, encode as 32-bit BGRA (default: false for compatibility)
    /// - Returns: BMP data or nil if encoding fails
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        let width = image.width
        let height = image.height

        guard width > 0 && height > 0 else { return nil }

        // Get pixel data
        guard let imageData = image.dataProvider?.data else { return nil }

        // Check if we should preserve alpha
        let preserveAlpha = (options?["preserveAlpha"] as? Bool) ?? false
        let hasAlpha = preserveAlpha && imageHasAlpha(image)

        if hasAlpha {
            return encode32BitBGRA(image: image, imageData: imageData, width: width, height: height)
        } else {
            return encode24BitBGR(image: image, imageData: imageData, width: width, height: height)
        }
    }

    // MARK: - 24-bit BGR Encoding (Standard BMP)

    private static func encode24BitBGR(
        image: CGImage,
        imageData: Data,
        width: Int,
        height: Int
    ) -> Data? {
        // Row size must be multiple of 4 bytes
        let rowSize = ((width * 3 + 3) / 4) * 4
        let imageSize = rowSize * height
        let fileSize = 54 + imageSize // 14 (file header) + 40 (DIB header) + pixel data

        var output = Data()
        output.reserveCapacity(fileSize)

        // BMP File Header (14 bytes)
        output.append(contentsOf: BMP_SIGNATURE)                                          // Signature
        output.append(contentsOf: uint32ToLittleEndian(UInt32(fileSize)))                // File size
        output.append(contentsOf: [0x00, 0x00, 0x00, 0x00])                              // Reserved
        output.append(contentsOf: uint32ToLittleEndian(54))                              // Data offset

        // DIB Header - BITMAPINFOHEADER (40 bytes)
        output.append(contentsOf: uint32ToLittleEndian(DIB_HEADER_SIZE))                 // Header size
        output.append(contentsOf: int32ToLittleEndian(Int32(width)))                     // Width
        output.append(contentsOf: int32ToLittleEndian(Int32(height)))                    // Height (positive = bottom-up)
        output.append(contentsOf: uint16ToLittleEndian(1))                               // Color planes
        output.append(contentsOf: uint16ToLittleEndian(24))                              // Bits per pixel
        output.append(contentsOf: uint32ToLittleEndian(BI_RGB))                          // Compression (none)
        output.append(contentsOf: uint32ToLittleEndian(UInt32(imageSize)))               // Image size
        output.append(contentsOf: int32ToLittleEndian(2835))                             // X pixels per meter (~72 DPI)
        output.append(contentsOf: int32ToLittleEndian(2835))                             // Y pixels per meter
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Colors used
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Important colors

        // Pixel Data (BGR format, bottom-up row order)
        for y in (0..<height).reversed() {
            for x in 0..<width {
                let srcIndex = y * image.bytesPerRow + x * 4
                if srcIndex + 2 < imageData.count {
                    output.append(imageData[srcIndex + 2]) // B
                    output.append(imageData[srcIndex + 1]) // G
                    output.append(imageData[srcIndex])     // R
                } else {
                    output.append(contentsOf: [0, 0, 0])
                }
            }
            // Row padding to 4-byte boundary
            let padding = rowSize - width * 3
            for _ in 0..<padding {
                output.append(0)
            }
        }

        return output
    }

    // MARK: - 32-bit BGRA Encoding (With Alpha)

    private static func encode32BitBGRA(
        image: CGImage,
        imageData: Data,
        width: Int,
        height: Int
    ) -> Data? {
        // 32-bit rows are always 4-byte aligned (no padding needed)
        let rowSize = width * 4
        let imageSize = rowSize * height
        let headerSize = 14 + Int(DIB_V4_HEADER_SIZE) // File header + V4 header
        let fileSize = headerSize + imageSize

        var output = Data()
        output.reserveCapacity(fileSize)

        // BMP File Header (14 bytes)
        output.append(contentsOf: BMP_SIGNATURE)                                          // Signature
        output.append(contentsOf: uint32ToLittleEndian(UInt32(fileSize)))                // File size
        output.append(contentsOf: [0x00, 0x00, 0x00, 0x00])                              // Reserved
        output.append(contentsOf: uint32ToLittleEndian(UInt32(headerSize)))              // Data offset

        // DIB Header - BITMAPV4HEADER (108 bytes)
        output.append(contentsOf: uint32ToLittleEndian(DIB_V4_HEADER_SIZE))              // Header size
        output.append(contentsOf: int32ToLittleEndian(Int32(width)))                     // Width
        output.append(contentsOf: int32ToLittleEndian(Int32(height)))                    // Height (positive = bottom-up)
        output.append(contentsOf: uint16ToLittleEndian(1))                               // Color planes
        output.append(contentsOf: uint16ToLittleEndian(32))                              // Bits per pixel
        output.append(contentsOf: uint32ToLittleEndian(BI_BITFIELDS))                    // Compression (bitfields for alpha)
        output.append(contentsOf: uint32ToLittleEndian(UInt32(imageSize)))               // Image size
        output.append(contentsOf: int32ToLittleEndian(2835))                             // X pixels per meter
        output.append(contentsOf: int32ToLittleEndian(2835))                             // Y pixels per meter
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Colors used
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Important colors

        // Color masks (BGRA format)
        output.append(contentsOf: uint32ToLittleEndian(0x00FF0000))                      // Red mask
        output.append(contentsOf: uint32ToLittleEndian(0x0000FF00))                      // Green mask
        output.append(contentsOf: uint32ToLittleEndian(0x000000FF))                      // Blue mask
        output.append(contentsOf: uint32ToLittleEndian(0xFF000000))                      // Alpha mask

        // Color space type (sRGB)
        output.append(contentsOf: [0x42, 0x47, 0x52, 0x73]) // "BGRs" - LCS_sRGB

        // CIEXYZTRIPLE endpoints (36 bytes of zeros for sRGB)
        output.append(contentsOf: [UInt8](repeating: 0, count: 36))

        // Gamma values (0 for sRGB)
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Red gamma
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Green gamma
        output.append(contentsOf: uint32ToLittleEndian(0))                               // Blue gamma

        // Pixel Data (BGRA format, bottom-up row order)
        for y in (0..<height).reversed() {
            for x in 0..<width {
                let srcIndex = y * image.bytesPerRow + x * 4
                if srcIndex + 3 < imageData.count {
                    output.append(imageData[srcIndex + 2]) // B
                    output.append(imageData[srcIndex + 1]) // G
                    output.append(imageData[srcIndex])     // R
                    output.append(imageData[srcIndex + 3]) // A
                } else {
                    output.append(contentsOf: [0, 0, 0, 255])
                }
            }
        }

        return output
    }

    // MARK: - Helper Functions

    private static func imageHasAlpha(_ image: CGImage) -> Bool {
        let alphaInfo = image.alphaInfo
        switch alphaInfo {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false
        default:
            return true
        }
    }

    private static func uint16ToLittleEndian(_ value: UInt16) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }

    private static func uint32ToLittleEndian(_ value: UInt32) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }

    private static func int32ToLittleEndian(_ value: Int32) -> [UInt8] {
        return withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }
}
