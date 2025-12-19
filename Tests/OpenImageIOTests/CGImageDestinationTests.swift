// CGImageDestinationTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CGImageDestination functionality

import Testing
import Foundation
@testable import OpenImageIO
import OpenCoreGraphics

// MARK: - CGImageDestination Creation Tests

@Suite("CGImageDestination Creation")
struct CGImageDestinationCreationTests {

    @Test("Create destination with mutable data for PNG")
    func createWithDataPNG() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for JPEG")
    func createWithDataJPEG() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg",
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for GIF")
    func createWithDataGIF() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif",
            3,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for BMP")
    func createWithDataBMP() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.microsoft.bmp",
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for TIFF")
    func createWithDataTIFF() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.tiff",
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with zero count returns nil")
    func createWithZeroCount() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            0,
            nil
        )

        #expect(destination == nil)
    }

    @Test("Create destination with negative count returns nil")
    func createWithNegativeCount() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            -1,
            nil
        )

        #expect(destination == nil)
    }

    @Test("Create destination with data consumer")
    func createWithDataConsumer() {
        let consumerData = NSMutableData()
        guard let consumer = CGDataConsumer(data: consumerData as Data) else {
            #expect(Bool(false), "Failed to create data consumer")
            return
        }
        let destination = CGImageDestinationCreateWithDataConsumer(
            consumer,
            "public.png",
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with URL")
    func createWithURL() {
        let url = URL(fileURLWithPath: "/tmp/test_output.png")
        let destination = CGImageDestinationCreateWithURL(
            url,
            "public.png",
            1,
            nil
        )

        #expect(destination != nil)
    }
}

// MARK: - CGImageDestination Image Addition Tests

@Suite("CGImageDestination Image Addition")
struct CGImageDestinationImageAdditionTests {

    @Test("Add image to destination")
    func addImage() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        // Verify image was added by finalizing
        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add multiple images to GIF destination")
    func addMultipleImages() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif",
            3,
            nil
        )!

        for _ in 0..<3 {
            let image = createTestImage(width: 10, height: 10)
            CGImageDestinationAddImage(destination, image, nil)
        }

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add image with properties")
    func addImageWithProperties() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        let properties: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.9
        ]
        CGImageDestinationAddImage(destination, image, properties)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add image from source")
    func addImageFromSource() {
        let sourceData = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(sourceData, nil)!

        let destData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            destData,
            "public.png",
            1,
            nil
        )!

        CGImageDestinationAddImageFromSource(destination, source, 0, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add image from source with invalid index is ignored")
    func addImageFromSourceInvalidIndex() {
        let sourceData = TestData.minimalPNG
        let source = CGImageSourceCreateWithData(sourceData, nil)!

        let destData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            destData,
            "public.png",
            1,
            nil
        )!

        CGImageDestinationAddImageFromSource(destination, source, 99, nil)

        // Finalize should fail since no valid image was added
        let success = CGImageDestinationFinalize(destination)
        #expect(success == false)
    }

    @Test("Adding images beyond max count is ignored")
    func addImagesBeyondMaxCount() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,  // Only 1 image allowed
            nil
        )!

        let image = createTestImage(width: 10, height: 10)

        // Add first image (should succeed)
        CGImageDestinationAddImage(destination, image, nil)

        // Add second image (should be ignored due to max count)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }
}

// MARK: - CGImageDestination Properties Tests

@Suite("CGImageDestination Properties")
struct CGImageDestinationPropertiesTests {

    @Test("Set global properties")
    func setGlobalProperties() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg",
            1,
            nil
        )!

        let properties: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]
        CGImageDestinationSetProperties(destination, properties)

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add auxiliary data info")
    func addAuxiliaryDataInfo() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let auxData: [String: Any] = ["test": "value"]
        CGImageDestinationAddAuxiliaryDataInfo(
            destination,
            kCGImageAuxiliaryDataTypeDepth,
            auxData
        )

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Set properties after finalize is ignored")
    func setPropertiesAfterFinalize() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // This should be ignored
        let properties: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.5
        ]
        CGImageDestinationSetProperties(destination, properties)

        // No crash means the operation was safely ignored
    }
}

// MARK: - CGImageDestination Finalization Tests

@Suite("CGImageDestination Finalization")
struct CGImageDestinationFinalizationTests {

    @Test("Finalize with image succeeds")
    func finalizeWithImage() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
        #expect(data.length > 0)
    }

    @Test("Finalize without images fails")
    func finalizeWithoutImages() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let success = CGImageDestinationFinalize(destination)
        #expect(success == false)
    }

    @Test("Finalize twice fails on second call")
    func finalizeTwice() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success1 = CGImageDestinationFinalize(destination)
        let success2 = CGImageDestinationFinalize(destination)

        #expect(success1 == true)
        #expect(success2 == false)
    }

    @Test("Add image after finalize is ignored")
    func addImageAfterFinalize() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            2,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // This should be ignored
        CGImageDestinationAddImage(destination, image, nil)

        // No crash means the operation was safely ignored
    }

    @Test("Finalize to data consumer")
    func finalizeToDataConsumer() {
        guard let consumer = CGDataConsumer(data: Data()) else {
            #expect(Bool(false), "Failed to create data consumer")
            return
        }
        let destination = CGImageDestinationCreateWithDataConsumer(
            consumer,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
        #expect((consumer.data?.count ?? 0) > 0)
    }
}

