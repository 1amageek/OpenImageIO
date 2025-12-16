// CGImageSourceTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CGImageSource functionality

import Testing
@testable import OpenImageIO

// MARK: - CGImageSource Creation Tests

@Suite("CGImageSource Creation")
struct CGImageSourceCreationTests {

    @Test("Create source from valid PNG data")
    func createWithValidPNGData() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.png")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from valid JPEG data")
    func createWithValidJPEGData() {
        let data = CFData(bytes: TestData.minimalJPEG)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.jpeg")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from valid GIF data")
    func createWithValidGIFData() {
        let data = CFData(bytes: TestData.minimalGIF)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "com.compuserve.gif")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from valid BMP data")
    func createWithValidBMPData() {
        let data = CFData(bytes: TestData.minimalBMP)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "com.microsoft.bmp")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from valid TIFF data")
    func createWithValidTIFFData() {
        let data = CFData(bytes: TestData.minimalTIFF)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.tiff")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from valid WebP data")
    func createWithValidWebPData() {
        let data = CFData(bytes: TestData.minimalWebP)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "org.webmproject.webp")
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }

    @Test("Create source from empty data returns incomplete status")
    func createWithEmptyData() {
        let data = CFData(bytes: TestData.emptyData)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        // Empty data is not parsed, so status remains incomplete
        #expect(CGImageSourceGetStatus(source!) == .statusIncomplete)
    }

    @Test("Create source from invalid data returns unknown type status")
    func createWithInvalidData() {
        let data = CFData(bytes: TestData.invalidData)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetStatus(source!) == .statusUnknownType)
    }

    @Test("Create source from data provider")
    func createWithDataProvider() {
        let provider = CGDataProvider(data: TestData.minimalPNG)
        let source = CGImageSourceCreateWithDataProvider(provider, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetType(source!) == "public.png")
    }

    @Test("Create incremental source")
    func createIncremental() {
        let source = CGImageSourceCreateIncremental(nil)

        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
        #expect(CGImageSourceGetCount(source) == 0)
        #expect(CGImageSourceGetType(source) == nil)
    }
}

// MARK: - CGImageSource Information Tests

@Suite("CGImageSource Information")
struct CGImageSourceInformationTests {

    @Test("Get image count for single image")
    func getCountSingleImage() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetCount(source) == 1)
    }

    @Test("Get image count for animated GIF")
    func getCountAnimatedGIF() {
        let data = CFData(bytes: TestData.animatedGIF(frameCount: 3, width: 10, height: 10))
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetCount(source) == 3)
    }

    @Test("Get type identifiers returns supported formats")
    func getTypeIdentifiers() {
        let identifiers = CGImageSourceCopyTypeIdentifiers()

        #expect(identifiers.count >= 5)
        #expect((identifiers as! [String]).contains("public.png"))
        #expect((identifiers as! [String]).contains("public.jpeg"))
        #expect((identifiers as! [String]).contains("com.compuserve.gif"))
        #expect((identifiers as! [String]).contains("com.microsoft.bmp"))
        #expect((identifiers as! [String]).contains("public.tiff"))
    }

    @Test("Get properties from PNG")
    func getPropertiesPNG() {
        let data = CFData(bytes: TestData.pngWithDimensions(width: 100, height: 50))
        let source = CGImageSourceCreateWithData(data, nil)!

        let props = CGImageSourceCopyProperties(source, nil)
        #expect(props != nil)
        #expect(props![kCGImagePropertyPixelWidth as String] as? Int == 100)
        #expect(props![kCGImagePropertyPixelHeight as String] as? Int == 50)
    }

    @Test("Get properties at index")
    func getPropertiesAtIndex() {
        let data = CFData(bytes: TestData.minimalJPEG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        #expect(props != nil)

        let propsInvalid = CGImageSourceCopyPropertiesAtIndex(source, 99, nil)
        #expect(propsInvalid == nil)
    }

    @Test("Get properties at negative index returns nil")
    func getPropertiesAtNegativeIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let props = CGImageSourceCopyPropertiesAtIndex(source, -1, nil)
        #expect(props == nil)
    }

    @Test("Get primary image index")
    func getPrimaryImageIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let index = CGImageSourceGetPrimaryImageIndex(source)
        #expect(index == 0)
    }

    @Test("Get type ID")
    func getTypeID() {
        let typeID = CGImageSourceGetTypeID()
        // Just verify it returns a value
        #expect(typeID >= 0)
    }
}

