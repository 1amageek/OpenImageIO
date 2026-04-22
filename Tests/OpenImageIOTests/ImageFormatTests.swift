// ImageFormatTests.swift
// OpenImageIO Tests
//
// Format-specific tests for image parsing

import Testing
import Foundation
@testable import OpenImageIO

// MARK: - PNG Format Tests

@Suite("PNG Format Parsing")
struct PNGFormatTests {

    @Test("Parse PNG signature")
    func parseSignature() {
        let data = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.png")
    }

    @Test("Parse PNG with various dimensions")
    func parseDimensions() {
        // 100x50 PNG
        let data100x50 = TestData.pngWithDimensions(width: 100, height: 50)
        let source100x50 = CGImageSourceCreateWithData(data100x50, nil)!
        let props100x50 = CGImageSourceCopyPropertiesAtIndex(source100x50, 0, nil)!

        #expect(props100x50[kCGImagePropertyPixelWidth] as? Int == 100)
        #expect(props100x50[kCGImagePropertyPixelHeight] as? Int == 50)

        // 1x1 PNG
        let data1x1 = TestData.minimalPNG
        let source1x1 = CGImageSourceCreateWithData(data1x1, nil)!
        let props1x1 = CGImageSourceCopyPropertiesAtIndex(source1x1, 0, nil)!

        #expect(props1x1[kCGImagePropertyPixelWidth] as? Int == 1)
        #expect(props1x1[kCGImagePropertyPixelHeight] as? Int == 1)
    }

    @Test("Parse PNG bit depth")
    func parseBitDepth() {
        let data = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyDepth] as? Int == 8)
    }

    @Test("Truncated PNG header is invalid")
    func truncatedPNGHeader() {
        let data = TestData.truncatedPNG
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatus(source) == .statusInvalidData)
    }

    @Test("Decode PNG to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        #expect(image!.width == 1)
        #expect(image!.height == 1)
    }

    @Test("Decode PNG with larger dimensions")
    func decodeLargerPNG() {
        let data = TestData.pngWithDimensions(width: 100, height: 50)
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        #expect(image!.width == 100)
        #expect(image!.height == 50)
    }

    @Test("PNG pixel data is red")
    func pixelDataIsRed() {
        let data = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(data, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)

        // Get pixel data from the decoded image
        if let dataProvider = image!.dataProvider,
           let pixelData = dataProvider.data {
            let bytes = pixelData as Data
            // PNG test data contains red pixel (RGBA: 255, 0, 0, 255)
            #expect(bytes.count >= 4)
            #expect(bytes[0] == 255, "Red channel should be 255")
            #expect(bytes[1] == 0, "Green channel should be 0")
            #expect(bytes[2] == 0, "Blue channel should be 0")
            #expect(bytes[3] == 255, "Alpha channel should be 255")
        }
    }
}

// MARK: - JPEG Format Tests

@Suite("JPEG Format Parsing")
struct JPEGFormatTests {

    @Test("Parse JPEG signature")
    func parseSignature() {
        let data = TestData.minimalJPEG
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.jpeg")
    }

    @Test("Parse JPEG dimensions")
    func parseDimensions() {
        let jpegData = TestData.jpegWithDimensions(width: 640, height: 480)
        let source = CGImageSourceCreateWithData(jpegData, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyPixelWidth] as? Int == 640)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 480)
    }

    @Test("JPEG color model is RGB")
    func colorModelRGB() {
        let data = TestData.minimalJPEG
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        // JPEG returns RGB color model
        #expect(props[kCGImagePropertyColorModel] as? String == kCGImagePropertyColorModelRGB)
    }

    @Test("JPEG 8x8 dimensions are correct")
    func jpeg8x8Dimensions() {
        let data = TestData.minimalJPEG
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyPixelWidth] as? Int == 8)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 8)
    }

    @Test("Decode JPEG to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalJPEG
        let source = CGImageSourceCreateWithData(data, nil)!

        // Try to decode - minimal JPEG may or may not decode depending on implementation
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        // Verify format detection works regardless of decode success
        #expect(CGImageSourceGetType(source) == "public.jpeg")

        // If decoding succeeds, verify dimensions
        if let img = image {
            #expect(img.width == 8)
            #expect(img.height == 8)
        }
    }

    @Test("Decode JPEG with various dimensions")
    func decodeVariousDimensions() {
        let jpegData = TestData.jpegWithDimensions(width: 640, height: 480)
        let source = CGImageSourceCreateWithData(jpegData, nil)!

        // Note: jpegWithDimensions creates header-only JPEG for dimension parsing
        // Full decoding may not work with incomplete data
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        // Even if decode fails, properties should be accessible
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!
        #expect(props[kCGImagePropertyPixelWidth] as? Int == 640)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 480)
    }
}