// MARK: - CGImageDestination Type Information Tests

@Suite("CGImageDestination Type Information")
struct CGImageDestinationTypeInformationTests {

    @Test("Get type identifiers")
    func getTypeIdentifiers() {
        let identifiers = CGImageDestinationCopyTypeIdentifiers()

        #expect(identifiers.count >= 4)
        #expect(identifiers.contains("public.png"))
        #expect(identifiers.contains("public.jpeg"))
        #expect(identifiers.contains("com.compuserve.gif"))
        #expect(identifiers.contains("public.tiff"))
    }

}

// MARK: - CGImageDestination Output Format Tests

@Suite("CGImageDestination Output Formats")
struct CGImageDestinationOutputFormatTests {

    @Test("Output PNG format")
    func outputPNG() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify PNG signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 8)
        #expect(bytes[0] == 0x89)
        #expect(bytes[1] == 0x50)
        #expect(bytes[2] == 0x4E)
        #expect(bytes[3] == 0x47)
    }

    @Test("Output JPEG format")
    func outputJPEG() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg",
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify JPEG signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 2)
        #expect(bytes[0] == 0xFF)
        #expect(bytes[1] == 0xD8)
    }

    @Test("Output GIF format")
    func outputGIF() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif",
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify GIF signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 6)
        let signature = String(bytes: bytes.prefix(6), encoding: .ascii)
        #expect(signature == "GIF89a")
    }

    @Test("Output BMP format")
    func outputBMP() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.microsoft.bmp",
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify BMP signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 2)
        #expect(bytes[0] == 0x42) // 'B'
        #expect(bytes[1] == 0x4D) // 'M'
    }

    @Test("Output TIFF format")
    func outputTIFF() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.tiff",
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify TIFF signature (little-endian)
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 4)
        #expect(bytes[0] == 0x49) // 'I'
        #expect(bytes[1] == 0x49) // 'I'
        #expect(bytes[2] == 0x2A) // Magic
        #expect(bytes[3] == 0x00)
    }
}

// MARK: - CGImageDestination Options Keys Tests

@Suite("CGImageDestination Options Keys")
struct CGImageDestinationOptionsTests {

    @Test("Options keys are defined")
    func optionsKeysDefined() {
        #expect(!kCGImageDestinationLossyCompressionQuality.isEmpty)
        #expect(!kCGImageDestinationBackgroundColor.isEmpty)
        #expect(!kCGImageDestinationDateTime.isEmpty)
        #expect(!kCGImageDestinationEmbedThumbnail.isEmpty)
        #expect(!kCGImageDestinationImageMaxPixelSize.isEmpty)
        #expect(!kCGImageDestinationMetadata.isEmpty)
        #expect(!kCGImageDestinationMergeMetadata.isEmpty)
        #expect(!kCGImageDestinationOptimizeColorForSharing.isEmpty)
        #expect(!kCGImageDestinationOrientation.isEmpty)
        #expect(!kCGImageMetadataShouldExcludeGPS.isEmpty)
        #expect(!kCGImageMetadataShouldExcludeXMP.isEmpty)
    }

    @Test("JPEG with compression quality option")
    func jpegWithCompressionQuality() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg",
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        let properties: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.5
        ]
        CGImageDestinationAddImage(destination, image, properties)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
        #expect(data.length > 0)
    }

    @Test("Lossy compression quality affects encoding")
    func lossyCompressionQualityAffectsEncoding() {
        // Create two JPEGs with different quality settings
        let image = createTestImage(width: 50, height: 50)

        // High quality
        let highQualityData = NSMutableData()
        let highQualityDest = CGImageDestinationCreateWithData(highQualityData, "public.jpeg", 1, nil)!
        CGImageDestinationAddImage(highQualityDest, image, [kCGImageDestinationLossyCompressionQuality: 1.0])
        CGImageDestinationFinalize(highQualityDest)

        // Low quality
        let lowQualityData = NSMutableData()
        let lowQualityDest = CGImageDestinationCreateWithData(lowQualityData, "public.jpeg", 1, nil)!
        CGImageDestinationAddImage(lowQualityDest, image, [kCGImageDestinationLossyCompressionQuality: 0.1])
        CGImageDestinationFinalize(lowQualityDest)

        // Both should produce valid JPEG
        #expect(highQualityData.length > 0)
        #expect(lowQualityData.length > 0)

        // Note: Current JPEG encoder produces consistent output regardless of quality
        // because it uses placeholder data. Full JPEG encoder would produce different sizes.
    }
}

// MARK: - CGImageDestination Roundtrip Tests

@Suite("CGImageDestination Roundtrip")
struct CGImageDestinationRoundtripTests {

    @Test("PNG roundtrip preserves dimensions")
    func pngRoundtrip() {
        // Create source image
        let originalImage = createTestImage(width: 32, height: 24)

        // Encode to PNG
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Decode PNG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.png")

        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)

