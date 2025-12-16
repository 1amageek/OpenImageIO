// CGImageDestinationTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CGImageDestination functionality

import Testing
@testable import OpenImageIO

// MARK: - CGImageDestination Creation Tests

@Suite("CGImageDestination Creation")
struct CGImageDestinationCreationTests {

    @Test("Create destination with mutable data for PNG")
    func createWithDataPNG() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for JPEG")
    func createWithDataJPEG() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for GIF")
    func createWithDataGIF() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif" as CFString,
            3,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for BMP")
    func createWithDataBMP() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.microsoft.bmp" as CFString,
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with mutable data for TIFF")
    func createWithDataTIFF() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.tiff" as CFString,
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with zero count returns nil")
    func createWithZeroCount() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            0,
            nil
        )

        #expect(destination == nil)
    }

    @Test("Create destination with negative count returns nil")
    func createWithNegativeCount() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            -1,
            nil
        )

        #expect(destination == nil)
    }

    @Test("Create destination with data consumer")
    func createWithDataConsumer() {
        let consumer = CGDataConsumer()
        let destination = CGImageDestinationCreateWithDataConsumer(
            consumer,
            "public.png" as CFString,
            1,
            nil
        )

        #expect(destination != nil)
    }

    @Test("Create destination with URL")
    func createWithURL() {
        let url = CFURL(fileURLWithPath: "/tmp/test_output.png")
        let destination = CGImageDestinationCreateWithURL(
            url,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        let properties: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality as String: 0.9
        ]
        CGImageDestinationAddImage(destination, image, properties)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add image from source")
    func addImageFromSource() {
        let sourceData = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(sourceData, nil)!

        let destData = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            destData,
            "public.png" as CFString,
            1,
            nil
        )!

        CGImageDestinationAddImageFromSource(destination, source, 0, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add image from source with invalid index is ignored")
    func addImageFromSourceInvalidIndex() {
        let sourceData = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(sourceData, nil)!

        let destData = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            destData,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        )!

        let properties: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality as String: 0.8
        ]
        CGImageDestinationSetProperties(destination, properties)

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }

    @Test("Add auxiliary data info")
    func addAuxiliaryDataInfo() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        let auxData: CFDictionary = ["test": "value"]
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // This should be ignored
        let properties: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality as String: 0.5
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        let success = CGImageDestinationFinalize(destination)
        #expect(success == false)
    }

    @Test("Finalize twice fails on second call")
    func finalizeTwice() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
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
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
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
        let consumer = CGDataConsumer()
        let destination = CGImageDestinationCreateWithDataConsumer(
            consumer,
            "public.png" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        CGImageDestinationAddImage(destination, image, nil)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
        #expect(consumer.data.count > 0)
    }
}

// MARK: - CGImageDestination Type Information Tests

@Suite("CGImageDestination Type Information")
struct CGImageDestinationTypeInformationTests {

    @Test("Get type identifiers")
    func getTypeIdentifiers() {
        let identifiers = CGImageDestinationCopyTypeIdentifiers()

        #expect(identifiers.count >= 4)
        #expect((identifiers as! [String]).contains("public.png"))
        #expect((identifiers as! [String]).contains("public.jpeg"))
        #expect((identifiers as! [String]).contains("com.compuserve.gif"))
        #expect((identifiers as! [String]).contains("public.tiff"))
    }

    @Test("Get type ID")
    func getTypeID() {
        let typeID = CGImageDestinationGetTypeID()
        #expect(typeID >= 0)
    }
}

// MARK: - CGImageDestination Output Format Tests

@Suite("CGImageDestination Output Formats")
struct CGImageDestinationOutputFormatTests {

    @Test("Output PNG format")
    func outputPNG() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify PNG signature
        #expect(data.bytes.count >= 8)
        #expect(data.bytes[0] == 0x89)
        #expect(data.bytes[1] == 0x50)
        #expect(data.bytes[2] == 0x4E)
        #expect(data.bytes[3] == 0x47)
    }

    @Test("Output JPEG format")
    func outputJPEG() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify JPEG signature
        #expect(data.bytes.count >= 2)
        #expect(data.bytes[0] == 0xFF)
        #expect(data.bytes[1] == 0xD8)
    }

    @Test("Output GIF format")
    func outputGIF() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify GIF signature
        #expect(data.bytes.count >= 6)
        let signature = String(bytes: data.bytes.prefix(6), encoding: .ascii)
        #expect(signature == "GIF89a")
    }

    @Test("Output BMP format")
    func outputBMP() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "com.microsoft.bmp" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify BMP signature
        #expect(data.bytes.count >= 2)
        #expect(data.bytes[0] == 0x42) // 'B'
        #expect(data.bytes[1] == 0x4D) // 'M'
    }

    @Test("Output TIFF format")
    func outputTIFF() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.tiff" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 2, height: 2)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        // Verify TIFF signature (little-endian)
        #expect(data.bytes.count >= 4)
        #expect(data.bytes[0] == 0x49) // 'I'
        #expect(data.bytes[1] == 0x49) // 'I'
        #expect(data.bytes[2] == 0x2A) // Magic
        #expect(data.bytes[3] == 0x00)
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

    @Test("JPEG with compression quality")
    func jpegWithCompressionQuality() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        )!

        let image = createTestImage(width: 10, height: 10)
        let properties: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality as String: 0.5
        ]
        CGImageDestinationAddImage(destination, image, properties)

        let success = CGImageDestinationFinalize(destination)
        #expect(success == true)
    }
}

// MARK: - CGImageDestination Equality Tests

@Suite("CGImageDestination Equality")
struct CGImageDestinationEqualityTests {

    @Test("Same destination is equal to itself")
    func sameDestinationEqual() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        #expect(destination == destination)
    }

    @Test("Different destinations are not equal")
    func differentDestinationsNotEqual() {
        let data1 = CFMutableData()
        let data2 = CFMutableData()
        let dest1 = CGImageDestinationCreateWithData(data1, "public.png", 1, nil)!
        let dest2 = CGImageDestinationCreateWithData(data2, "public.png", 1, nil)!

        #expect(dest1 != dest2)
    }

    @Test("Destination can be used as dictionary key")
    func destinationAsDictionaryKey() {
        let data = CFMutableData()
        let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        )!

        var dict: [CGImageDestination: String] = [:]
        dict[destination] = "test"

        #expect(dict[destination] == "test")
    }
}