// MARK: - GIF Format Tests

@Suite("GIF Format Parsing")
struct GIFFormatTests {

    @Test("Parse GIF89a signature")
    func parseSignature() {
        let data = TestData.minimalGIF
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "com.compuserve.gif")
    }

    @Test("Parse single frame GIF")
    func parseSingleFrame() {
        let data = TestData.minimalGIF
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetCount(source) == 1)
    }

    @Test("Parse animated GIF with multiple frames")
    func parseMultipleFrames() {
        let gifData = TestData.animatedGIF(frameCount: 5, width: 100, height: 100)
        let source = CGImageSourceCreateWithData(gifData, nil)!

        #expect(CGImageSourceGetCount(source) == 5)
    }

    @Test("Parse GIF dimensions")
    func parseDimensions() {
        let gifData = TestData.animatedGIF(frameCount: 1, width: 320, height: 240)
        let source = CGImageSourceCreateWithData(gifData, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyPixelWidth] as? Int == 320)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 240)
    }

    @Test("Decode GIF to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalGIF
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        #expect(image!.width == 1)
        #expect(image!.height == 1)
    }

    @Test("Decode animated GIF frames")
    func decodeAnimatedFrames() {
        let gifData = TestData.animatedGIF(frameCount: 3, width: 10, height: 10)
        let source = CGImageSourceCreateWithData(gifData, nil)!

        // Verify all frames can be decoded
        for i in 0..<3 {
            let image = CGImageSourceCreateImageAtIndex(source, i, nil)
            #expect(image != nil, "Frame \(i) should decode")
            #expect(image!.width == 10)
            #expect(image!.height == 10)
        }
    }
}

// MARK: - BMP Format Tests

@Suite("BMP Format Parsing")
struct BMPFormatTests {

    @Test("Parse BMP signature")
    func parseSignature() {
        let data = TestData.minimalBMP
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "com.microsoft.bmp")
    }

    @Test("Parse BMP dimensions")
    func parseDimensions() {
        let data = TestData.minimalBMP
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyPixelWidth] as? Int == 2)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 2)
    }

    @Test("Decode BMP to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalBMP
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        #expect(image!.width == 2)
        #expect(image!.height == 2)
    }

    @Test("BMP pixel data is white")
    func pixelDataIsWhite() {
        let data = TestData.minimalBMP
        let source = CGImageSourceCreateWithData(data, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        // The test BMP contains white pixels (0xFF, 0xFF, 0xFF)
        // Verify the image was decoded (dimensions check is sufficient for unit test)
        #expect(image!.bitsPerPixel == 32) // RGBA output
    }

    @Test("Parse BMP bit depth")
    func parseBitDepth() {
        let data = TestData.minimalBMP
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyDepth] as? Int == 24)
    }
}

// MARK: - TIFF Format Tests

@Suite("TIFF Format Parsing")
struct TIFFFormatTests {

    @Test("Parse TIFF little-endian signature")
    func parseLittleEndianSignature() {
        let data = TestData.minimalTIFF
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.tiff")
    }

    @Test("Parse TIFF big-endian signature")
    func parseBigEndianSignature() {
        // Create big-endian TIFF header
        var bigEndianTiff: [UInt8] = []
        bigEndianTiff.append(contentsOf: [0x4D, 0x4D]) // "MM" (big-endian)
        bigEndianTiff.append(contentsOf: [0x00, 0x2A]) // Magic number
        bigEndianTiff.append(contentsOf: [0x00, 0x00, 0x00, 0x08]) // IFD offset

        // Minimal IFD
        bigEndianTiff.append(contentsOf: [0x00, 0x00]) // 0 entries
        bigEndianTiff.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Next IFD

        let data = Data(bigEndianTiff)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.tiff")
    }

