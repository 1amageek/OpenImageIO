// TestHelpers.swift
// OpenImageIO Tests
//
// Common test data and utilities for OpenImageIO tests

import Foundation
@testable import OpenImageIO
import OpenCoreGraphics

/// Test data generators for various image formats
enum TestData {

    // MARK: - CRC32 Helper

    private static func crc32(_ data: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crc32Table[index] ^ (crc >> 8)
        }
        return ~crc
    }

    private static let crc32Table: [UInt32] = {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var crc = UInt32(i)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1
            }
            table[i] = crc
        }
        return table
    }()

    private static func adler32(_ data: [UInt8]) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        for byte in data {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }

    // MARK: - PNG Chunk Helper

    private static func createPNGChunk(type: [UInt8], data: [UInt8]) -> [UInt8] {
        var chunk: [UInt8] = []

        // Length (big-endian)
        let length = UInt32(data.count)
        chunk.append(UInt8((length >> 24) & 0xFF))
        chunk.append(UInt8((length >> 16) & 0xFF))
        chunk.append(UInt8((length >> 8) & 0xFF))
        chunk.append(UInt8(length & 0xFF))

        // Type
        chunk.append(contentsOf: type)

        // Data
        chunk.append(contentsOf: data)

        // CRC (over type + data)
        var crcInput = type
        crcInput.append(contentsOf: data)
        let crc = crc32(crcInput)
        chunk.append(UInt8((crc >> 24) & 0xFF))
        chunk.append(UInt8((crc >> 16) & 0xFF))
        chunk.append(UInt8((crc >> 8) & 0xFF))
        chunk.append(UInt8(crc & 0xFF))

        return chunk
    }

    // MARK: - Deflate Helper (Stored blocks - no compression)

    private static func deflateStored(_ data: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []

        // zlib header
        output.append(0x78) // CMF: CM=8, CINFO=7
        output.append(0x01) // FLG: FCHECK makes (CMF*256+FLG) % 31 == 0

        // Split into blocks if needed (max 65535 bytes per block)
        let maxBlockSize = 65535
        var offset = 0

        while offset < data.count {
            let remaining = data.count - offset
            let blockSize = min(remaining, maxBlockSize)
            let isFinal = (offset + blockSize) >= data.count

            // Block header: BFINAL (1 bit) + BTYPE (2 bits) = 3 bits
            // BTYPE = 00 (stored), so header is just 0x00 or 0x01 for final
            output.append(isFinal ? 0x01 : 0x00)

            let len = UInt16(blockSize)
            let nlen = ~len

            output.append(UInt8(len & 0xFF))
            output.append(UInt8((len >> 8) & 0xFF))
            output.append(UInt8(nlen & 0xFF))
            output.append(UInt8((nlen >> 8) & 0xFF))

            output.append(contentsOf: data[offset..<(offset + blockSize)])
            offset += blockSize
        }

        // Adler-32 checksum
        let checksum = adler32(data)
        output.append(UInt8((checksum >> 24) & 0xFF))
        output.append(UInt8((checksum >> 16) & 0xFF))
        output.append(UInt8((checksum >> 8) & 0xFF))
        output.append(UInt8(checksum & 0xFF))

        return output
    }

    // MARK: - PNG Test Data

    /// Minimal valid PNG (1x1 RGBA pixel - red)
    static var minimalPNG: Data {
        var data: [UInt8] = []

        // PNG signature
        data.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        // IHDR chunk
        var ihdrData: [UInt8] = []
        ihdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // width = 1
        ihdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // height = 1
        ihdrData.append(0x08) // bit depth = 8
        ihdrData.append(0x06) // color type = 6 (RGBA)
        ihdrData.append(0x00) // compression = 0
        ihdrData.append(0x00) // filter = 0
        ihdrData.append(0x00) // interlace = 0
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x48, 0x44, 0x52], data: ihdrData))

        // IDAT chunk - scanline: filter(0) + RGBA(255, 0, 0, 255) = red pixel
        let scanline: [UInt8] = [0x00, 0xFF, 0x00, 0x00, 0xFF] // Filter None + Red RGBA
        let compressedData = deflateStored(scanline)
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x44, 0x41, 0x54], data: compressedData))

        // IEND chunk
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x45, 0x4E, 0x44], data: []))

        return Data(data)
    }

    /// PNG with specified dimensions (fully decodable)
    static func pngWithDimensions(width: Int, height: Int) -> Data {
        var data: [UInt8] = []

        // PNG signature
        data.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        // IHDR chunk
        var ihdrData: [UInt8] = []
        ihdrData.append(UInt8((width >> 24) & 0xFF))
        ihdrData.append(UInt8((width >> 16) & 0xFF))
        ihdrData.append(UInt8((width >> 8) & 0xFF))
        ihdrData.append(UInt8(width & 0xFF))
        ihdrData.append(UInt8((height >> 24) & 0xFF))
        ihdrData.append(UInt8((height >> 16) & 0xFF))
        ihdrData.append(UInt8((height >> 8) & 0xFF))
        ihdrData.append(UInt8(height & 0xFF))
        ihdrData.append(0x08) // bit depth = 8
        ihdrData.append(0x06) // color type = 6 (RGBA)
        ihdrData.append(0x00) // compression = 0
        ihdrData.append(0x00) // filter = 0
        ihdrData.append(0x00) // interlace = 0
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x48, 0x44, 0x52], data: ihdrData))

        // IDAT chunk - create scanlines with filter byte + RGBA pixels
        var scanlines: [UInt8] = []
        for _ in 0..<height {
            scanlines.append(0x00) // Filter None
            for _ in 0..<width {
                scanlines.append(contentsOf: [0xFF, 0x00, 0x00, 0xFF]) // Red RGBA
            }
        }
        let compressedData = deflateStored(scanlines)
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x44, 0x41, 0x54], data: compressedData))

        // IEND chunk
        data.append(contentsOf: createPNGChunk(type: [0x49, 0x45, 0x4E, 0x44], data: []))

        return Data(data)
    }

    // MARK: - JPEG Test Data

    /// Complete JPEG produced by the package encoder.
    static var minimalJPEG: Data {
        makeJPEG(width: 8, height: 8)
    }

    /// Complete JPEG with the specified dimensions.
    static func jpegWithDimensions(width: Int, height: Int) -> Data {
        makeJPEG(width: width, height: height)
    }

    private static func makeJPEG(width: Int, height: Int) -> Data {
        let image = createTestImage(width: width, height: height)
        guard let data = JPEGEncoder.encode(image: image) else {
            fatalError("The JPEG test fixture encoder failed")
        }
        return data
    }

    // MARK: - GIF Test Data

    /// Complete minimal GIF (1x1 red pixel)
    static var minimalGIF: Data {
        var data: [UInt8] = []

        // GIF89a header
        data.append(contentsOf: Array("GIF89a".utf8))

        // Logical screen descriptor
        data.append(contentsOf: [0x01, 0x00]) // Width = 1
        data.append(contentsOf: [0x01, 0x00]) // Height = 1
        // Packed byte: GCT flag=1, color resolution=1, sort=0, GCT size=0 (2 colors)
        data.append(0x80) // Has global color table, 2 colors (2^(0+1))
        data.append(0x00) // Background color index
        data.append(0x00) // Pixel aspect ratio

        // Global Color Table (2 colors: red, black)
        data.append(contentsOf: [0xFF, 0x00, 0x00]) // Color 0: Red
        data.append(contentsOf: [0x00, 0x00, 0x00]) // Color 1: Black

        // Image descriptor
        data.append(0x2C) // Image separator
        data.append(contentsOf: [0x00, 0x00]) // Left
        data.append(contentsOf: [0x00, 0x00]) // Top
        data.append(contentsOf: [0x01, 0x00]) // Width = 1
        data.append(contentsOf: [0x01, 0x00]) // Height = 1
        data.append(0x00) // No local color table

        // Image data
        data.append(0x02) // LZW minimum code size = 2
        // LZW encoded data for single pixel (index 0):
        // Clear code = 4, data = 0, end code = 5
        // Bits: 100 000 101 -> packed as: 00010100 00000101 -> 0x84, 0x01 (reversed bit order for GIF)
        // Actually GIF uses LSB first, so: 100(clear)=4, 000(data)=0, 101(end)=5
        // Packed LSB first: 000 100 | 101 000 -> 0x04 0x01
        // Let me use a known working sequence
        data.append(0x02) // Block size
        data.append(0x44) // LZW data
        data.append(0x01) // LZW data
        data.append(0x00) // Block terminator

        // Trailer
        data.append(0x3B)

        return Data(data)
    }

    /// GIF with multiple frames (animated) with color table
    static func animatedGIF(frameCount: Int, width: Int, height: Int) -> Data {
        var data: [UInt8] = []

        // GIF89a header
        data.append(contentsOf: Array("GIF89a".utf8))

        // Logical screen descriptor
        data.append(UInt8(width & 0xFF))
        data.append(UInt8((width >> 8) & 0xFF))
        data.append(UInt8(height & 0xFF))
        data.append(UInt8((height >> 8) & 0xFF))
        // Packed byte: GCT flag=1, color resolution=1, sort=0, GCT size=0 (2 colors)
        data.append(0x80)
        data.append(0x00) // Background color index
        data.append(0x00) // Pixel aspect ratio

        // Global Color Table (2 colors)
        data.append(contentsOf: [0xFF, 0x00, 0x00]) // Color 0: Red
        data.append(contentsOf: [0x00, 0x00, 0xFF]) // Color 1: Blue

        // Add frames
        for _ in 0..<frameCount {
            // Graphic Control Extension (for animation)
            data.append(0x21) // Extension introducer
            data.append(0xF9) // Graphic control label
            data.append(0x04) // Block size
            data.append(0x00) // Disposal method, no transparency
            data.append(contentsOf: [0x0A, 0x00]) // Delay time = 10 (100ms)
            data.append(0x00) // Transparent color index
            data.append(0x00) // Block terminator

            // Image descriptor
            data.append(0x2C) // Image separator
            data.append(contentsOf: [0x00, 0x00]) // Left
            data.append(contentsOf: [0x00, 0x00]) // Top
            data.append(UInt8(width & 0xFF))
            data.append(UInt8((width >> 8) & 0xFF))
            data.append(UInt8(height & 0xFF))
            data.append(UInt8((height >> 8) & 0xFF))
            data.append(0x00) // No local color table

            // Image data - simplified LZW for solid color
            data.append(0x02) // LZW minimum code size
            data.append(0x02) // Block size
            data.append(0x44) // LZW data (clear + pixel 0 + end)
            data.append(0x01)
            data.append(0x00) // Block terminator
        }

        // Trailer
        data.append(0x3B)

        return Data(data)
    }

    // MARK: - BMP Test Data

    /// Minimal valid BMP
    static var minimalBMP: Data {
        var data: [UInt8] = []

        // BMP header
        data.append(contentsOf: Array("BM".utf8))

        // File size
        data.append(contentsOf: [0x46, 0x00, 0x00, 0x00]) // 70 bytes

        // Reserved
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Data offset
        data.append(contentsOf: [0x36, 0x00, 0x00, 0x00]) // 54 bytes

        // DIB header size
        data.append(contentsOf: [0x28, 0x00, 0x00, 0x00]) // 40 bytes

        // Width
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // 2

        // Height
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // 2

        // Planes
        data.append(contentsOf: [0x01, 0x00])

        // Bits per pixel
        data.append(contentsOf: [0x18, 0x00]) // 24

        // Compression
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Image size
        data.append(contentsOf: [0x10, 0x00, 0x00, 0x00]) // 16 bytes

        // Resolution
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Colors
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Pixel data (2x2, 24-bit)
        data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00])
        data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00])

        return Data(data)
    }

    // MARK: - TIFF Test Data

    /// Complete minimal TIFF (2x2 RGB, little-endian, uncompressed)
    static var minimalTIFF: Data {
        var data: [UInt8] = []

        // TIFF header (little-endian)
        data.append(contentsOf: [0x49, 0x49]) // "II" (little-endian)
        data.append(contentsOf: [0x2A, 0x00]) // Magic number 42
        data.append(contentsOf: [0x08, 0x00, 0x00, 0x00]) // IFD offset = 8

        // IFD starts at offset 8
        data.append(contentsOf: [0x0A, 0x00]) // Number of entries = 10

        // Entry 1: ImageWidth (tag 256)
        data.append(contentsOf: [0x00, 0x01]) // Tag = 256
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // Value = 2

        // Entry 2: ImageLength (tag 257)
        data.append(contentsOf: [0x01, 0x01]) // Tag = 257
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // Value = 2

        // Entry 3: BitsPerSample (tag 258)
        data.append(contentsOf: [0x02, 0x01]) // Tag = 258
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x03, 0x00, 0x00, 0x00]) // Count = 3
        data.append(contentsOf: [0x86, 0x00, 0x00, 0x00]) // Offset to values (134)

        // Entry 4: Compression (tag 259)
        data.append(contentsOf: [0x03, 0x01]) // Tag = 259
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Value = 1 (none)

        // Entry 5: PhotometricInterpretation (tag 262)
        data.append(contentsOf: [0x06, 0x01]) // Tag = 262
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // Value = 2 (RGB)

        // Entry 6: StripOffsets (tag 273)
        data.append(contentsOf: [0x11, 0x01]) // Tag = 273
        data.append(contentsOf: [0x04, 0x00]) // Type = LONG
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x8C, 0x00, 0x00, 0x00]) // Value = 140 (pixel data offset)

        // Entry 7: SamplesPerPixel (tag 277)
        data.append(contentsOf: [0x15, 0x01]) // Tag = 277
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x03, 0x00, 0x00, 0x00]) // Value = 3 (RGB)

        // Entry 8: RowsPerStrip (tag 278)
        data.append(contentsOf: [0x16, 0x01]) // Tag = 278
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x02, 0x00, 0x00, 0x00]) // Value = 2

        // Entry 9: StripByteCounts (tag 279)
        data.append(contentsOf: [0x17, 0x01]) // Tag = 279
        data.append(contentsOf: [0x04, 0x00]) // Type = LONG
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x0C, 0x00, 0x00, 0x00]) // Value = 12 (2*2*3)

        // Entry 10: ResolutionUnit (tag 296) - optional but common
        data.append(contentsOf: [0x28, 0x01]) // Tag = 296
        data.append(contentsOf: [0x03, 0x00]) // Type = SHORT
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count = 1
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Value = 1 (no unit)

        // Next IFD offset (none)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // BitsPerSample values at offset 134 (3 SHORT values: 8, 8, 8)
        data.append(contentsOf: [0x08, 0x00, 0x08, 0x00, 0x08, 0x00])

        // Pixel data at offset 140 (2x2 RGB = 12 bytes)
        // White pixels: RGB(255, 255, 255)
        data.append(contentsOf: [0xFF, 0xFF, 0xFF]) // Pixel (0,0)
        data.append(contentsOf: [0xFF, 0xFF, 0xFF]) // Pixel (1,0)
        data.append(contentsOf: [0xFF, 0xFF, 0xFF]) // Pixel (0,1)
        data.append(contentsOf: [0xFF, 0xFF, 0xFF]) // Pixel (1,1)

        return Data(data)
    }

    // MARK: - WebP Test Data

    /// Minimal valid WebP (lossy VP8)
    static var minimalWebP: Data {
        var data: [UInt8] = []

        // RIFF header
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(contentsOf: [0x24, 0x00, 0x00, 0x00]) // File size - 8
        data.append(contentsOf: Array("WEBP".utf8))

        // VP8 chunk
        data.append(contentsOf: Array("VP8 ".utf8))
        data.append(contentsOf: [0x14, 0x00, 0x00, 0x00]) // Chunk size

        // VP8 frame header
        data.append(contentsOf: [0x9D, 0x01, 0x2A]) // Frame tag
        data.append(contentsOf: [0x10, 0x00]) // Width = 16
        data.append(contentsOf: [0x10, 0x00]) // Height = 16
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00])

        return Data(data)
    }

    // MARK: - Invalid Data

    /// Empty data
    static var emptyData: Data { Data() }

    /// Random invalid data
    static var invalidData: Data {
        Data([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE])
    }

    /// Truncated PNG (missing chunks)
    static var truncatedPNG: Data {
        // Only PNG signature, no chunks
        return Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    }

    // MARK: - XMP Test Data

    /// Sample XMP data
    static var sampleXMP: Data {
        let xmpString = """
        <?xpacket begin='\u{feff}' id='W5M0MpCehiHzreSzNTczkc9d'?>
        <x:xmpmeta xmlns:x='adobe:ns:meta/'>
        <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
        <rdf:Description rdf:about=''
         xmlns:dc='http://purl.org/dc/elements/1.1/'>
        <dc:title>Test Image Title</dc:title>
        </rdf:Description>
        </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end='w'?>
        """
        return Data(xmpString.utf8)
    }
}

/// Helper to create test CGImage instances
func createTestImage(width: Int, height: Int, fill: UInt8 = 255) -> CGImage {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        fatalError("Failed to create color space for test image")
    }

    let bytesPerRow = width * 4
    let data = [UInt8](repeating: fill, count: bytesPerRow * height)
    let provider = CGDataProvider(data: Data(data))

    guard let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    ) else {
        fatalError("Failed to create test image")
    }

    return image
}