// MARK: - CGImageSource Image Extraction Tests

@Suite("CGImageSource Image Extraction")
struct CGImageSourceImageExtractionTests {

    @Test("Create image at valid index")
    func createImageAtValidIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        #expect(image != nil)
        #expect(image!.width == 1)
        #expect(image!.height == 1)
    }

    @Test("Create image at invalid index returns nil")
    func createImageAtInvalidIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, 99, nil)
        #expect(image == nil)
    }

    @Test("Create image at negative index returns nil")
    func createImageAtNegativeIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let image = CGImageSourceCreateImageAtIndex(source, -1, nil)
        #expect(image == nil)
    }

    @Test("Create thumbnail at valid index")
    func createThumbnailAtValidIndex() {
        let data = CFData(bytes: TestData.pngWithDimensions(width: 100, height: 100))
        let source = CGImageSourceCreateWithData(data, nil)!

        let options: CFDictionary = [
            kCGImageSourceThumbnailMaxPixelSize as String: 50
        ]
        let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options)

        #expect(thumbnail != nil)
        #expect(thumbnail!.width <= 50)
        #expect(thumbnail!.height <= 50)
    }

    @Test("Create thumbnail at invalid index returns nil")
    func createThumbnailAtInvalidIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 99, nil)
        #expect(thumbnail == nil)
    }

    @Test("Create thumbnail without max size")
    func createThumbnailWithoutMaxSize() {
        let data = CFData(bytes: TestData.pngWithDimensions(width: 200, height: 100))
        let source = CGImageSourceCreateWithData(data, nil)!

        let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, nil)
        #expect(thumbnail != nil)
        // Without max size, should return original dimensions
        #expect(thumbnail!.width == 200)
        #expect(thumbnail!.height == 100)
    }
}

// MARK: - CGImageSource Status Tests

@Suite("CGImageSource Status")
struct CGImageSourceStatusTests {

    @Test("Get status for complete source")
    func getStatusComplete() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatus(source) == .statusComplete)
    }

    @Test("Get status for incomplete source")
    func getStatusIncomplete() {
        let source = CGImageSourceCreateIncremental(nil)

        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
    }

    @Test("Get status for empty data is incomplete")
    func getStatusEmpty() {
        let data = CFData(bytes: TestData.emptyData)
        let source = CGImageSourceCreateWithData(data, nil)!

        // Empty data is not parsed, so status remains incomplete
        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
    }

    @Test("Get status for truncated data is invalid")
    func getStatusTruncated() {
        // Data that is too short to be any valid format
        let data = CFData(bytes: [0x00, 0x01, 0x02, 0x03])
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatus(source) == .statusInvalidData)
    }

    @Test("Get status for unknown type")
    func getStatusUnknownType() {
        let data = CFData(bytes: TestData.invalidData)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatus(source) == .statusUnknownType)
    }

    @Test("Get status at valid index")
    func getStatusAtValidIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete)
    }

    @Test("Get status at invalid index")
    func getStatusAtInvalidIndex() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(CGImageSourceGetStatusAtIndex(source, 99) == .statusInvalidData)
    }
}

// MARK: - CGImageSource Incremental Tests

@Suite("CGImageSource Incremental Loading")
struct CGImageSourceIncrementalTests {