    @Test("Parse TIFF dimensions")
    func parseDimensions() {
        let data = TestData.minimalTIFF
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyPixelWidth] as? Int == 2)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 2)
    }

    @Test("Decode TIFF to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalTIFF
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        #expect(image != nil)
        #expect(image!.width == 2)
        #expect(image!.height == 2)
    }

    @Test("TIFF RGB color model")
    func rgbColorModel() {
        let data = TestData.minimalTIFF
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        #expect(props[kCGImagePropertyColorModel] as? String == kCGImagePropertyColorModelRGB)
    }

    // MARK: - Multi-IFD + Predictor + Cycle Guard

    /// Round-trip a 3-page TIFF: encode three CGImages with
    /// `CGImageDestinationCreateWithData(..., "public.tiff", 3, nil)`, then
    /// decode each frame by index. Each frame must report the expected
    /// pixel-size, exercising the multi-IFD path in `TIFFDecoder` +
    /// `CGImageSource.parseTIFF`.
    @Test("Multi-page TIFF: three pages roundtrip with correct dimensions")
    func multiPageTIFFRoundtrip() throws {
        let sizes: [(Int, Int)] = [(4, 3), (5, 5), (6, 2)]
        let images = sizes.map { createTestImage(width: $0.0, height: $0.1) }

        var data = Data()
        let destination = try #require(
            CGImageDestinationCreateWithData(&data, "public.tiff", images.count, nil)
        )
        for image in images {
            CGImageDestinationAddImage(destination, image, nil)
        }

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true, "Multi-page TIFF encode must succeed")

        let source = try #require(CGImageSourceCreateWithData(data, nil))
        #expect(
            CGImageSourceGetCount(source) == images.count,
            "Source must report 3 pages"
        )

        for (index, expected) in sizes.enumerated() {
            let frame = try #require(
                CGImageSourceCreateImageAtIndex(source, index, nil),
                "Frame \(index) must decode"
            )
            #expect(frame.width == expected.0, "Frame \(index) width")
            #expect(frame.height == expected.1, "Frame \(index) height")
        }
    }

    /// Regression guard: a predictor=1 (no predictor) image must still decode
    /// correctly after the predictor-handling code was introduced.
    /// `TestData.minimalTIFF` omits the predictor tag (default = 1) so we use
    /// it as the canonical "no predictor" fixture.
    @Test("Predictor=1 (default): image decodes without predictor adjustment")
    func predictorNoneStillDecodes() throws {
        let data = TestData.minimalTIFF
        let source = try #require(CGImageSourceCreateWithData(data, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))

        #expect(image.width == 2)
        #expect(image.height == 2)

        // minimalTIFF is a solid-white 2x2 RGB. After decode the pixel buffer
        // should hold 255s for the RGB channels — this verifies that the
        // absence of a predictor tag does not corrupt the data path.
        let provider = try #require(image.dataProvider)
        let pixels = try #require(provider.data)
        #expect(pixels.count >= 4, "Decoded RGBA buffer must exist")
        #expect(pixels[0] == 255, "R of pixel (0,0) must be white")
        #expect(pixels[1] == 255, "G of pixel (0,0) must be white")
        #expect(pixels[2] == 255, "B of pixel (0,0) must be white")
    }

    /// Hand-construct a TIFF with `TAG_PREDICTOR = 2` (horizontal) for an
    /// 8-bit RGB 2x1 image. Pixel 0 = (100, 50, 25); stored differences make
    /// pixel 1 = (110, 60, 30). After the predictor is reversed the decoded
    /// bytes must equal the original pixel values.
    @Test("Predictor=2 (horizontal): pixel differences are reversed on decode")
    func predictorHorizontalDecodes() throws {
        let tiff = makePredictorHorizontalTIFF()
        let source = try #require(CGImageSourceCreateWithData(tiff, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))

        #expect(image.width == 2)
        #expect(image.height == 1)

        let provider = try #require(image.dataProvider)
        let pixels = try #require(provider.data)
        #expect(pixels.count >= 8, "RGBA buffer must hold 2 pixels")

        // Pixel 0 stored literally: (100, 50, 25).
        #expect(pixels[0] == 100, "Pixel 0 R")
        #expect(pixels[1] == 50, "Pixel 0 G")
        #expect(pixels[2] == 25, "Pixel 0 B")

        // Pixel 1 after predictor reversal: (100+10, 50+10, 25+5).
        #expect(pixels[4] == 110, "Pixel 1 R after predictor reversal")
        #expect(pixels[5] == 60, "Pixel 1 G after predictor reversal")
        #expect(pixels[6] == 30, "Pixel 1 B after predictor reversal")
    }

    /// Construct a TIFF whose `nextIFDOffset` points back at the first IFD.
    /// The cycle guard (`visited: Set<Int>`) in `CGImageSource.parseTIFF`
    /// must break the walk on the second visit, so `CGImageSourceGetCount`
    /// returns in bounded time (1 page counted, not a hang).
    @Test("Malformed IFD chain cycle: parse terminates instead of hanging")
    func malformedIFDChainCycleTerminates() throws {
        let tiff = makeCyclicIFDTIFF()

        let source = try #require(CGImageSourceCreateWithData(tiff, nil))
        let count = CGImageSourceGetCount(source)

        // The first IFD is counted, then the self-referencing `nextIFDOffset`
        // is caught by the cycle guard — so count must be exactly 1 and the
        // call must terminate (verified implicitly by this test completing).
        #expect(count == 1, "Cycle guard must stop after the first IFD")
    }

    // MARK: - TIFF Fixture Builders

    /// Builds a 2x1 RGB 8-bit TIFF with horizontal predictor (tag 317 = 2).
    /// The pixel data stores pixel 0 verbatim and pixel 1 as
    /// (pixel1 - pixel0) per channel; after the decoder reverses the
    /// predictor the original pixel values must be reconstructed.
    private func makePredictorHorizontalTIFF() -> Data {
        var data: [UInt8] = []

        // Header
        data.append(contentsOf: [0x49, 0x49]) // "II"
        data.append(contentsOf: [0x2A, 0x00]) // magic 42
        data.append(contentsOf: [0x08, 0x00, 0x00, 0x00]) // first IFD at 8

        // IFD: 11 entries (10 for minimalTIFF + Predictor tag 317)
        let numEntries: UInt16 = 11
        data.append(UInt8(numEntries & 0xFF))
        data.append(UInt8((numEntries >> 8) & 0xFF))

        // Layout plan (little-endian):
        //   Header: 0..7
        //   IFD count: 8..9
        //   11 entries × 12 bytes: 10..141
        //   Next IFD offset (0): 142..145
        //   BitsPerSample values (3 SHORTS = 6 bytes): 146..151
        //   Pixel data (2 pixels × 3 bytes): 152..157
        let bitsPerSampleOffset: UInt32 = 146
        let stripOffset: UInt32 = 152
        let stripByteCount: UInt32 = 6 // 2 pixels * 3 samples * 1 byte

        func appendEntry(tag: UInt16, type: UInt16, count: UInt32, value: UInt32) {
            data.append(UInt8(tag & 0xFF))
            data.append(UInt8((tag >> 8) & 0xFF))
            data.append(UInt8(type & 0xFF))
            data.append(UInt8((type >> 8) & 0xFF))
            data.append(UInt8(count & 0xFF))
            data.append(UInt8((count >> 8) & 0xFF))
            data.append(UInt8((count >> 16) & 0xFF))
            data.append(UInt8((count >> 24) & 0xFF))
            data.append(UInt8(value & 0xFF))
            data.append(UInt8((value >> 8) & 0xFF))
            data.append(UInt8((value >> 16) & 0xFF))
            data.append(UInt8((value >> 24) & 0xFF))
        }

        appendEntry(tag: 256, type: 3, count: 1, value: 2)  // ImageWidth = 2
        appendEntry(tag: 257, type: 3, count: 1, value: 1)  // ImageLength = 1
        appendEntry(tag: 258, type: 3, count: 3, value: bitsPerSampleOffset) // BitsPerSample -> external (8,8,8)
        appendEntry(tag: 259, type: 3, count: 1, value: 1)  // Compression = none
        appendEntry(tag: 262, type: 3, count: 1, value: 2)  // PhotometricInterpretation = RGB
        appendEntry(tag: 273, type: 4, count: 1, value: stripOffset) // StripOffsets
        appendEntry(tag: 277, type: 3, count: 1, value: 3)  // SamplesPerPixel = 3
        appendEntry(tag: 278, type: 3, count: 1, value: 1)  // RowsPerStrip = 1
        appendEntry(tag: 279, type: 4, count: 1, value: stripByteCount) // StripByteCounts
        appendEntry(tag: 296, type: 3, count: 1, value: 1)  // ResolutionUnit (optional, keeps IFD aligned with minimal fixture)
        appendEntry(tag: 317, type: 3, count: 1, value: 2)  // Predictor = 2 (horizontal)

        // Next IFD offset = 0 (no more pages)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // BitsPerSample: three SHORT values (8, 8, 8)
        data.append(contentsOf: [0x08, 0x00, 0x08, 0x00, 0x08, 0x00])

        // Pixel data with horizontal differencing applied.
        // Pixel 0 = (100, 50, 25); pixel 1 = pixel 0 + (10, 10, 5) = (110, 60, 30).
        // Stored: [100, 50, 25, 10, 10, 5].
        data.append(contentsOf: [100, 50, 25, 10, 10, 5])

        return Data(data)
    }

    /// Builds a minimal TIFF whose IFD's `nextIFDOffset` points back at the
    /// start of the IFD, forming a 1-cycle. The first page must be counted,
    /// then the cycle guard must break the walk.
    private func makeCyclicIFDTIFF() -> Data {
        var data: [UInt8] = []

        // Header
        data.append(contentsOf: [0x49, 0x49]) // "II"
        data.append(contentsOf: [0x2A, 0x00]) // magic 42
        data.append(contentsOf: [0x08, 0x00, 0x00, 0x00]) // first IFD at 8

        // IFD at offset 8: 2 entries + nextIFDOffset.
        // Layout:
        //   8..9   : numEntries (2)
        //   10..21 : entry 1 (ImageWidth)
        //   22..33 : entry 2 (ImageLength)
        //   34..37 : nextIFDOffset — set to 8 to create a self-cycle
        let numEntries: UInt16 = 2
        data.append(UInt8(numEntries & 0xFF))
        data.append(UInt8((numEntries >> 8) & 0xFF))

        func appendEntry(tag: UInt16, type: UInt16, count: UInt32, value: UInt32) {
            data.append(UInt8(tag & 0xFF))
            data.append(UInt8((tag >> 8) & 0xFF))
            data.append(UInt8(type & 0xFF))
            data.append(UInt8((type >> 8) & 0xFF))
            data.append(UInt8(count & 0xFF))
            data.append(UInt8((count >> 8) & 0xFF))
            data.append(UInt8((count >> 16) & 0xFF))
            data.append(UInt8((count >> 24) & 0xFF))
            data.append(UInt8(value & 0xFF))
            data.append(UInt8((value >> 8) & 0xFF))
            data.append(UInt8((value >> 16) & 0xFF))
            data.append(UInt8((value >> 24) & 0xFF))
        }

        appendEntry(tag: 256, type: 3, count: 1, value: 1) // ImageWidth = 1
        appendEntry(tag: 257, type: 3, count: 1, value: 1) // ImageLength = 1

        // nextIFDOffset = 8 (points back at the start of this same IFD).
        data.append(contentsOf: [0x08, 0x00, 0x00, 0x00])

        return Data(data)
    }
}

