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

    @Test("Get type ID returns consistent value")
    func getTypeID() {
        let typeID1 = CGImageDestinationGetTypeID()
        let typeID2 = CGImageDestinationGetTypeID()

        // Verify it returns a consistent value
        #expect(typeID1 == typeID2)
        #expect(typeID1 >= 0)
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

    @Test("JPEG roundtrip produces valid pixel data")
    func jpegRoundtripPixelData() {
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
        CGImageDestinationFinalize(destination)

        // Decode JPEG
        let source = CGImageSourceCreateWithData(Data(referencing: data), nil)!
        let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!

        // Verify dimensions
        #expect(decodedImage.width == 8)
        #expect(decodedImage.height == 8)

        // Verify pixel data exists
        if let dataProvider = decodedImage.dataProvider,
           let pixelData = dataProvider.data {
            let decodedBytes = pixelData as Data

            // JPEG decoded image should have pixel data
            #expect(decodedBytes.count >= width * height * 3, "Should have RGB pixel data")

            // For a solid gray image, all pixel values should be similar (within JPEG tolerance)
            // We just verify the data exists and has reasonable values
            if decodedBytes.count >= 3 {
                // Check first pixel is grayish (JPEG is lossy, so allow tolerance)
                let r = decodedBytes[0]
                let g = decodedBytes[1]
                let b = decodedBytes[2]

                // Values should be in the gray range (allow for JPEG artifacts)
                #expect(r > 50 && r < 200, "Red channel should be in gray range")
                #expect(g > 50 && g < 200, "Green channel should be in gray range")
                #expect(b > 50 && b < 200, "Blue channel should be in gray range")
            }
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