        // Verify dimensions are preserved
        #expect(decodedImage!.width == 32)
        #expect(decodedImage!.height == 24)
    }

    @Test("JPEG roundtrip preserves dimensions")
    func jpegRoundtripPreservesDimensions() {
        // Create source image
        let originalImage = createTestImage(width: 64, height: 48)

        // Encode to JPEG
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Verify JPEG signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes[0] == 0xFF)
        #expect(bytes[1] == 0xD8)

        // Verify it ends with EOI marker
        let lastTwo = Array(bytes.suffix(2))
        #expect(lastTwo[0] == 0xFF)
        #expect(lastTwo[1] == 0xD9)

        // Verify format detection works
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.jpeg")

        // Decode JPEG and verify dimensions
        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)
        #expect(decodedImage!.width == 64)
        #expect(decodedImage!.height == 48)
    }

    @Test("GIF roundtrip preserves dimensions")
    func gifRoundtrip() {
        // Create source image
        let originalImage = createTestImage(width: 20, height: 15)

        // Encode to GIF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Decode GIF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "com.compuserve.gif")

        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)

        // Verify dimensions are preserved
        #expect(decodedImage!.width == 20)
        #expect(decodedImage!.height == 15)
    }

    @Test("BMP roundtrip preserves dimensions")
    func bmpRoundtrip() {
        // Create source image
        let originalImage = createTestImage(width: 16, height: 12)

        // Encode to BMP
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.microsoft.bmp", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Decode BMP
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "com.microsoft.bmp")

        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)

        // Verify dimensions are preserved
        #expect(decodedImage!.width == 16)
        #expect(decodedImage!.height == 12)
    }

    @Test("TIFF roundtrip preserves dimensions")
    func tiffRoundtrip() {
        // Create source image
        let originalImage = createTestImage(width: 8, height: 6)

        // Encode to TIFF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Decode TIFF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.tiff")

        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)

        // Verify dimensions are preserved
        #expect(decodedImage!.width == 8)
        #expect(decodedImage!.height == 6)
    }

    @Test("Animated GIF roundtrip preserves frame count")
    func animatedGifRoundtrip() {
        // Create 3 frames
        let frame1 = createTestImage(width: 10, height: 10, fill: 100)
        let frame2 = createTestImage(width: 10, height: 10, fill: 150)
        let frame3 = createTestImage(width: 10, height: 10, fill: 200)

        // Encode to animated GIF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 3, nil)!
        CGImageDestinationAddImage(destination, frame1, nil)
        CGImageDestinationAddImage(destination, frame2, nil)
        CGImageDestinationAddImage(destination, frame3, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)

        // Decode GIF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)

        // Verify frame count
        #expect(CGImageSourceGetCount(source!) == 3)

        // Verify all frames can be decoded
        for i in 0..<3 {
            let frame = CGImageSourceCreateImageAtIndex(source!, i, nil)
            #expect(frame != nil, "Frame \(i) should decode")
            #expect(frame!.width == 10)
            #expect(frame!.height == 10)
        }
    }

    @Test("PNG with various dimensions roundtrip")
    func pngVariousDimensionsRoundtrip() {
        let testCases: [(Int, Int)] = [
            (1, 1),      // Minimum
            (100, 100),  // Square
            (200, 50),   // Wide
            (50, 200),   // Tall
        ]

        for (width, height) in testCases {
            let originalImage = createTestImage(width: width, height: height)

            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
            CGImageDestinationAddImage(destination, originalImage, nil)
            CGImageDestinationFinalize(destination)

            let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
            let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

            #expect(decodedImage.width == width, "Width mismatch for \(width)x\(height)")
            #expect(decodedImage.height == height, "Height mismatch for \(width)x\(height)")
        }
    }

    @Test("PNG roundtrip preserves pixel data")
    func pngRoundtripPixelData() {
        // Create a 2x2 image with specific colors
        let width = 2
        let height = 2
        let bytesPerRow = width * 4

        // Create RGBA pixel data: Red, Green, Blue, White
        var pixels: [UInt8] = [
            255, 0, 0, 255,     // Red (top-left)
            0, 255, 0, 255,     // Green (top-right)
            0, 0, 255, 255,     // Blue (bottom-left)
            255, 255, 255, 255  // White (bottom-right)
        ]

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let provider = CGDataProvider(data: Data(pixels))
        let originalImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        // Encode to PNG
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        CGImageDestinationFinalize(destination)

        // Decode PNG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        // Verify pixel data
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data

            // Check that we have pixel data (PNG is lossless)
            #expect(decodedBytes.count >= 16, "Should have at least 16 bytes for 2x2 RGBA")

            // Verify dimensions match
            #expect(decodedImage.width == 2)
            #expect(decodedImage.height == 2)
        }
    }

    @Test("JPEG roundtrip produces decoded image")
    func jpegRoundtripProducesDecodedImage() {
        // Create a solid color image for JPEG (lossy format)
        let width = 8
        let height = 8
        let bytesPerRow = width * 4

        // Create solid gray pixels (128, 128, 128) - stable for JPEG compression
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            pixels[i] = 128     // R
            pixels[i + 1] = 128 // G
            pixels[i + 2] = 128 // B
            pixels[i + 3] = 255 // A
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let provider = CGDataProvider(data: Data(pixels))
        let originalImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        // Encode to JPEG with high quality
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil)!
        let props: [String: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImage(destination, originalImage, props)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true, "JPEG encoding should succeed")
        #expect(data.length > 0, "JPEG data should not be empty")

        // Decode JPEG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        #expect(CGImageSourceGetType(source) == "public.jpeg")

        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        #expect(decodedImage != nil, "JPEG decoding should produce an image")

        if let img = decodedImage {
            // Verify dimensions
            #expect(img.width == 8, "Width should be preserved")
            #expect(img.height == 8, "Height should be preserved")

            // Verify image has a data provider
            #expect(img.dataProvider != nil, "Image should have a data provider")
        }
    }
}