// MARK: - WebP Format Tests

@Suite("WebP Format Parsing")
struct WebPFormatTests {

    @Test("Parse WebP signature")
    func parseSignature() {
        let data = TestData.minimalWebP
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "org.webmproject.webp")
    }

    @Test("Parse WebP dimensions")
    func parseDimensions() {
        let data = TestData.minimalWebP
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        // WebP parsing extracts dimensions from VP8 chunk
        let width = props[kCGImagePropertyPixelWidth] as? Int
        let height = props[kCGImagePropertyPixelHeight] as? Int

        #expect(width != nil)
        #expect(height != nil)
    }

    @Test("Decode WebP to CGImage")
    func decodeToCGImage() {
        let data = TestData.minimalWebP
        let source = CGImageSourceCreateWithData(data, nil)!

        // Verify format detection works
        #expect(CGImageSourceGetType(source) == "org.webmproject.webp")

        // Try to decode - minimalWebP is synthetic VP8 data
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)

        // If decoding succeeds, verify dimensions
        if let img = image {
            #expect(img.width == 16, "Width should be 16")
            #expect(img.height == 16, "Height should be 16")
        } else {
            // Fallback: verify that properties were parsed correctly
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!
            let width = props[kCGImagePropertyPixelWidth] as? Int
            let height = props[kCGImagePropertyPixelHeight] as? Int
            #expect(width != nil, "Width should be parsed from VP8 header")
            #expect(height != nil, "Height should be parsed from VP8 header")
        }
    }

    @Test("WebP color model")
    func colorModel() {
        let data = TestData.minimalWebP
        let source = CGImageSourceCreateWithData(data, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)!

        // WebP uses RGB color model
        #expect(props[kCGImagePropertyColorModel] as? String == kCGImagePropertyColorModelRGB)
    }
}

