import Testing
import Foundation
@testable import OpenImageIO
import OpenCoreGraphics

// MARK: - CGImageSourceStatus Tests

@Test func testCGImageSourceStatusValues() {
    #expect(CGImageSourceStatus.statusUnexpectedEOF.rawValue == -5)
    #expect(CGImageSourceStatus.statusInvalidData.rawValue == -4)
    #expect(CGImageSourceStatus.statusUnknownType.rawValue == -3)
    #expect(CGImageSourceStatus.statusReadingHeader.rawValue == -2)
    #expect(CGImageSourceStatus.statusIncomplete.rawValue == -1)
    #expect(CGImageSourceStatus.statusComplete.rawValue == 0)
}

@Test func testCGImageSourceStatusFromRawValue() {
    #expect(CGImageSourceStatus(rawValue: -5) == .statusUnexpectedEOF)
    #expect(CGImageSourceStatus(rawValue: 0) == .statusComplete)
    #expect(CGImageSourceStatus(rawValue: 100) == nil)
}

// MARK: - CGImageMetadataType Tests

@Test func testCGImageMetadataTypeValues() {
    #expect(CGImageMetadataType.invalid.rawValue == -1)
    #expect(CGImageMetadataType.default.rawValue == 0)
    #expect(CGImageMetadataType.string.rawValue == 1)
    #expect(CGImageMetadataType.arrayUnordered.rawValue == 2)
    #expect(CGImageMetadataType.arrayOrdered.rawValue == 3)
    #expect(CGImageMetadataType.alternateArray.rawValue == 4)
    #expect(CGImageMetadataType.alternateText.rawValue == 5)
    #expect(CGImageMetadataType.structure.rawValue == 6)
}

// MARK: - CGImageMetadataErrors Tests

@Test func testCGImageMetadataErrorsValues() {
    #expect(CGImageMetadataErrors.unknown.rawValue == 0)
    #expect(CGImageMetadataErrors.unsupportedFormat.rawValue == 1)
    #expect(CGImageMetadataErrors.badArgument.rawValue == 2)
    #expect(CGImageMetadataErrors.conflictingArguments.rawValue == 3)
    #expect(CGImageMetadataErrors.prefixConflict.rawValue == 4)
}

// MARK: - CGImagePropertyOrientation Tests

@Test func testCGImagePropertyOrientationValues() {
    #expect(CGImagePropertyOrientation.up.rawValue == 1)
    #expect(CGImagePropertyOrientation.upMirrored.rawValue == 2)
    #expect(CGImagePropertyOrientation.down.rawValue == 3)
    #expect(CGImagePropertyOrientation.downMirrored.rawValue == 4)
    #expect(CGImagePropertyOrientation.leftMirrored.rawValue == 5)
    #expect(CGImagePropertyOrientation.right.rawValue == 6)
    #expect(CGImagePropertyOrientation.rightMirrored.rawValue == 7)
    #expect(CGImagePropertyOrientation.left.rawValue == 8)
}

// MARK: - CGImageSource Tests

@Test func testCGImageSourceCreateIncremental() {
    let source = CGImageSourceCreateIncremental(nil)
    #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
    #expect(CGImageSourceGetCount(source) == 0)
}

@Test func testCGImageSourceTypeIdentifiers() {
    let identifiers = CGImageSourceCopyTypeIdentifiers()
    #expect(identifiers.count > 0)
    #expect(identifiers.contains("public.png"))
    #expect(identifiers.contains("public.jpeg"))
}

@Test func testCGImageSourceCreateWithPNGData() {
    let data = TestData.minimalPNG
    let source = CGImageSourceCreateWithData(data, nil)

    #expect(source != nil)
    #expect(CGImageSourceGetType(source!) == "public.png")
    #expect(CGImageSourceGetCount(source!) == 1)
    #expect(CGImageSourceGetStatus(source!) == .statusComplete)

    // Check properties
    let props = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)
    #expect(props != nil)
    #expect(props![kCGImagePropertyPixelWidth] as? Int == 1)
    #expect(props![kCGImagePropertyPixelHeight] as? Int == 1)
}

@Test func testCGImageSourceCreateWithJPEGData() {
    let data = TestData.minimalJPEG
    let source = CGImageSourceCreateWithData(data, nil)

    #expect(source != nil)
    #expect(CGImageSourceGetType(source!) == "public.jpeg")
    #expect(CGImageSourceGetCount(source!) == 1)
}

// MARK: - CGImageDestination Tests

@Test func testCGImageDestinationTypeIdentifiers() {
    let identifiers = CGImageDestinationCopyTypeIdentifiers()
    #expect(identifiers.count > 0)
    #expect(identifiers.contains("public.png"))
    #expect(identifiers.contains("public.jpeg"))
}