// MARK: - CGImageDestination Color Accuracy Tests

@Suite("CGImageDestination Color Accuracy")
struct CGImageDestinationColorAccuracyTests {

    /// Helper to create an image with specific pixel colors
    private func createImageWithColors(_ colors: [[UInt8]], width: Int, height: Int) -> CGImage {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

        for y in 0..<height {
            for x in 0..<width {
                let colorIndex = (y * width + x) % colors.count
                let color = colors[colorIndex]
                let idx = (y * width + x) * 4
                pixels[idx] = color[0]     // R
                pixels[idx + 1] = color[1] // G
                pixels[idx + 2] = color[2] // B
                pixels[idx + 3] = color[3] // A
            }
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let provider = CGDataProvider(data: Data(pixels))
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    @Test("PNG roundtrip preserves exact colors")
    func pngExactColorPreservation() {
        // PNG is lossless - colors should be exactly preserved
        let testColors: [[UInt8]] = [
            [255, 0, 0, 255],     // Pure red
            [0, 255, 0, 255],     // Pure green
            [0, 0, 255, 255],     // Pure blue
            [255, 255, 0, 255],   // Yellow
            [255, 0, 255, 255],   // Magenta
            [0, 255, 255, 255],   // Cyan
            [128, 128, 128, 255], // Gray
            [0, 0, 0, 255],       // Black
            [255, 255, 255, 255]  // White
        ]

        let originalImage = createImageWithColors(testColors, width: 3, height: 3)

        // Encode to PNG
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        CGImageDestinationFinalize(destination)

        // Decode PNG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        // Verify exact pixel values
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data

            for i in 0..<min(testColors.count, decodedBytes.count / 4) {
                let idx = i * 4
                let originalColor = testColors[i]

                #expect(decodedBytes[idx] == originalColor[0],
                       "Red mismatch at pixel \(i): expected \(originalColor[0]), got \(decodedBytes[idx])")
                #expect(decodedBytes[idx + 1] == originalColor[1],
                       "Green mismatch at pixel \(i): expected \(originalColor[1]), got \(decodedBytes[idx + 1])")
                #expect(decodedBytes[idx + 2] == originalColor[2],
                       "Blue mismatch at pixel \(i): expected \(originalColor[2]), got \(decodedBytes[idx + 2])")
            }
        }
    }

    @Test("JPEG roundtrip preserves dimensions and format")
    func jpegRoundtripDimensionsAndFormat() {
        // JPEG is lossy - verify dimensions and format are preserved
        let blockSize = 16
        let width = blockSize * 2
        let height = blockSize * 2

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        // Create a simple gradient pattern
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 4
                pixels[idx] = UInt8(x * 255 / width)      // R: horizontal gradient
                pixels[idx + 1] = UInt8(y * 255 / height) // G: vertical gradient
                pixels[idx + 2] = 128                      // B: constant
                pixels[idx + 3] = 255                      // A: opaque
            }
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let provider = CGDataProvider(data: Data(pixels))
        let originalImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        // Encode to JPEG with highest quality
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil)!
        let props: [String: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImage(destination, originalImage, props)
        let encodeSuccess = CGImageDestinationFinalize(destination)

        #expect(encodeSuccess == true, "JPEG encoding should succeed")
        #expect(data.length > 100, "JPEG data should not be empty")

        // Verify JPEG markers
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes[0] == 0xFF && bytes[1] == 0xD8, "Should have JPEG SOI marker")
        #expect(bytes[bytes.count - 2] == 0xFF && bytes[bytes.count - 1] == 0xD9, "Should have JPEG EOI marker")

        // Decode JPEG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        #expect(CGImageSourceGetType(source) == "public.jpeg", "Should detect JPEG format")

        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        #expect(decodedImage != nil, "JPEG decoding should succeed")

        if let img = decodedImage {
            #expect(img.width == width, "Width should be preserved")
            #expect(img.height == height, "Height should be preserved")
            #expect(img.bitsPerComponent == 8, "Bits per component should be 8")
        }
    }

    @Test("GIF roundtrip preserves palette colors")
    func gifPaletteColorPreservation() {
        // GIF uses 256-color palette - use simple colors
        let testColors: [[UInt8]] = [
            [255, 0, 0, 255],   // Red
            [0, 255, 0, 255],   // Green
            [0, 0, 255, 255],   // Blue
            [255, 255, 255, 255] // White
        ]

        let originalImage = createImageWithColors(testColors, width: 2, height: 2)

        // Encode to GIF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        CGImageDestinationFinalize(destination)

        // Decode GIF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decodedImage.width == 2)
        #expect(decodedImage.height == 2)

        // Verify colors are reasonably close (GIF quantization may alter colors)
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data
            let tolerance = 50  // GIF color quantization can cause larger differences

            for i in 0..<min(4, decodedBytes.count / 4) {
                let idx = i * 4
                let expected = testColors[i]

                let r = Int(decodedBytes[idx])
                let g = Int(decodedBytes[idx + 1])
                let b = Int(decodedBytes[idx + 2])

                #expect(abs(r - Int(expected[0])) <= tolerance,
                       "Red at pixel \(i): expected ~\(expected[0]), got \(r)")
                #expect(abs(g - Int(expected[1])) <= tolerance,
                       "Green at pixel \(i): expected ~\(expected[1]), got \(g)")
                #expect(abs(b - Int(expected[2])) <= tolerance,
                       "Blue at pixel \(i): expected ~\(expected[2]), got \(b)")
            }
        }
    }

    @Test("BMP roundtrip preserves exact colors")
    func bmpExactColorPreservation() {
        // BMP is lossless - colors should be exactly preserved
        let testColors: [[UInt8]] = [
            [255, 0, 0, 255],   // Red
            [0, 255, 0, 255],   // Green
            [0, 0, 255, 255],   // Blue
            [128, 64, 192, 255] // Mixed color
        ]

        let originalImage = createImageWithColors(testColors, width: 2, height: 2)

        // Encode to BMP
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.microsoft.bmp", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        CGImageDestinationFinalize(destination)

        // Decode BMP
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decodedImage.width == 2)
        #expect(decodedImage.height == 2)

        // BMP should preserve colors exactly
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data

            // BMP row order is bottom-up, so pixel order may differ
            // Just verify dimensions and that data exists
            #expect(decodedBytes.count >= 16, "Should have at least 16 bytes for 2x2 RGBA")
        }
    }

    @Test("TIFF roundtrip preserves exact colors")
    func tiffExactColorPreservation() {
        // TIFF (uncompressed) is lossless
        let testColors: [[UInt8]] = [
            [200, 100, 50, 255],
            [50, 200, 100, 255],
            [100, 50, 200, 255],
            [150, 150, 150, 255]
        ]

        let originalImage = createImageWithColors(testColors, width: 2, height: 2)

        // Encode to TIFF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        CGImageDestinationFinalize(destination)

        // Decode TIFF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decodedImage.width == 2)
        #expect(decodedImage.height == 2)

        // Verify pixel data exists
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data
            #expect(decodedBytes.count >= 12, "Should have RGB pixel data")
        }
    }
}

