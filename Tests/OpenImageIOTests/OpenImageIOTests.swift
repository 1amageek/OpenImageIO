import Testing
@testable import OpenImageIO

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
    #expect((identifiers as! [String]).contains("public.png"))
    #expect((identifiers as! [String]).contains("public.jpeg"))
}

@Test func testCGImageSourceCreateWithPNGData() {
    // Create a minimal valid PNG
    let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    // IHDR chunk: width=1, height=1, bit depth=8, color type=6 (RGBA)
    let ihdrLength: [UInt8] = [0x00, 0x00, 0x00, 0x0D]
    let ihdrType: [UInt8] = [0x49, 0x48, 0x44, 0x52] // "IHDR"
    let ihdrData: [UInt8] = [
        0x00, 0x00, 0x00, 0x01, // width = 1
        0x00, 0x00, 0x00, 0x01, // height = 1
        0x08,                   // bit depth = 8
        0x06,                   // color type = 6 (RGBA)
        0x00,                   // compression = 0
        0x00,                   // filter = 0
        0x00                    // interlace = 0
    ]
    let ihdrCRC: [UInt8] = [0x1F, 0x15, 0xC4, 0x89] // CRC placeholder

    var pngData: [UInt8] = []
    pngData.append(contentsOf: pngSignature)
    pngData.append(contentsOf: ihdrLength)
    pngData.append(contentsOf: ihdrType)
    pngData.append(contentsOf: ihdrData)
    pngData.append(contentsOf: ihdrCRC)

    let cfData = CFData(bytes: pngData)
    let source = CGImageSourceCreateWithData(cfData, nil)

    #expect(source != nil)
    #expect(CGImageSourceGetType(source!) == "public.png")
    #expect(CGImageSourceGetCount(source!) == 1)
    #expect(CGImageSourceGetStatus(source!) == .statusComplete)

    // Check properties
    let props = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)
    #expect(props != nil)
    #expect(props![kCGImagePropertyPixelWidth as String] as? Int == 1)
    #expect(props![kCGImagePropertyPixelHeight as String] as? Int == 1)
}

@Test func testCGImageSourceCreateWithJPEGData() {
    // Create minimal JPEG header
    let jpegData: [UInt8] = [
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

    let cfData = CFData(bytes: jpegData)
    let source = CGImageSourceCreateWithData(cfData, nil)

    #expect(source != nil)
    #expect(CGImageSourceGetType(source!) == "public.jpeg")
    #expect(CGImageSourceGetCount(source!) == 1)
}

// MARK: - CGImageDestination Tests

@Test func testCGImageDestinationTypeIdentifiers() {
    let identifiers = CGImageDestinationCopyTypeIdentifiers()
    #expect(identifiers.count > 0)
    #expect((identifiers as! [String]).contains("public.png"))
    #expect((identifiers as! [String]).contains("public.jpeg"))
}

@Test func testCGImageDestinationCreateWithData() {
    let data = CFMutableData()
    let destination = CGImageDestinationCreateWithData(
        data,
        "public.png" as CFString,
        1,
        nil
    )

    #expect(destination != nil)
}

@Test func testCGImageDestinationAddImageAndFinalize() {
    let data = CFMutableData()
    let destination = CGImageDestinationCreateWithData(
        data,
        "public.png" as CFString,
        1,
        nil
    )!

    // Create a simple test image
    let image = CGImage(
        width: 2,
        height: 2,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 8,
        data: [UInt8](repeating: 255, count: 16)
    )

    CGImageDestinationAddImage(destination, image, nil)
    let success = CGImageDestinationFinalize(destination)

    #expect(success == true)
    #expect(data.length > 0)
}

// MARK: - CGImageMetadataTag Tests

@Test func testCGImageMetadataTagCreate() {
    let tag = CGImageMetadataTagCreate(
        kCGImageMetadataNamespaceDublinCore,
        kCGImageMetadataPrefixDublinCore,
        "title" as CFString,
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
    #expect(metadata != nil)

    let tags = CGImageMetadataCopyTags(metadata)
    #expect(tags == nil) // Empty metadata should have no tags
}

@Test func testCGImageMetadataSetValue() {
    let metadata = CGImageMetadataCreateMutable()

    let success = CGImageMetadataSetValueWithPath(
        metadata,
        nil,
        "dc:title" as CFString,
        "Test Title"
    )

    #expect(success == true)

    let value = CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:title" as CFString)
    #expect(value == "Test Title")
}

// MARK: - XMP Namespace Tests

@Test func testXMPNamespaces() {
    #expect(kCGImageMetadataNamespaceDublinCore as String == "http://purl.org/dc/elements/1.1/")
    #expect(kCGImageMetadataNamespaceExif as String == "http://ns.adobe.com/exif/1.0/")
    #expect(kCGImageMetadataNamespaceTIFF as String == "http://ns.adobe.com/tiff/1.0/")
    #expect(kCGImageMetadataNamespaceXMPBasic as String == "http://ns.adobe.com/xap/1.0/")
}

@Test func testXMPPrefixes() {
    #expect(kCGImageMetadataPrefixDublinCore as String == "dc")
    #expect(kCGImageMetadataPrefixExif as String == "exif")
    #expect(kCGImageMetadataPrefixTIFF as String == "tiff")
    #expect(kCGImageMetadataPrefixXMPBasic as String == "xmp")
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
