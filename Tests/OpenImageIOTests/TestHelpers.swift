// TestHelpers.swift
// OpenImageIO Tests
//
// Common test data and utilities for OpenImageIO tests

import Foundation
@testable import OpenImageIO

/// Test data generators for various image formats
enum TestData {

    // MARK: - PNG Test Data

    /// Minimal valid PNG (1x1 RGBA pixel)
    static var minimalPNG: [UInt8] {
        var data: [UInt8] = []

        // PNG signature
        data.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        // IHDR chunk
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x0D]) // length = 13
        data.append(contentsOf: [0x49, 0x48, 0x44, 0x52]) // "IHDR"
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // width = 1
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // height = 1
        data.append(0x08) // bit depth = 8
        data.append(0x06) // color type = 6 (RGBA)
        data.append(0x00) // compression = 0
        data.append(0x00) // filter = 0
        data.append(0x00) // interlace = 0
        data.append(contentsOf: [0x1F, 0x15, 0xC4, 0x89]) // CRC

        // IDAT chunk (minimal)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x0A]) // length
        data.append(contentsOf: [0x49, 0x44, 0x41, 0x54]) // "IDAT"
        data.append(contentsOf: [0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01])
        data.append(contentsOf: [0x0D, 0x0A, 0x2D, 0xB4]) // CRC

        // IEND chunk
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // length = 0
        data.append(contentsOf: [0x49, 0x45, 0x4E, 0x44]) // "IEND"
        data.append(contentsOf: [0xAE, 0x42, 0x60, 0x82]) // CRC

        return data
    }

    /// PNG with specified dimensions
    static func pngWithDimensions(width: Int, height: Int) -> [UInt8] {
        var data: [UInt8] = []

        // PNG signature
        data.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        // IHDR chunk
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x0D]) // length = 13
        data.append(contentsOf: [0x49, 0x48, 0x44, 0x52]) // "IHDR"

        // Width (big-endian)
        data.append(UInt8((width >> 24) & 0xFF))
        data.append(UInt8((width >> 16) & 0xFF))
        data.append(UInt8((width >> 8) & 0xFF))
        data.append(UInt8(width & 0xFF))

        // Height (big-endian)
        data.append(UInt8((height >> 24) & 0xFF))
        data.append(UInt8((height >> 16) & 0xFF))
        data.append(UInt8((height >> 8) & 0xFF))
        data.append(UInt8(height & 0xFF))

        data.append(0x08) // bit depth = 8
        data.append(0x06) // color type = 6 (RGBA)
        data.append(0x00) // compression = 0
        data.append(0x00) // filter = 0
        data.append(0x00) // interlace = 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // CRC placeholder

        return data
    }

    // MARK: - JPEG Test Data

    /// Minimal valid JPEG header
    static var minimalJPEG: [UInt8] {
        return [
            0xFF, 0xD8, 0xFF, 0xE0, // SOI + APP0
            0x00, 0x10,             // Length
            0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
            0x01, 0x01,             // Version
            0x00,                   // Units
            0x00, 0x01, 0x00, 0x01, // Density
            0x00, 0x00,             // Thumbnail
            0xFF, 0xC0,             // SOF0
            0x00, 0x0B,             // Length
            0x08,                   // Precision
            0x00, 0x10,             // Height = 16
            0x00, 0x20,             // Width = 32
            0x01,                   // Components
            0x01, 0x11, 0x00,       // Component info
            0xFF, 0xD9              // EOI
        ]
    }

    /// JPEG with specified dimensions
    static func jpegWithDimensions(width: Int, height: Int) -> [UInt8] {
        return [
            0xFF, 0xD8, 0xFF, 0xE0, // SOI + APP0
            0x00, 0x10,             // Length
            0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
            0x01, 0x01,             // Version
            0x00,                   // Units
            0x00, 0x01, 0x00, 0x01, // Density
            0x00, 0x00,             // Thumbnail
            0xFF, 0xC0,             // SOF0
            0x00, 0x0B,             // Length
            0x08,                   // Precision
            UInt8((height >> 8) & 0xFF), UInt8(height & 0xFF), // Height
            UInt8((width >> 8) & 0xFF), UInt8(width & 0xFF),   // Width
            0x01,                   // Components
            0x01, 0x11, 0x00,       // Component info
            0xFF, 0xD9              // EOI
        ]
    }

    // MARK: - GIF Test Data

    /// Minimal valid GIF
    static var minimalGIF: [UInt8] {
        var data: [UInt8] = []

        // GIF89a header
        data.append(contentsOf: Array("GIF89a".utf8))

        // Logical screen descriptor
        data.append(contentsOf: [0x01, 0x00]) // Width = 1
        data.append(contentsOf: [0x01, 0x00]) // Height = 1
        data.append(0x00) // No global color table
        data.append(0x00) // Background color
        data.append(0x00) // Pixel aspect ratio

        // Image descriptor
        data.append(0x2C) // Image separator
        data.append(contentsOf: [0x00, 0x00]) // Left
        data.append(contentsOf: [0x00, 0x00]) // Top
        data.append(contentsOf: [0x01, 0x00]) // Width = 1
        data.append(contentsOf: [0x01, 0x00]) // Height = 1
        data.append(0x00) // No local color table

        // Image data
        data.append(0x02) // LZW minimum code size
        data.append(0x01) // Block size
        data.append(0x00) // Data
        data.append(0x00) // Block terminator

        // Trailer
        data.append(0x3B)

        return data
    }

    /// GIF with multiple frames (animated)
    static func animatedGIF(frameCount: Int, width: Int, height: Int) -> [UInt8] {
        var data: [UInt8] = []

        // GIF89a header
        data.append(contentsOf: Array("GIF89a".utf8))

        // Logical screen descriptor
        data.append(UInt8(width & 0xFF))
        data.append(UInt8((width >> 8) & 0xFF))
        data.append(UInt8(height & 0xFF))
        data.append(UInt8((height >> 8) & 0xFF))
        data.append(0x00) // No global color table
        data.append(0x00) // Background color
        data.append(0x00) // Pixel aspect ratio

        // Add frames
        for _ in 0..<frameCount {
            // Image descriptor
            data.append(0x2C) // Image separator
            data.append(contentsOf: [0x00, 0x00]) // Left
            data.append(contentsOf: [0x00, 0x00]) // Top
            data.append(UInt8(width & 0xFF))
            data.append(UInt8((width >> 8) & 0xFF))
            data.append(UInt8(height & 0xFF))
            data.append(UInt8((height >> 8) & 0xFF))
            data.append(0x00) // No local color table

            // Image data
            data.append(0x02) // LZW minimum code size
            data.append(0x01) // Block size
            data.append(0x00) // Data
            data.append(0x00) // Block terminator
        }

        // Trailer
        data.append(0x3B)

        return data
    }

    // MARK: - BMP Test Data

    /// Minimal valid BMP
    static var minimalBMP: [UInt8] {
        var data: [UInt8] = []

        // BMP header
        data.append(contentsOf: Array("BM".utf8))

        // File size (placeholder)
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

        return data
    }

    // MARK: - TIFF Test Data

    /// Minimal valid TIFF (little-endian)
    static var minimalTIFF: [UInt8] {
        var data: [UInt8] = []

        // TIFF header (little-endian)
        data.append(contentsOf: [0x49, 0x49]) // "II" (little-endian)
        data.append(contentsOf: [0x2A, 0x00]) // Magic number
        data.append(contentsOf: [0x08, 0x00, 0x00, 0x00]) // IFD offset = 8

        // IFD
        data.append(contentsOf: [0x02, 0x00]) // Number of entries = 2

        // Entry 1: ImageWidth (tag 256)
        data.append(contentsOf: [0x00, 0x01]) // Tag
        data.append(contentsOf: [0x03, 0x00]) // Type (SHORT)
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count
        data.append(contentsOf: [0x10, 0x00, 0x00, 0x00]) // Value = 16

        // Entry 2: ImageLength (tag 257)
        data.append(contentsOf: [0x01, 0x01]) // Tag
        data.append(contentsOf: [0x03, 0x00]) // Type (SHORT)
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // Count
        data.append(contentsOf: [0x10, 0x00, 0x00, 0x00]) // Value = 16

        // Next IFD offset
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        return data
    }

    // MARK: - WebP Test Data

    /// Minimal valid WebP (lossy VP8)
    static var minimalWebP: [UInt8] {
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

        return data
    }

    // MARK: - Invalid Data

    /// Empty data
    static var emptyData: [UInt8] { [] }

    /// Random invalid data
    static var invalidData: [UInt8] {
        [0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE]
    }

    /// Truncated PNG (missing chunks)
    static var truncatedPNG: [UInt8] {
        // Only PNG signature, no chunks
        return [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    }

    // MARK: - XMP Test Data

    /// Sample XMP data
    static var sampleXMP: [UInt8] {
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
        return Array(xmpString.utf8)
    }
}

/// Helper to create test CGImage instances
func createTestImage(width: Int, height: Int, fill: UInt8 = 255) -> CGImage {
    let bytesPerRow = width * 4
    let data = [UInt8](repeating: fill, count: bytesPerRow * height)
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        data: data
    )
}