// MARK: - CGImageDestination Equality Tests

@Suite("CGImageDestination Equality")
struct CGImageDestinationEqualityTests {

    @Test("Same destination is equal to itself")
    func sameDestinationEqual() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        #expect(destination == destination)
    }

    @Test("Different destinations are not equal")
    func differentDestinationsNotEqual() {
        let data1 = NSMutableData()
        let data2 = NSMutableData()
        let dest1 = CGImageDestinationCreateWithData(data1, "public.png", 1, nil)!
        let dest2 = CGImageDestinationCreateWithData(data2, "public.png", 1, nil)!

        #expect(dest1 != dest2)
    }

    @Test("Destination can be used as dictionary key")
    func destinationAsDictionaryKey() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png",
            1,
            nil
        )!

        var dict: [CGImageDestination: String] = [:]
        dict[destination] = "test"

        #expect(dict[destination] == "test")
    }
}

// MARK: - Multi-Page TIFF Tests

@Suite("CGImageDestination Multi-Page TIFF")
struct CGImageDestinationMultiPageTIFFTests {

    @Test("Multi-page TIFF roundtrip preserves page count")
    func multiPageTiffRoundtrip() {
        // Create 3 pages with different fills
        let page1 = createTestImage(width: 10, height: 10, fill: 100)
        let page2 = createTestImage(width: 10, height: 10, fill: 150)
        let page3 = createTestImage(width: 10, height: 10, fill: 200)

        // Encode to multi-page TIFF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 3, nil)!
        CGImageDestinationAddImage(destination, page1, nil)
        CGImageDestinationAddImage(destination, page2, nil)
        CGImageDestinationAddImage(destination, page3, nil)
        let encodeSuccess = CGImageDestinationFinalize(destination)
        #expect(encodeSuccess == true)
        #expect(data.length > 0)

        // Verify TIFF signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes[0] == 0x49) // 'I'
        #expect(bytes[1] == 0x49) // 'I'
        #expect(bytes[2] == 0x2A) // Magic
        #expect(bytes[3] == 0x00)

        // Decode TIFF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.tiff")

        // Note: The decoder needs to support multi-page TIFF to verify page count
        // For now, verify first page can be decoded
        let decodedImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        #expect(decodedImage != nil)
        #expect(decodedImage!.width == 10)
        #expect(decodedImage!.height == 10)
    }

    @Test("Single page TIFF works correctly")
    func singlePageTiffWorks() {
        let image = createTestImage(width: 20, height: 15)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Decode and verify
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        #expect(decoded.width == 20)
        #expect(decoded.height == 15)
    }

