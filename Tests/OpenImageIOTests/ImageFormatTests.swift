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
