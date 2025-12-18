// ColorQuantizer.swift
// OpenImageIO
//
// Color quantization algorithms: Median Cut and Floyd-Steinberg dithering

import Foundation

/// Color quantization using the Median Cut algorithm
internal struct MedianCutQuantizer {

    // MARK: - Types

    /// A box in color space containing a set of colors
    private struct ColorBox {
        var colors: [(r: Int, g: Int, b: Int, count: Int)]
        var rMin: Int, rMax: Int
        var gMin: Int, gMax: Int
        var bMin: Int, bMax: Int

        var volume: Int {
            return (rMax - rMin + 1) * (gMax - gMin + 1) * (bMax - bMin + 1)
        }

        var pixelCount: Int {
            return colors.reduce(0) { $0 + $1.count }
        }

        /// The axis with the largest range
        var longestAxis: Axis {
            let rRange = rMax - rMin
            let gRange = gMax - gMin
            let bRange = bMax - bMin

            if rRange >= gRange && rRange >= bRange {
                return .red
            } else if gRange >= bRange {
                return .green
            } else {
                return .blue
            }
        }

        /// Calculate the representative color (weighted average)
        var representativeColor: (r: UInt8, g: UInt8, b: UInt8) {
            guard !colors.isEmpty else { return (128, 128, 128) }

            var totalR = 0
            var totalG = 0
            var totalB = 0
            var totalCount = 0

            for color in colors {
                totalR += color.r * color.count
                totalG += color.g * color.count
                totalB += color.b * color.count
                totalCount += color.count
            }

            guard totalCount > 0 else { return (128, 128, 128) }

            return (
                r: UInt8(clamping: totalR / totalCount),
                g: UInt8(clamping: totalG / totalCount),
                b: UInt8(clamping: totalB / totalCount)
            )
        }

        mutating func recalculateBounds() {
            guard !colors.isEmpty else { return }

            rMin = 255; rMax = 0
            gMin = 255; gMax = 0
            bMin = 255; bMax = 0

            for color in colors {
                rMin = min(rMin, color.r)
                rMax = max(rMax, color.r)
                gMin = min(gMin, color.g)
                gMax = max(gMax, color.g)
                bMin = min(bMin, color.b)
                bMax = max(bMax, color.b)
            }
        }
    }

    private enum Axis {
        case red, green, blue
    }

    // MARK: - Public API

    /// Quantize colors to a maximum of 256 colors using Median Cut
    /// - Parameter pixels: Array of RGB pixels (3 bytes per pixel: R, G, B)
    /// - Returns: Tuple of (palette, indexed pixels)
    static func quantize(pixels: [UInt8], width: Int, height: Int, maxColors: Int = 256) -> (palette: [UInt8], indices: [UInt8])? {
        guard pixels.count >= width * height * 3 else { return nil }
        guard maxColors >= 2 && maxColors <= 256 else { return nil }

        // Build color histogram
        var histogram: [Int: (r: Int, g: Int, b: Int, count: Int)] = [:]

        for i in stride(from: 0, to: pixels.count, by: 3) {
            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])
            let key = (r << 16) | (g << 8) | b