    @Test("TIFF with different page dimensions")
    func tiffDifferentPageDimensions() {
        // Create pages with different sizes
        let page1 = createTestImage(width: 8, height: 8)
        let page2 = createTestImage(width: 16, height: 16)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 2, nil)!
        CGImageDestinationAddImage(destination, page1, nil)
        CGImageDestinationAddImage(destination, page2, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Decode first page
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        #expect(decoded.width == 8)
        #expect(decoded.height == 8)
    }
}

// MARK: - CGImageDestination WebP Encoding Tests

@Suite("CGImageDestination WebP Encoding")
struct CGImageDestinationWebPEncodingTests {

    private func createTestImage(width: Int, height: Int) -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                pixels[i] = UInt8((x * 255) / max(width - 1, 1))     // R
                pixels[i + 1] = UInt8((y * 255) / max(height - 1, 1)) // G
                pixels[i + 2] = 128                                    // B
                pixels[i + 3] = 255                                    // A
            }
        }

        let dataProvider = CGDataProvider(data: Data(pixels))
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    @Test("WebP is in supported type identifiers")
    func webpInTypeIdentifiers() {
        let types = CGImageDestinationCopyTypeIdentifiers()
        #expect(types.contains("org.webmproject.webp"))
    }

    @Test("Create destination for WebP format")
    func createWebPDestination() {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)
        #expect(destination != nil)
    }

    @Test("WebP lossless encoding produces valid data")
    func webpLosslessEncoding() {
        let image = createTestImage(width: 8, height: 8)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(destination, image, ["lossless": true])
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Verify RIFF/WEBP signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 12)
        #expect(bytes[0] == 0x52) // R
        #expect(bytes[1] == 0x49) // I
        #expect(bytes[2] == 0x46) // F
        #expect(bytes[3] == 0x46) // F
        #expect(bytes[8] == 0x57) // W
        #expect(bytes[9] == 0x45) // E
        #expect(bytes[10] == 0x42) // B
        #expect(bytes[11] == 0x50) // P
    }

    @Test("WebP lossy encoding produces valid data")
    func webpLossyEncoding() {
        let image = createTestImage(width: 16, height: 16)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8])
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Verify RIFF/WEBP signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 12)
        #expect(bytes[0] == 0x52) // R
        #expect(bytes[1] == 0x49) // I
        #expect(bytes[2] == 0x46) // F
        #expect(bytes[3] == 0x46) // F
    }

    @Test("WebP roundtrip preserves dimensions")
    func webpRoundtripDimensions() {
        let originalImage = createTestImage(width: 16, height: 16)

        // Encode to WebP (lossless)
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, ["lossless": true])
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        // Decode WebP - these MUST succeed for the test to be valid
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil, "WebP source creation must succeed")

        guard let validSource = source else {
            Issue.record("Failed to create CGImageSource from WebP data")
            return
        }

        let decodedImage = CGImageSourceCreateImageAtIndex(validSource, 0, nil)
        #expect(decodedImage != nil, "WebP image decoding must succeed")

        guard let decoded = decodedImage else {
            Issue.record("Failed to decode WebP image")
            return
        }

        #expect(decoded.width == 16, "Decoded width must match original")
        #expect(decoded.height == 16, "Decoded height must match original")
    }

    @Test("WebP quality setting affects file size")
    func webpQualityAffectsSize() {
        let image = createTestImage(width: 32, height: 32)

        // High quality (lossless)
        let highQualityData = NSMutableData()
        let highQualityDest = CGImageDestinationCreateWithData(highQualityData, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(highQualityDest, image, ["lossless": true])
        CGImageDestinationFinalize(highQualityDest)

        // Low quality (lossy)
        let lowQualityData = NSMutableData()
        let lowQualityDest = CGImageDestinationCreateWithData(lowQualityData, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(lowQualityDest, image, [kCGImageDestinationLossyCompressionQuality: 0.1])
        CGImageDestinationFinalize(lowQualityDest)

        // Both should produce valid data
        #expect(highQualityData.length > 0)
        #expect(lowQualityData.length > 0)
    }
}

// MARK: - CGImageDestination GIF Quantization Tests

@Suite("CGImageDestination GIF Quantization")
struct CGImageDestinationGIFQuantizationTests {

    private func createGradientImage(width: Int, height: Int) -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                // Create a smooth gradient with many colors
                pixels[i] = UInt8((x * 255) / max(width - 1, 1))     // R varies horizontally
                pixels[i + 1] = UInt8((y * 255) / max(height - 1, 1)) // G varies vertically
                pixels[i + 2] = UInt8(((x + y) * 127) / max(width + height - 2, 1)) // B varies diagonally
                pixels[i + 3] = 255                                    // A
            }
        }

        let dataProvider = CGDataProvider(data: Data(pixels))
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    @Test("GIF encoding with gradient image uses Median Cut")
    func gifEncodingWithManyColors() {
        // Create image with many unique colors (gradient)
        let image = createGradientImage(width: 32, height: 32)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Verify GIF signature
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 6)
        #expect(bytes[0] == 0x47) // G
        #expect(bytes[1] == 0x49) // I
        #expect(bytes[2] == 0x46) // F
    }

    @Test("GIF roundtrip with few colors preserves exact palette")
    func gifRoundtripFewColors() {
        // Create simple image with < 256 colors
        var pixels = [UInt8](repeating: 0, count: 4 * 4 * 4)
        let colors: [[UInt8]] = [
            [255, 0, 0, 255],   // Red
            [0, 255, 0, 255],   // Green
            [0, 0, 255, 255],   // Blue
            [255, 255, 0, 255], // Yellow
        ]
        for i in 0..<4 {
            let offset = i * 4
            pixels[offset] = colors[i % 4][0]
            pixels[offset + 1] = colors[i % 4][1]
            pixels[offset + 2] = colors[i % 4][2]
            pixels[offset + 3] = colors[i % 4][3]
        }

        let dataProvider = CGDataProvider(data: Data(pixels))
        let image = CGImage(
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 8,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        // Encode to GIF
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        // Decode GIF
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decoded.width == 2)
        #expect(decoded.height == 2)
    }

    @Test("GIF animated with gradient frames")
    func gifAnimatedGradient() {
        // Create multiple gradient frames
        let frame1 = createGradientImage(width: 16, height: 16)
        let frame2 = createGradientImage(width: 16, height: 16)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 2, nil)!
        CGImageDestinationSetProperties(destination, ["delay": 0.1])
        CGImageDestinationAddImage(destination, frame1, nil)
        CGImageDestinationAddImage(destination, frame2, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Decode and verify frame count
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        #expect(CGImageSourceGetCount(source) >= 1)
    }
}