    @Test("Update data incrementally")
    func updateDataIncrementally() {
        let source = CGImageSourceCreateIncremental(nil)

        // Initial state
        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
        #expect(CGImageSourceGetCount(source) == 0)

        // Update with partial data
        let partialData = CFData(bytes: Array(TestData.minimalPNG.prefix(10)))
        CGImageSourceUpdateData(source, partialData, false)
        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)

        // Update with complete data
        let completeData = CFData(bytes: TestData.minimalPNG)
        CGImageSourceUpdateData(source, completeData, true)
        #expect(CGImageSourceGetStatus(source) == .statusComplete)
        #expect(CGImageSourceGetCount(source) == 1)
    }

    @Test("Update data provider incrementally")
    func updateDataProviderIncrementally() {
        let source = CGImageSourceCreateIncremental(nil)

        // Update with partial data
        let partialProvider = CGDataProvider(data: Array(TestData.minimalJPEG.prefix(10)))
        CGImageSourceUpdateDataProvider(source, partialProvider, false)
        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)

        // Update with complete data
        let completeProvider = CGDataProvider(data: TestData.minimalJPEG)
        CGImageSourceUpdateDataProvider(source, completeProvider, true)
        #expect(CGImageSourceGetStatus(source) == .statusComplete)
    }

    @Test("Incremental source with options")
    func incrementalWithOptions() {
        let options: CFDictionary = [
            kCGImageSourceTypeIdentifierHint as String: "public.png"
        ]
        let source = CGImageSourceCreateIncremental(options)

        #expect(CGImageSourceGetStatus(source) == .statusIncomplete)
    }
}

// MARK: - CGImageSource Options Keys Tests

@Suite("CGImageSource Options Keys")
struct CGImageSourceOptionsTests {

    @Test("Options keys are defined")
    func optionsKeysDefined() {
        #expect(!kCGImageSourceTypeIdentifierHint.isEmpty)
        #expect(!kCGImageSourceShouldAllowFloat.isEmpty)
        #expect(!kCGImageSourceShouldCache.isEmpty)
        #expect(!kCGImageSourceShouldCacheImmediately.isEmpty)
        #expect(!kCGImageSourceCreateThumbnailFromImageIfAbsent.isEmpty)
        #expect(!kCGImageSourceCreateThumbnailFromImageAlways.isEmpty)
        #expect(!kCGImageSourceThumbnailMaxPixelSize.isEmpty)
        #expect(!kCGImageSourceCreateThumbnailWithTransform.isEmpty)
        #expect(!kCGImageSourceSubsampleFactor.isEmpty)
    }

    @Test("Create source with options")
    func createWithOptions() {
        let options: CFDictionary = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: "public.png"
        ]
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, options)

        #expect(source != nil)
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
    }
}

// MARK: - CGImageSource Equality Tests

@Suite("CGImageSource Equality")
struct CGImageSourceEqualityTests {

    @Test("Same source is equal to itself")
    func sameSourceEqual() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        #expect(source == source)
    }

    @Test("Different sources are not equal")
    func differentSourcesNotEqual() {
        let data1 = CFData(bytes: TestData.minimalPNG)
        let data2 = CFData(bytes: TestData.minimalPNG)
        let source1 = CGImageSourceCreateWithData(data1, nil)!
        let source2 = CGImageSourceCreateWithData(data2, nil)!

        #expect(source1 != source2)
    }

    @Test("Source can be used as dictionary key")
    func sourceAsDictionaryKey() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        var dict: [CGImageSource: String] = [:]
        dict[source] = "test"

        #expect(dict[source] == "test")
    }
}

// MARK: - CGImageSource Auxiliary Data Tests

@Suite("CGImageSource Auxiliary Data")
struct CGImageSourceAuxiliaryDataTests {

    @Test("Copy auxiliary data info returns nil for basic image")
    func copyAuxiliaryDataInfoReturnsNil() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)!

        let auxData = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
            source,
            0,
            kCGImageAuxiliaryDataTypeDepth
        )

        #expect(auxData == nil)
    }
}