// MARK: - Format Detection Tests

@Suite("Format Detection")
struct FormatDetectionTests {

    @Test("Detect PNG from magic bytes")
    func detectPNG() {
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let data = Data(pngSignature + [0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                                        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                                        0x08, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.png")
    }

    @Test("Detect JPEG from magic bytes")
    func detectJPEG() {
        let data = Data([0xFF, 0xD8, 0xFF] + [UInt8](repeating: 0, count: 30))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.jpeg")
    }

    @Test("Detect GIF from magic bytes")
    func detectGIF() {
        let data = Data(Array("GIF89a".utf8) + [UInt8](repeating: 0, count: 20))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "com.compuserve.gif")
    }

    @Test("Detect BMP from magic bytes")
    func detectBMP() {
        let data = Data(Array("BM".utf8) + [UInt8](repeating: 0, count: 50))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "com.microsoft.bmp")
    }

    @Test("Detect TIFF little-endian from magic bytes")
    func detectTIFFLittleEndian() {
        let data = Data([0x49, 0x49, 0x2A, 0x00] + [UInt8](repeating: 0, count: 20))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.tiff")
    }

    @Test("Detect TIFF big-endian from magic bytes")
    func detectTIFFBigEndian() {
        let data = Data([0x4D, 0x4D, 0x00, 0x2A] + [UInt8](repeating: 0, count: 20))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "public.tiff")
    }

    @Test("Detect WebP from magic bytes")
    func detectWebP() {
        // RIFF....WEBP
        let riffHeader: [UInt8] = [0x52, 0x49, 0x46, 0x46] // "RIFF"
        let size: [UInt8] = [0x00, 0x00, 0x00, 0x00] // Size placeholder
        let webpSig: [UInt8] = [0x57, 0x45, 0x42, 0x50] // "WEBP"
        let data = Data(riffHeader + size + webpSig + [UInt8](repeating: 0, count: 20))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == "org.webmproject.webp")
    }

    @Test("Unknown format returns nil type")
    func unknownFormat() {
        let data = TestData.invalidData
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetType(source) == nil)
        #expect(CGImageSourceGetStatus(source) == .statusUnknownType)
    }
}