            if var existing = histogram[key] {
                existing.count += 1
                histogram[key] = existing
            } else {
                histogram[key] = (r: r, g: g, b: b, count: 1)
            }
        }

        // If we have fewer unique colors than maxColors, use them directly
        if histogram.count <= maxColors {
            return buildDirectPalette(histogram: histogram, pixels: pixels, maxColors: maxColors)
        }

        // Create initial box with all colors
        let colors = Array(histogram.values)
        var initialBox = ColorBox(
            colors: colors,
            rMin: 0, rMax: 255,
            gMin: 0, gMax: 255,
            bMin: 0, bMax: 255
        )
        initialBox.recalculateBounds()

        // Split boxes until we have maxColors
        var boxes = [initialBox]

        while boxes.count < maxColors {
            // Find the box with the largest volume * pixel count (for better distribution)
            let splittableBoxes = boxes.enumerated().filter { $0.element.colors.count > 1 }
            guard let bestBox = splittableBoxes.max(by: {
                ($0.element.volume * $0.element.pixelCount) < ($1.element.volume * $1.element.pixelCount)
            }) else {
                break
            }
            let boxIndex = bestBox.offset

            // Split the box
            let box = boxes[boxIndex]
            guard let (box1, box2) = splitBox(box) else {
                break
            }

            boxes[boxIndex] = box1
            boxes.append(box2)
        }

        // Build palette from box representatives
        var palette = [UInt8]()
        var colorToIndex: [Int: Int] = [:]

        for (index, box) in boxes.enumerated() {
            let color = box.representativeColor
            palette.append(color.r)
            palette.append(color.g)
            palette.append(color.b)

            // Map all colors in this box to this palette index
            for c in box.colors {
                let key = (c.r << 16) | (c.g << 8) | c.b
                colorToIndex[key] = index
            }
        }

        // Pad palette to power of 2
        let paletteSize = nextPowerOf2(boxes.count)
        while palette.count < paletteSize * 3 {
            palette.append(0)
        }

        // Build palette lookup for colors not directly in a box
        let paletteColors = (0..<boxes.count).map { i -> (r: Int, g: Int, b: Int) in
            (Int(palette[i * 3]), Int(palette[i * 3 + 1]), Int(palette[i * 3 + 2]))
        }

        // Map pixels to indices
        var indices = [UInt8]()
        indices.reserveCapacity(width * height)

        for i in stride(from: 0, to: pixels.count, by: 3) {
            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])
            let key = (r << 16) | (g << 8) | b

            if let index = colorToIndex[key] {
                indices.append(UInt8(index))
            } else {
                // Find closest color in palette
                let index = findClosestColor(r: r, g: g, b: b, palette: paletteColors)
                indices.append(UInt8(index))
            }
        }

        return (palette, indices)
    }

    // MARK: - Private Helpers

    private static func buildDirectPalette(
        histogram: [Int: (r: Int, g: Int, b: Int, count: Int)],
        pixels: [UInt8],
        maxColors: Int
    ) -> (palette: [UInt8], indices: [UInt8]) {
        var palette = [UInt8]()
        var colorToIndex: [Int: Int] = [:]
        var index = 0

        for (key, color) in histogram {
            palette.append(UInt8(color.r))
            palette.append(UInt8(color.g))
            palette.append(UInt8(color.b))
            colorToIndex[key] = index
            index += 1
        }

        // Pad to power of 2
        let paletteSize = nextPowerOf2(histogram.count)
        while palette.count < paletteSize * 3 {
            palette.append(0)
        }

        var indices = [UInt8]()
        for i in stride(from: 0, to: pixels.count, by: 3) {
            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])
            let key = (r << 16) | (g << 8) | b
            indices.append(UInt8(colorToIndex[key] ?? 0))
        }

        return (palette, indices)
    }

    private static func splitBox(_ box: ColorBox) -> (ColorBox, ColorBox)? {
        guard box.colors.count > 1 else { return nil }

        let axis = box.longestAxis
        var sortedColors = box.colors

        // Sort by the longest axis
        switch axis {
        case .red:
            sortedColors.sort { $0.r < $1.r }
        case .green:
            sortedColors.sort { $0.g < $1.g }
        case .blue:
            sortedColors.sort { $0.b < $1.b }
        }

        // Find median by pixel count
        let totalPixels = box.pixelCount
        var runningCount = 0
        var medianIndex = sortedColors.count / 2

        for (i, color) in sortedColors.enumerated() {
            runningCount += color.count
            if runningCount >= totalPixels / 2 {
                medianIndex = max(1, i)
                break
            }
        }

        // Ensure we don't create empty boxes
        medianIndex = min(medianIndex, sortedColors.count - 1)
        if medianIndex == 0 { medianIndex = 1 }

        let colors1 = Array(sortedColors[0..<medianIndex])
        let colors2 = Array(sortedColors[medianIndex...])

        var box1 = ColorBox(
            colors: colors1,
            rMin: box.rMin, rMax: box.rMax,
            gMin: box.gMin, gMax: box.gMax,
            bMin: box.bMin, bMax: box.bMax
        )
        box1.recalculateBounds()

        var box2 = ColorBox(
            colors: colors2,
            rMin: box.rMin, rMax: box.rMax,
            gMin: box.gMin, gMax: box.gMax,
            bMin: box.bMin, bMax: box.bMax
        )
        box2.recalculateBounds()

        return (box1, box2)
    }

    private static func findClosestColor(r: Int, g: Int, b: Int, palette: [(r: Int, g: Int, b: Int)]) -> Int {
        var bestIndex = 0
        var bestDistance = Int.max

        for (i, color) in palette.enumerated() {
            let dr = r - color.r
            let dg = g - color.g
            let db = b - color.b
            let distance = dr * dr + dg * dg + db * db

            if distance < bestDistance {
                bestDistance = distance
                bestIndex = i
            }

            if distance == 0 { break }
        }

        return bestIndex
    }

    private static func nextPowerOf2(_ n: Int) -> Int {
        var power = 2
        while power < n {
            power *= 2
        }
        return min(power, 256)
    }
}