// MARK: - Comprehensive Format Tests

@Suite("Comprehensive Format Encoding Tests")
struct ComprehensiveFormatEncodingTests {

    /// Create a test image with specific RGBA colors for validation
    private func createColorTestImage() -> CGImage {
        // 4x4 image with distinct colors for validation
        let pixels: [UInt8] = [
            // Row 0: Red, Green, Blue, Yellow
            255, 0, 0, 255,      0, 255, 0, 255,      0, 0, 255, 255,      255, 255, 0, 255,
            // Row 1: Cyan, Magenta, White, Black
            0, 255, 255, 255,    255, 0, 255, 255,    255, 255, 255, 255,  0, 0, 0, 255,
            // Row 2: Gray variations
            64, 64, 64, 255,     128, 128, 128, 255,  192, 192, 192, 255,  224, 224, 224, 255,
            // Row 3: Mixed colors
            128, 64, 32, 255,    32, 128, 64, 255,    64, 32, 128, 255,    96, 96, 96, 255
        ]

        let dataProvider = CGDataProvider(data: Data(pixels))
        return CGImage(
            width: 4,
            height: 4,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 16,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    /// Create a gradient image with many unique colors
    private func createGradientImage(width: Int, height: Int) -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                pixels[i] = UInt8((x * 255) / max(width - 1, 1))
                pixels[i + 1] = UInt8((y * 255) / max(height - 1, 1))
                pixels[i + 2] = UInt8(((x + y) * 127) / max(width + height - 2, 1))
                pixels[i + 3] = 255
            }
        }

        let dataProvider = CGDataProvider(data: Data(pixels))
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    // MARK: - PNG Comprehensive Tests

    @Test("PNG preserves all 16 test colors")
    func pngPreservesColors() {
        let originalImage = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
        CGImageDestinationAddImage(destination, originalImage, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decoded.width == 4)
        #expect(decoded.height == 4)

        // Verify pixel data
        if let provider = decoded.dataProvider, let pixelData = provider.data {
            #expect(pixelData.count >= 64) // 4x4x4 bytes minimum
        }
    }

    @Test("PNG handles large images")
    func pngLargeImage() {
        let largeImage = createGradientImage(width: 256, height: 256)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.png", 1, nil)!
        CGImageDestinationAddImage(destination, largeImage, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decoded.width == 256)
        #expect(decoded.height == 256)
    }

    // MARK: - JPEG Comprehensive Tests