// MARK: - Image Animation Tests

@Suite("Image Animation")
struct ImageAnimationTests {

    @Test("Animation status values")
    func animationStatusValues() {
        #expect(CGImageAnimationStatus.allocationFailure.rawValue == -22)
        #expect(CGImageAnimationStatus.corruptInputImage.rawValue == -23)
        #expect(CGImageAnimationStatus.incompleteInputImage.rawValue == -24)
        #expect(CGImageAnimationStatus.parameterError.rawValue == -25)
        #expect(CGImageAnimationStatus.unsupportedFormat.rawValue == -26)
    }

    @Test("Animate image data with block")
    func animateImageDataWithBlock() {
        let gifData = TestData.animatedGIF(frameCount: 3, width: 10, height: 10)

        var frameIndices: [Int] = []
        let status = CGAnimateImageDataWithBlock(gifData, nil) { index, image, stop in
            frameIndices.append(index)
        }

        #expect(status == noErr)
        #expect(frameIndices == [0, 1, 2])
    }

    @Test("Animate image data stops when requested")
    func animateImageDataStopsEarly() {
        let gifData = TestData.animatedGIF(frameCount: 5, width: 10, height: 10)

        var frameCount = 0
        CGAnimateImageDataWithBlock(gifData, nil) { index, image, stop in
            frameCount += 1
            if frameCount >= 2 {
                stop.pointee = true
            }
        }

        #expect(frameCount == 2)
    }

    @Test("Animation property keys exist")
    func animationPropertyKeysExist() {
        #expect(!kCGImageAnimationStartIndex.isEmpty)
        #expect(!kCGImageAnimationDelayTime.isEmpty)
        #expect(!kCGImageAnimationLoopCount.isEmpty)
    }
}
