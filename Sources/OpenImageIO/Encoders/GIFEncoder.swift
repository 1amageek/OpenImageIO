// GIFEncoder.swift
// OpenImageIO
//
// GIF image format encoder with LZW compression

import Foundation
import OpenCoreGraphics

/// GIF image encoder with LZW compression
internal struct GIFEncoder {

    // MARK: - Constants

    private static let GIF_SIGNATURE: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] // "GIF89a"
    private static let IMAGE_SEPARATOR: UInt8 = 0x2C
    private static let EXTENSION_INTRODUCER: UInt8 = 0x21
    private static let GRAPHIC_CONTROL_EXTENSION: UInt8 = 0xF9
    private static let APPLICATION_EXTENSION: UInt8 = 0xFF
    private static let TRAILER: UInt8 = 0x3B

    // MARK: - Public API

    /// Encode CGImage to GIF data
    static func encode(image: CGImage, options: [String: Any]? = nil) -> Data? {
        return encode(images: [image], options: options)
    }

    /// Encode multiple CGImages to animated GIF data
    static func encode(images: [CGImage], options: [String: Any]? = nil) -> Data? {
        guard let firstImage = images.first else { return nil }

        let width = firstImage.width
        let height = firstImage.height

        guard width > 0 && height > 0 && width <= 65535 && height <= 65535 else {
            return nil
        }

        // Build color palette from all images
        var allPixels: [[UInt8]] = []
        for image in images {
            guard let imageData = image.dataProvider?.data else { continue }

            // Determine source pixel format
            let srcBytesPerPixel = image.bitsPerPixel / 8
            let srcAlphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
            let srcIsARGB = (srcAlphaInfo == .premultipliedFirst || srcAlphaInfo == .first || srcAlphaInfo == .noneSkipFirst)

            var pixels: [UInt8] = []
            for y in 0..<image.height {
                for x in 0..<image.width {
                    let srcIndex = (y * image.bytesPerRow) + (x * srcBytesPerPixel)

                    // Extract RGB values based on source format
                    var r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0

                    if srcBytesPerPixel == 4 && srcIndex + 3 < imageData.count {
                        if srcIsARGB {
                            r = imageData[srcIndex + 1]
                            g = imageData[srcIndex + 2]
                            b = imageData[srcIndex + 3]
                        } else {
                            r = imageData[srcIndex]
                            g = imageData[srcIndex + 1]
                            b = imageData[srcIndex + 2]
                        }
                    } else if srcBytesPerPixel == 3 && srcIndex + 2 < imageData.count {
                        r = imageData[srcIndex]
                        g = imageData[srcIndex + 1]
                        b = imageData[srcIndex + 2]
                    } else if srcBytesPerPixel == 1 && srcIndex < imageData.count {
                        let gray = imageData[srcIndex]
                        r = gray
                        g = gray
                        b = gray
                    }

                    pixels.append(r)
                    pixels.append(g)
                    pixels.append(b)
                }
            }
            allPixels.append(pixels)
        }

        // Build global color table using Median Cut quantization
        let (colorTable, colorCount) = buildColorTable(allPixels, width: width, height: height)

        var output = Data()

        // GIF Header
        output.append(contentsOf: GIF_SIGNATURE)

        // Logical Screen Descriptor
        output.append(contentsOf: withUnsafeBytes(of: UInt16(width).littleEndian) { Array($0) })
        output.append(contentsOf: withUnsafeBytes(of: UInt16(height).littleEndian) { Array($0) })

        // Packed byte: global color table flag, color resolution, sort flag, size of global color table
        let colorTableSizeBits = colorTableSizeToFlag(colorCount)
        let packedByte: UInt8 = 0x80 | (7 << 4) | colorTableSizeBits
        output.append(packedByte)
        output.append(0x00) // Background color index
        output.append(0x00) // Pixel aspect ratio

        // Global Color Table
        output.append(contentsOf: colorTable)

        // NETSCAPE extension for animation (if multiple frames)
        if images.count > 1 {
            output.append(EXTENSION_INTRODUCER)
            output.append(APPLICATION_EXTENSION)
            output.append(0x0B) // Block size
            output.append(contentsOf: Array("NETSCAPE2.0".utf8))
            output.append(0x03) // Sub-block size
            output.append(0x01) // Sub-block ID
            output.append(contentsOf: withUnsafeBytes(of: UInt16(0).littleEndian) { Array($0) }) // Loop count (0 = infinite)
            output.append(0x00) // Block terminator
        }

        // Get delay from options
        let delayTime: UInt16
        if let delay = options?["delay"] as? Double {
            delayTime = UInt16(delay * 100) // Convert seconds to centiseconds
        } else {
            delayTime = 10 // Default 0.1 seconds
        }

        // Encode each frame
        for (_, image) in images.enumerated() {
            guard let imageData = image.dataProvider?.data else { continue }

            // Graphic Control Extension
            if images.count > 1 || hasTransparency(image) {
                output.append(EXTENSION_INTRODUCER)
                output.append(GRAPHIC_CONTROL_EXTENSION)
                output.append(0x04) // Block size

                // Packed byte: disposal method (1), user input (0), transparent color flag
                var gcPackedByte: UInt8 = 0x04 // Disposal method 1 (do not dispose)
                if hasTransparency(image) {
                    gcPackedByte |= 0x01
                }
                output.append(gcPackedByte)

                output.append(contentsOf: withUnsafeBytes(of: delayTime.littleEndian) { Array($0) })
                output.append(hasTransparency(image) ? 0xFF : 0x00) // Transparent color index
                output.append(0x00) // Block terminator
            }

            // Image Descriptor
            output.append(IMAGE_SEPARATOR)
            output.append(contentsOf: [0x00, 0x00]) // Left position
            output.append(contentsOf: [0x00, 0x00]) // Top position
            output.append(contentsOf: withUnsafeBytes(of: UInt16(image.width).littleEndian) { Array($0) })
            output.append(contentsOf: withUnsafeBytes(of: UInt16(image.height).littleEndian) { Array($0) })
            output.append(0x00) // Packed byte (no local color table)

            // Quantize pixels to color indices
            let indexedPixels = quantizeImage(imageData: imageData, image: image, colorTable: colorTable)

            // LZW encode
            let minCodeSize: UInt8 = 8
            output.append(minCodeSize)

            // Compress with LZW
            if let compressed = LZW.encode(data: Data(indexedPixels), minCodeSize: Int(minCodeSize)) {
                // Write as sub-blocks
                writeSubBlocks(data: compressed, to: &output)
            } else {
                // Fallback: write uncompressed as sub-blocks
                writeSubBlocks(data: Data(indexedPixels), to: &output)
            }

            output.append(0x00) // Block terminator
        }

        // GIF Trailer
        output.append(TRAILER)

        return output
    }

    // MARK: - Color Quantization

    private static func buildColorTable(_ allPixels: [[UInt8]], width: Int, height: Int) -> ([UInt8], Int) {
        // Combine all pixels for quantization
        var combinedPixels: [UInt8] = []
        for pixels in allPixels {
            combinedPixels.append(contentsOf: pixels)
        }

        // Count unique colors first
        var uniqueColors = Set<UInt32>()
        for i in stride(from: 0, to: combinedPixels.count, by: 3) {
            let colorKey = (UInt32(combinedPixels[i]) << 16) |
                          (UInt32(combinedPixels[i + 1]) << 8) |
                          UInt32(combinedPixels[i + 2])
            uniqueColors.insert(colorKey)
            if uniqueColors.count > 256 { break }
        }

        // If <= 256 unique colors, use them directly (better quality)
        if uniqueColors.count <= 256 {
            var colorTable: [UInt8] = []
            for color in uniqueColors {
                colorTable.append(UInt8((color >> 16) & 0xFF))
                colorTable.append(UInt8((color >> 8) & 0xFF))
                colorTable.append(UInt8(color & 0xFF))
            }
            let targetCount = nextPowerOf2(uniqueColors.count)
            while colorTable.count < targetCount * 3 {
                colorTable.append(0)
            }
            return (colorTable, targetCount)
        }

        // Use Median Cut quantization for > 256 colors
        let totalWidth = width
        let totalHeight = height * allPixels.count

        guard let (palette, _) = MedianCutQuantizer.quantize(
            pixels: combinedPixels,
            width: totalWidth,
            height: totalHeight,
            maxColors: 256
        ) else {
            // Fallback to simple approach
            return buildSimpleColorTable(allPixels)
        }

        let colorCount = palette.count / 3
        let targetCount = nextPowerOf2(colorCount)

        var colorTable = palette
        while colorTable.count < targetCount * 3 {
            colorTable.append(0)
        }

        return (colorTable, targetCount)
    }

    private static func buildSimpleColorTable(_ allPixels: [[UInt8]]) -> ([UInt8], Int) {
        // Fallback: collect first 256 unique colors
        var uniqueColors = Set<UInt32>()

        for pixels in allPixels {
            var i = 0
            while i + 2 < pixels.count {
                let colorKey = (UInt32(pixels[i]) << 16) | (UInt32(pixels[i + 1]) << 8) | UInt32(pixels[i + 2])
                uniqueColors.insert(colorKey)
                i += 3
                if uniqueColors.count >= 256 { break }
            }
            if uniqueColors.count >= 256 { break }
        }

        var colorTable: [UInt8] = []
        for color in uniqueColors.prefix(256) {
            colorTable.append(UInt8((color >> 16) & 0xFF))
            colorTable.append(UInt8((color >> 8) & 0xFF))
            colorTable.append(UInt8(color & 0xFF))
        }

        let targetCount = nextPowerOf2(uniqueColors.count)
        while colorTable.count < targetCount * 3 {
            colorTable.append(0)
        }

        return (colorTable, targetCount)
    }

    private static func quantizeImage(imageData: Data, image: CGImage, colorTable: [UInt8]) -> [UInt8] {
        var indexed: [UInt8] = []

        // Determine source pixel format
        let srcBytesPerPixel = image.bitsPerPixel / 8
        let srcAlphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let srcIsARGB = (srcAlphaInfo == .premultipliedFirst || srcAlphaInfo == .first || srcAlphaInfo == .noneSkipFirst)
        let srcHasAlpha = hasTransparency(image)

        for y in 0..<image.height {
            for x in 0..<image.width {
                let srcIndex = (y * image.bytesPerRow) + (x * srcBytesPerPixel)

                // Extract RGBA values based on source format
                var r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0, a: UInt8 = 255

                if srcBytesPerPixel == 4 && srcIndex + 3 < imageData.count {
                    if srcIsARGB {
                        a = imageData[srcIndex]
                        r = imageData[srcIndex + 1]
                        g = imageData[srcIndex + 2]
                        b = imageData[srcIndex + 3]
                    } else {
                        r = imageData[srcIndex]
                        g = imageData[srcIndex + 1]
                        b = imageData[srcIndex + 2]
                        a = imageData[srcIndex + 3]
                    }
                } else if srcBytesPerPixel == 3 && srcIndex + 2 < imageData.count {
                    r = imageData[srcIndex]
                    g = imageData[srcIndex + 1]
                    b = imageData[srcIndex + 2]
                } else if srcBytesPerPixel == 1 && srcIndex < imageData.count {
                    let gray = imageData[srcIndex]
                    r = gray
                    g = gray
                    b = gray
                }

                // If transparent, use transparent color index
                if srcHasAlpha && a < 128 {
                    indexed.append(0xFF)
                    continue
                }

                // Find closest color in palette
                let colorIndex = findClosestColor(r: r, g: g, b: b, colorTable: colorTable)
                indexed.append(UInt8(colorIndex))
            }
        }

        return indexed
    }

    private static func findClosestColor(r: UInt8, g: UInt8, b: UInt8, colorTable: [UInt8]) -> Int {
        var bestIndex = 0
        var bestDistance = Int.max

        let numColors = colorTable.count / 3

        for i in 0..<numColors {
            let cr = Int(colorTable[i * 3])
            let cg = Int(colorTable[i * 3 + 1])
            let cb = Int(colorTable[i * 3 + 2])

            let dr = Int(r) - cr
            let dg = Int(g) - cg
            let db = Int(b) - cb

            let distance = dr * dr + dg * dg + db * db

            if distance < bestDistance {
                bestDistance = distance
                bestIndex = i
            }

            if distance == 0 { break }
        }

        return bestIndex
    }

    // MARK: - Helper Functions

    private static func hasTransparency(_ image: CGImage) -> Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        switch alphaInfo {
        case .premultipliedLast, .premultipliedFirst, .last, .first, .alphaOnly:
            return true
        default:
            return false
        }
    }

    private static func colorTableSizeToFlag(_ count: Int) -> UInt8 {
        // Returns the flag value for GIF color table size
        // Flag value n means 2^(n+1) colors
        var size = 2
        var flag: UInt8 = 0
        while size < count && flag < 7 {
            size *= 2
            flag += 1
        }
        return flag
    }

    private static func nextPowerOf2(_ n: Int) -> Int {
        var power = 2
        while power < n {
            power *= 2
        }
        return min(power, 256)
    }

    private static func writeSubBlocks(data: Data, to output: inout Data) {
        var offset = 0
        while offset < data.count {
            let remaining = data.count - offset
            let blockSize = min(remaining, 255)

            output.append(UInt8(blockSize))
            output.append(data[offset..<(offset + blockSize)])

            offset += blockSize
        }
    }
}