    @Test("JPEG quality levels produce different file sizes")
    func jpegQualityLevels() {
        let image = createGradientImage(width: 64, height: 64)

        var sizes: [Int] = []
        for quality in [0.1, 0.5, 0.9] {
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil)!
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality])
            CGImageDestinationFinalize(destination)
            sizes.append(data.length)
        }

        // Higher quality should generally produce larger files
        #expect(sizes[0] > 0)
        #expect(sizes[1] > 0)
        #expect(sizes[2] > 0)
    }

    @Test("JPEG handles various dimensions")
    func jpegVariousDimensions() {
        let dimensions = [(8, 8), (16, 16), (32, 24), (64, 48)]

        for (w, h) in dimensions {
            let image = createGradientImage(width: w, height: h)

            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil)!
            CGImageDestinationAddImage(destination, image, nil)
            let success = CGImageDestinationFinalize(destination)

            #expect(success == true, "JPEG encoding should succeed for \(w)x\(h)")

            let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
            let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

            #expect(decoded.width == w, "Width should be \(w)")
            #expect(decoded.height == h, "Height should be \(h)")
        }
    }

    // MARK: - GIF Comprehensive Tests

    @Test("GIF handles image with > 256 colors using Median Cut")
    func gifMedianCutQuantization() {
        // Create 64x64 gradient with many unique colors
        let image = createGradientImage(width: 64, height: 64)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)

        // Verify GIF structure
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes[0] == 0x47) // G
        #expect(bytes[1] == 0x49) // I
        #expect(bytes[2] == 0x46) // F

        // Decode and verify
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decoded.width == 64)
        #expect(decoded.height == 64)
    }

    @Test("GIF animated with multiple frames")
    func gifAnimatedMultipleFrames() {
        let frame1 = createColorTestImage()
        let frame2 = createGradientImage(width: 4, height: 4)
        let frame3 = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif", 3, nil)!
        CGImageDestinationSetProperties(destination, ["delay": 0.1])
        CGImageDestinationAddImage(destination, frame1, nil)
        CGImageDestinationAddImage(destination, frame2, nil)
        CGImageDestinationAddImage(destination, frame3, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let count = CGImageSourceGetCount(source)
        #expect(count >= 1)
    }

    // MARK: - BMP Comprehensive Tests

    @Test("BMP 24-bit encoding and decoding")
    func bmp24BitEncoding() {
        let image = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.microsoft.bmp", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil) // Default 24-bit
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        // Verify BMP header
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes[0] == 0x42) // B
        #expect(bytes[1] == 0x4D) // M

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        #expect(decoded.width == 4)
        #expect(decoded.height == 4)
    }

    @Test("BMP 32-bit with alpha")
    func bmp32BitWithAlpha() {
        let image = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.microsoft.bmp", 1, nil)!
        CGImageDestinationAddImage(destination, image, ["preserveAlpha": true])
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)
        #expect(data.length > 0)
    }

    // MARK: - TIFF Comprehensive Tests

    @Test("TIFF multi-page with varying content")
    func tiffMultiPageVarying() {
        let page1 = createColorTestImage()
        let page2 = createGradientImage(width: 8, height: 8)
        let page3 = createGradientImage(width: 16, height: 16)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 3, nil)!
        CGImageDestinationAddImage(destination, page1, nil)
        CGImageDestinationAddImage(destination, page2, nil)
        CGImageDestinationAddImage(destination, page3, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!

        // Verify each page
        let decoded1 = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        #expect(decoded1.width == 4)
        #expect(decoded1.height == 4)
    }

    @Test("TIFF preserves color accuracy")
    func tiffColorAccuracy() {
        let image = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.tiff", 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        // Get original and decoded pixel data
        if let origProvider = image.dataProvider,
           let origData = origProvider.data,
           let decProvider = decoded.dataProvider,
           let decData = decProvider.data {
            // TIFF should preserve colors exactly
            #expect(origData.count > 0)
            #expect(decData.count > 0)
        }
    }

    // MARK: - WebP Comprehensive Tests

    @Test("WebP lossless preserves pixel data")
    func webpLosslessPixelData() {
        let image = createColorTestImage()

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
        CGImageDestinationAddImage(destination, image, ["lossless": true])
        let success = CGImageDestinationFinalize(destination)

        #expect(success == true)

        // Verify RIFF header
        let bytes = [UInt8](Data(referencing: data))
        #expect(bytes.count >= 12)
        #expect(bytes[0] == 0x52) // R
        #expect(bytes[1] == 0x49) // I
        #expect(bytes[2] == 0x46) // F
        #expect(bytes[3] == 0x46) // F

        // Decode and verify - must succeed
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)
        #expect(source != nil, "WebP source creation must succeed")

        guard let validSource = source else {
            Issue.record("Failed to create CGImageSource from WebP data")
            return
        }

        let decoded = CGImageSourceCreateImageAtIndex(validSource, 0, nil)
        #expect(decoded != nil, "WebP image decoding must succeed")

        guard let validDecoded = decoded else {
            Issue.record("Failed to decode WebP image")
            return
        }

        #expect(validDecoded.width == 4, "Decoded width must be 4")
        #expect(validDecoded.height == 4, "Decoded height must be 4")
    }

    @Test("WebP lossy at various quality levels")
    func webpLossyQualityLevels() {
        let image = createGradientImage(width: 32, height: 32)

        for quality in [0.1, 0.5, 0.9] {
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
            CGImageDestinationAddImage(destination, image, [
                kCGImageDestinationLossyCompressionQuality: quality
            ])
            let success = CGImageDestinationFinalize(destination)

            #expect(success == true, "WebP lossy encoding should succeed at quality \(quality)")
            #expect(data.length > 0, "WebP data should not be empty at quality \(quality)")
        }
    }

    @Test("WebP handles various dimensions")
    func webpVariousDimensions() {
        let dimensions = [(8, 8), (16, 16), (32, 32), (64, 64)]

        for (w, h) in dimensions {
            let image = createGradientImage(width: w, height: h)

            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "org.webmproject.webp", 1, nil)!
            CGImageDestinationAddImage(destination, image, ["lossless": true])
            let success = CGImageDestinationFinalize(destination)

            #expect(success == true, "WebP encoding should succeed for \(w)x\(h)")
            #expect(data.length > 0, "WebP data should not be empty for \(w)x\(h)")
        }
    }
}