@Test func testCGImageDestinationCreateWithData() {
    var data = Data()
    let destination = CGImageDestinationCreateWithData(
        &data,
        "public.png",
        1,
        nil
    )

    #expect(destination != nil)
}

@Test func testCGImageDestinationAddImageAndFinalize() {
    var data = Data()
    let destination = CGImageDestinationCreateWithData(
        &data,
        "public.png",
        1,
        nil
    )!

    // Create a simple test image
    let image = createTestImage(width: 2, height: 2)

    CGImageDestinationAddImage(destination, image, nil)
    let success = CGImageDestinationFinalize(destination)

    #expect(success == true)
    #expect((CGImageDestinationCopyData(destination) ?? Data()).count > 0)
}

// MARK: - CGImageMetadataTag Tests

@Test func testCGImageMetadataTagCreate() {
    let tag = CGImageMetadataTagCreate(
        kCGImageMetadataNamespaceDublinCore,
        kCGImageMetadataPrefixDublinCore,
        "title",
        .string,
        "Test Title"
    )

    #expect(tag != nil)
    #expect(CGImageMetadataTagCopyName(tag!) == "title")
    #expect(CGImageMetadataTagCopyNamespace(tag!)! == kCGImageMetadataNamespaceDublinCore)
    #expect(CGImageMetadataTagCopyPrefix(tag!) == "dc")
    #expect(CGImageMetadataTagGetType(tag!) == .string)
    #expect(CGImageMetadataTagCopyValue(tag!) as? String == "Test Title")
}

// MARK: - CGImageMetadata Tests

@Test func testCGImageMetadataCreateMutable() {
    let metadata = CGImageMetadataCreateMutable()

    let tags = CGImageMetadataCopyTags(metadata)
    #expect(tags == nil) // Empty metadata should have no tags
}

@Test func testCGImageMetadataSetValue() {
    let metadata = CGImageMetadataCreateMutable()

    let success = CGImageMetadataSetValueWithPath(
        metadata,
        nil,
        "dc:title",
        "Test Title"
    )

    #expect(success == true)

    let value = CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:title")
    #expect(value == "Test Title")
}

// MARK: - XMP Namespace Tests

@Test func testXMPNamespaces() {
    #expect(kCGImageMetadataNamespaceDublinCore == "http://purl.org/dc/elements/1.1/")
    #expect(kCGImageMetadataNamespaceExif == "http://ns.adobe.com/exif/1.0/")
    #expect(kCGImageMetadataNamespaceTIFF == "http://ns.adobe.com/tiff/1.0/")
    #expect(kCGImageMetadataNamespaceXMPBasic == "http://ns.adobe.com/xap/1.0/")
}

@Test func testXMPPrefixes() {
    #expect(kCGImageMetadataPrefixDublinCore == "dc")
    #expect(kCGImageMetadataPrefixExif == "exif")
    #expect(kCGImageMetadataPrefixTIFF == "tiff")
    #expect(kCGImageMetadataPrefixXMPBasic == "xmp")
}

// MARK: - Property Constants Tests

@Test func testImagePropertyConstants() {
    // Test that constants are defined
    #expect(!kCGImagePropertyPixelWidth.isEmpty)
    #expect(!kCGImagePropertyPixelHeight.isEmpty)
    #expect(!kCGImagePropertyDepth.isEmpty)
    #expect(!kCGImagePropertyOrientation.isEmpty)
    #expect(!kCGImagePropertyColorModel.isEmpty)
}

@Test func testEXIFPropertyConstants() {
    #expect(!kCGImagePropertyExifDictionary.isEmpty)
    #expect(!kCGImagePropertyExifExposureTime.isEmpty)
    #expect(!kCGImagePropertyExifFNumber.isEmpty)
    #expect(!kCGImagePropertyExifISOSpeedRatings.isEmpty)
}

@Test func testIPTCPropertyConstants() {
    #expect(!kCGImagePropertyIPTCDictionary.isEmpty)
    #expect(!kCGImagePropertyIPTCKeywords.isEmpty)
    #expect(!kCGImagePropertyIPTCCopyrightNotice.isEmpty)
}

@Test func testGPSPropertyConstants() {
    #expect(!kCGImagePropertyGPSDictionary.isEmpty)
    #expect(!kCGImagePropertyGPSLatitude.isEmpty)
    #expect(!kCGImagePropertyGPSLongitude.isEmpty)
}

// MARK: - Exact String Property Constants

@Test func testFileContentsDictionaryConstantExactValue() {
    #expect(kCGImagePropertyFileContentsDictionary == "{FileContents}")
}

@Test func testAnimationPropertyConstantsExactValues() {
    #expect(kCGImageAnimationStartIndex == "StartIndex")
    #expect(kCGImageAnimationDelayTime == "DelayTime")
    #expect(kCGImageAnimationLoopCount == "LoopCount")
}