// MARK: - Floyd-Steinberg Dithering

/// Floyd-Steinberg error diffusion dithering
internal struct FloydSteinbergDithering {

    /// Apply Floyd-Steinberg dithering to an image
    /// - Parameters:
    ///   - pixels: RGB pixels (3 bytes per pixel)
    ///   - width: Image width
    ///   - height: Image height
    ///   - palette: Color palette (3 bytes per color)
    /// - Returns: Palette indices for each pixel
    static func dither(
        pixels: [UInt8],
        width: Int,
        height: Int,
        palette: [UInt8]
    ) -> [UInt8] {
        guard pixels.count >= width * height * 3 else { return [] }

        // Convert palette to color tuples
        let paletteColors: [(r: Int, g: Int, b: Int)] = stride(from: 0, to: palette.count, by: 3).map {
            (Int(palette[$0]), Int(palette[$0 + 1]), Int(palette[$0 + 2]))
        }

        // Create working buffer with signed integers for error accumulation
        var errorBuffer = [[Int]](repeating: [Int](repeating: 0, count: width * 3), count: 2)
        var indices = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            let currentRow = y % 2
            let nextRow = (y + 1) % 2

            // Clear next row error buffer
            for x in 0..<(width * 3) {
                errorBuffer[nextRow][x] = 0
            }

            for x in 0..<width {
                let srcIdx = (y * width + x) * 3
                let errorIdx = x * 3

                // Get original color with accumulated error
                var r = Int(pixels[srcIdx]) + errorBuffer[currentRow][errorIdx]
                var g = Int(pixels[srcIdx + 1]) + errorBuffer[currentRow][errorIdx + 1]
                var b = Int(pixels[srcIdx + 2]) + errorBuffer[currentRow][errorIdx + 2]

                // Clamp to valid range
                r = max(0, min(255, r))
                g = max(0, min(255, g))
                b = max(0, min(255, b))

                // Find closest palette color
                let paletteIndex = findClosestPaletteColor(r: r, g: g, b: b, palette: paletteColors)
                indices[y * width + x] = UInt8(paletteIndex)

                // Calculate quantization error
                let palR = paletteColors[paletteIndex].r
                let palG = paletteColors[paletteIndex].g
                let palB = paletteColors[paletteIndex].b

                let errR = r - palR
                let errG = g - palG
                let errB = b - palB

                // Distribute error to neighboring pixels using Floyd-Steinberg matrix:
                // [    *   7/16 ]
                // [ 3/16  5/16  1/16 ]

                // Right pixel (7/16)
                if x + 1 < width {
                    errorBuffer[currentRow][(x + 1) * 3] += errR * 7 / 16
                    errorBuffer[currentRow][(x + 1) * 3 + 1] += errG * 7 / 16
                    errorBuffer[currentRow][(x + 1) * 3 + 2] += errB * 7 / 16
                }

                // Bottom-left pixel (3/16)
                if y + 1 < height && x > 0 {
                    errorBuffer[nextRow][(x - 1) * 3] += errR * 3 / 16
                    errorBuffer[nextRow][(x - 1) * 3 + 1] += errG * 3 / 16
                    errorBuffer[nextRow][(x - 1) * 3 + 2] += errB * 3 / 16
                }

                // Bottom pixel (5/16)
                if y + 1 < height {
                    errorBuffer[nextRow][x * 3] += errR * 5 / 16
                    errorBuffer[nextRow][x * 3 + 1] += errG * 5 / 16
                    errorBuffer[nextRow][x * 3 + 2] += errB * 5 / 16
                }

                // Bottom-right pixel (1/16)
                if y + 1 < height && x + 1 < width {
                    errorBuffer[nextRow][(x + 1) * 3] += errR * 1 / 16
                    errorBuffer[nextRow][(x + 1) * 3 + 1] += errG * 1 / 16
                    errorBuffer[nextRow][(x + 1) * 3 + 2] += errB * 1 / 16
                }
            }
        }

        return indices
    }

    private static func findClosestPaletteColor(
        r: Int,
        g: Int,
        b: Int,
        palette: [(r: Int, g: Int, b: Int)]
    ) -> Int {
        var bestIndex = 0
        var bestDistance = Int.max

        for (i, color) in palette.enumerated() {
            // Use weighted distance (green is more perceptually important)
            let dr = r - color.r
            let dg = g - color.g
            let db = b - color.b
            let distance = 2 * dr * dr + 4 * dg * dg + 3 * db * db

            if distance < bestDistance {
                bestDistance = distance
                bestIndex = i
            }

            if distance == 0 { break }
        }

        return bestIndex
    }
}
