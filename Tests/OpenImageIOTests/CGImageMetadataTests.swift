// CGImageMetadataTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CGImageMetadata functionality

import Testing
import Foundation
@testable import OpenImageIO

// MARK: - CGImageMetadata Creation Tests

@Suite("CGImageMetadata Creation")
struct CGImageMetadataCreationTests {

    @Test("Create mutable metadata")
    func createMutable() {
        let metadata = CGImageMetadataCreateMutable()

        #expect(CGImageMetadataCopyTags(metadata) == nil) // Empty metadata
    }

    @Test("Create mutable copy of metadata")
    func createMutableCopy() {
        let original = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(
            original,
            nil,
            "dc:title",
            "Test Title"
        )

        let copy = CGImageMetadataCreateMutableCopy(original)

        #expect(copy != nil)
        let value = CGImageMetadataCopyStringValueWithPath(copy!, nil, "dc:title")
        #expect(value == "Test Title")
    }

    @Test("Mutable copies own independent metadata state")
    func mutableCopyIsIndependent() throws {
        let original = CGImageMetadataCreateMutable()
        #expect(CGImageMetadataSetValueWithPath(original, nil, "dc:title", "Original"))

        let copy = try #require(CGImageMetadataCreateMutableCopy(original))
        #expect(CGImageMetadataSetValueWithPath(copy, nil, "dc:title", "Copy"))
        #expect(CGImageMetadataSetValueWithPath(original, nil, "dc:creator", "Author"))

        #expect(CGImageMetadataCopyStringValueWithPath(original, nil, "dc:title") == "Original")
        #expect(CGImageMetadataCopyStringValueWithPath(copy, nil, "dc:title") == "Copy")
        #expect(CGImageMetadataCopyStringValueWithPath(copy, nil, "dc:creator") == nil)
    }

    @Test("Create metadata from XMP data")
    func createFromXMPData() {
        let xmpData = TestData.sampleXMP
        let metadata = CGImageMetadataCreateFromXMPData(xmpData)

        #expect(metadata != nil)
        #expect(CGImageMetadataCopyStringValueWithPath(metadata!, nil, "dc:title") == "Test Image Title")
    }

    @Test("Create metadata from empty XMP returns nil")
    func createFromEmptyXMP() {
        let xmpData = Data()
        let metadata = CGImageMetadataCreateFromXMPData(xmpData)

        #expect(metadata == nil)
    }

}

// MARK: - CGImageMetadata Tag Access Tests

@Suite("CGImageMetadata Tag Access")
struct CGImageMetadataTagAccessTests {

    @Test("Copy tag with path")
    func copyTagWithPath() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "My Title"
        )

        let tag = CGImageMetadataCopyTagWithPath(metadata, nil, "dc:title")

        #expect(tag != nil)
        #expect(CGImageMetadataTagCopyName(tag!) == "title")
    }

    @Test("Copy tag with invalid path returns nil")
    func copyTagWithInvalidPath() {
        let metadata = CGImageMetadataCreateMutable()

        let tag = CGImageMetadataCopyTagWithPath(metadata, nil, "invalid:path")

        #expect(tag == nil)
    }

    @Test("Copy all tags")
    func copyAllTags() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:title", "Title")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:creator", "Creator")

        let tags = CGImageMetadataCopyTags(metadata)

        #expect(tags != nil)
        #expect(tags!.count == 2)
    }

    @Test("Copy tags from empty metadata returns nil")
    func copyTagsFromEmptyMetadata() {
        let metadata = CGImageMetadataCreateMutable()

        let tags = CGImageMetadataCopyTags(metadata)

        #expect(tags == nil)
    }

    @Test("Copy string value with path")
    func copyStringValueWithPath() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:description",
            "A description"
        )

        let value = CGImageMetadataCopyStringValueWithPath(
            metadata,
            nil,
            "dc:description"
        )

        #expect(value == "A description")
    }

    @Test("Copy string value with invalid path returns nil")
    func copyStringValueWithInvalidPath() {
        let metadata = CGImageMetadataCreateMutable()

        let value = CGImageMetadataCopyStringValueWithPath(
            metadata,
            nil,
            "invalid:path"
        )

        #expect(value == nil)
    }

    @Test("Copy tag matching image property")
    func copyTagMatchingImageProperty() {
        let metadata = CGImageMetadataCreateMutable()

        // Add a tag with a matching namespace
        if let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceTIFF,
            kCGImageMetadataPrefixTIFF,
            "Make",
            .string,
            "Apple"
        ) {
            CGImageMetadataSetTagWithPath(
                metadata,
                nil,
                "tiff:Make",
                tag
            )
        }

        let foundTag = CGImageMetadataCopyTagMatchingImageProperty(
            metadata,
            kCGImageMetadataNamespaceTIFF,
            "Make"
        )

        #expect(foundTag != nil)
    }
}

// MARK: - CGMutableImageMetadata Tests

@Suite("CGMutableImageMetadata Operations")
struct CGMutableImageMetadataTests {

    @Test("Set value with path")
    func setValueWithPath() {
        let metadata = CGImageMetadataCreateMutable()

        let success = CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "Test Title"
        )

        #expect(success == true)

        let value = CGImageMetadataCopyStringValueWithPath(
            metadata,
            nil,
            "dc:title"
        )
        #expect(value == "Test Title")
    }

    @Test("Update existing value")
    func updateExistingValue() {
        let metadata = CGImageMetadataCreateMutable()

        CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "Original Title"
        )

        CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "Updated Title"
        )

        let value = CGImageMetadataCopyStringValueWithPath(
            metadata,
            nil,
            "dc:title"
        )
        #expect(value == "Updated Title")
    }

    @Test("Remove tag with path")
    func removeTagWithPath() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "Title to Remove"
        )

        let removed = CGImageMetadataRemoveTagWithPath(
            metadata,
            nil,
            "dc:title"
        )

        #expect(removed == true)

        let value = CGImageMetadataCopyStringValueWithPath(
            metadata,
            nil,
            "dc:title"
        )
        #expect(value == nil)
    }

    @Test("Remove non-existent tag returns false")
    func removeNonExistentTag() {
        let metadata = CGImageMetadataCreateMutable()

        let removed = CGImageMetadataRemoveTagWithPath(
            metadata,
            nil,
            "dc:nonexistent"
        )

        #expect(removed == false)
    }

    @Test("Set tag with path")
    func setTagWithPath() {
        let metadata = CGImageMetadataCreateMutable()

        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "creator",
            .string,
            "Test Author"
        )!

        let success = CGImageMetadataSetTagWithPath(
            metadata,
            nil,
            "dc:creator",
            tag
        )

        #expect(success == true)

        let foundTag = CGImageMetadataCopyTagWithPath(
            metadata,
            nil,
            "dc:creator"
        )
        #expect(foundTag != nil)
        #expect(CGImageMetadataTagCopyValue(foundTag!) as? String == "Test Author")
    }

    @Test("Set value matching image property")
    func setValueMatchingImageProperty() {
        let metadata = CGImageMetadataCreateMutable()

        let success = CGImageMetadataSetValueMatchingImageProperty(
            metadata,
            kCGImageMetadataNamespaceExif,
            "ExposureTime",
            "1/100"
        )

        #expect(success == true)
    }

    @Test("Register namespace for prefix")
    func registerNamespaceForPrefix() {
        let metadata = CGImageMetadataCreateMutable()

        let success = CGImageMetadataRegisterNamespaceForPrefix(
            metadata,
            "http://example.com/custom/",
            "custom",
            nil
        )

        #expect(success == true)
        #expect(CGImageMetadataSetValueWithPath(metadata, nil, "custom:rating", "5"))
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "custom:rating") == "5")
    }

    @Test("Namespace registration rejects conflicts and reports an error")
    func registerNamespaceConflict() {
        let metadata = CGImageMetadataCreateMutable()
        var error: Error?

        #expect(CGImageMetadataRegisterNamespaceForPrefix(
            metadata,
            "http://example.com/first/",
            "custom",
            &error
        ))
        #expect(!CGImageMetadataRegisterNamespaceForPrefix(
            metadata,
            "http://example.com/second/",
            "custom",
            &error
        ))
        #expect(error != nil)
    }

    @Test("Namespace registration rejects malformed values")
    func registerMalformedNamespace() {
        let metadata = CGImageMetadataCreateMutable()
        var error: Error?

        #expect(!CGImageMetadataRegisterNamespaceForPrefix(metadata, "not a namespace", "bad prefix", &error))
        #expect(error != nil)
        #expect(!CGImageMetadataSetValueWithPath(metadata, nil, "bad:tag", "value"))
    }
}

// MARK: - CGImageMetadata Enumeration Tests

@Suite("CGImageMetadata Enumeration")
struct CGImageMetadataEnumerationTests {

    @Test("Enumerate tags using block")
    func enumerateTagsUsingBlock() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:title", "Title")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:creator", "Creator")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:subject", "Subject")

        var enumeratedCount = 0
        var enumeratedPaths: [String] = []

        CGImageMetadataEnumerateTagsUsingBlock(metadata, nil, nil) { path, tag in
            enumeratedCount += 1
            enumeratedPaths.append(path)
            return true // Continue enumeration
        }

        #expect(enumeratedCount == 3)
    }

    @Test("Enumerate tags stops when block returns false")
    func enumerateTagsStopsEarly() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:title", "Title")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:creator", "Creator")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:subject", "Subject")

        var enumeratedCount = 0

        CGImageMetadataEnumerateTagsUsingBlock(metadata, nil, nil) { path, tag in
            enumeratedCount += 1
            return enumeratedCount < 2 // Stop after 2
        }

        #expect(enumeratedCount == 2)
    }

    @Test("Enumerate empty metadata")
    func enumerateEmptyMetadata() {
        let metadata = CGImageMetadataCreateMutable()

        var enumeratedCount = 0

        CGImageMetadataEnumerateTagsUsingBlock(metadata, nil, nil) { path, tag in
            enumeratedCount += 1
            return true
        }

        #expect(enumeratedCount == 0)
    }

    @Test("Enumeration recursively option key exists")
    func enumerateRecursivelyOptionKeyExists() {
        #expect(!kCGImageMetadataEnumerateRecursively.isEmpty)
    }
}

// MARK: - CGImageMetadata XMP Tests

@Suite("CGImageMetadata XMP Serialization")
struct CGImageMetadataXMPTests {

    @Test("Create XMP data from metadata")
    func createXMPData() {
        let metadata = CGImageMetadataCreateMutable()
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:title", "Test Title")
        CGImageMetadataSetValueWithPath(metadata, nil, "dc:creator", "Test Creator")

        let xmpData = CGImageMetadataCreateXMPData(metadata, nil)

        #expect(xmpData != nil)
        #expect(xmpData!.count > 0)

        // Verify XMP structure
        let xmpString = String(data: xmpData!, encoding: .utf8)
        #expect(xmpString?.contains("xmpmeta") == true)
        #expect(xmpString?.contains("rdf:RDF") == true)
    }

    @Test("Create XMP data from empty metadata")
    func createXMPDataFromEmpty() {
        let metadata = CGImageMetadataCreateMutable()

        let xmpData = CGImageMetadataCreateXMPData(metadata, nil)

        #expect(xmpData != nil)
        // Even empty metadata should produce valid XMP structure
    }

    @Test("XMP roundtrip")
    func xmpRoundtrip() {
        let original = CGImageMetadataCreateMutable()
        let originalValue = "Roundtrip & <Test> \"quoted\""
        CGImageMetadataSetValueWithPath(original, nil, "dc:title", originalValue)

        let xmpData = CGImageMetadataCreateXMPData(original, nil)
        #expect(xmpData != nil)
        let decoded = CGImageMetadataCreateFromXMPData(xmpData!)
        #expect(decoded != nil)
        #expect(CGImageMetadataCopyStringValueWithPath(decoded!, nil, "dc:title") == originalValue)
    }

    @Test("Malformed and non-XMP XML fail instead of producing empty metadata")
    func invalidXMPFails() {
        #expect(CGImageMetadataCreateFromXMPData(Data("plain text".utf8)) == nil)
        #expect(CGImageMetadataCreateFromXMPData(Data("<root/>".utf8)) == nil)
        #expect(CGImageMetadataCreateFromXMPData(Data("<rdf:RDF>".utf8)) == nil)
        #expect(CGImageMetadataCreateFromXMPData(Data("<rdf:RDF>&unknown;</rdf:RDF>".utf8)) == nil)
    }

    @Test("Arrays, structures, selectors, and qualifiers parse from XMP")
    func structuredXMPRoundtrip() throws {
        let source = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:dc="http://purl.org/dc/elements/1.1/"
              xmlns:exif="http://ns.adobe.com/exif/1.0/">
              <dc:subject><rdf:Bag><rdf:li>swift</rdf:li><rdf:li>wasm</rdf:li></rdf:Bag></dc:subject>
              <dc:description><rdf:Alt><rdf:li xml:lang="en-US">Browser image</rdf:li><rdf:li xml:lang="ja-JP">ブラウザ画像</rdf:li></rdf:Alt></dc:description>
              <exif:Flash rdf:parseType="Resource"><exif:Fired>true</exif:Fired></exif:Flash>
            </rdf:Description>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let metadata = try #require(CGImageMetadataCreateFromXMPData(Data(source.utf8)))

        let subject = try #require(CGImageMetadataCopyTagWithPath(metadata, nil, "dc:subject"))
        #expect(CGImageMetadataTagGetType(subject) == .arrayUnordered)
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:subject[1]") == "wasm")
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:description[ja-JP]") == "ブラウザ画像")
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:description[en-US]?xml:lang") == "en-US")
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "exif:Flash.Fired") == "true")

        let japanese = try #require(CGImageMetadataCopyTagWithPath(metadata, nil, "dc:description[ja-JP]"))
        let qualifiers = try #require(CGImageMetadataTagCopyQualifiers(japanese))
        #expect(qualifiers.count == 1)
        #expect(CGImageMetadataTagCopyName(qualifiers[0]) == "lang")

        let encoded = try #require(CGImageMetadataCreateXMPData(metadata, nil))
        let decoded = try #require(CGImageMetadataCreateFromXMPData(encoded))
        #expect(CGImageMetadataCopyStringValueWithPath(decoded, nil, "dc:subject[0]") == "swift")
        #expect(CGImageMetadataCopyStringValueWithPath(decoded, nil, "dc:description[ja-JP]") == "ブラウザ画像")
        #expect(CGImageMetadataCopyStringValueWithPath(decoded, nil, "exif:Flash.Fired") == "true")
    }

    @Test("Structured values update their navigable and serialized children")
    func structuredValueMutation() throws {
        let source = """
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:exif="http://ns.adobe.com/exif/1.0/">
          <rdf:Description>
            <dc:subject><rdf:Bag><rdf:li>old</rdf:li></rdf:Bag></dc:subject>
            <exif:Flash rdf:parseType="Resource"><exif:Fired>true</exif:Fired></exif:Flash>
          </rdf:Description>
        </rdf:RDF>
        """
        let parsed = try #require(CGImageMetadataCreateFromXMPData(Data(source.utf8)))
        let metadata = try #require(CGImageMetadataCreateMutableCopy(parsed))

        #expect(CGImageMetadataSetValueWithPath(metadata, nil, "dc:subject", ["gpu", "browser"]))
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:subject[0]") == "gpu")
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "dc:subject[1]") == "browser")

        #expect(CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "exif:Flash",
            ["exif:Fired": "false", "exif:Mode": "3"]
        ))
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "exif:Flash.Fired") == "false")
        #expect(CGImageMetadataCopyStringValueWithPath(metadata, nil, "exif:Flash.Mode") == "3")
        #expect(!CGImageMetadataSetValueWithPath(metadata, nil, "dc:subject", Data([0x01])))

        let encoded = try #require(CGImageMetadataCreateXMPData(metadata, nil))
        let decoded = try #require(CGImageMetadataCreateFromXMPData(encoded))
        #expect(CGImageMetadataCopyStringValueWithPath(decoded, nil, "dc:subject[1]") == "browser")
        #expect(CGImageMetadataCopyStringValueWithPath(decoded, nil, "exif:Flash.Mode") == "3")
    }

    @Test("Recursive enumeration traverses arrays, qualifiers, and structures")
    func recursiveEnumeration() throws {
        let source = """
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <rdf:Description><dc:description><rdf:Alt><rdf:li xml:lang="en">Text</rdf:li></rdf:Alt></dc:description></rdf:Description>
        </rdf:RDF>
        """
        let metadata = try #require(CGImageMetadataCreateFromXMPData(Data(source.utf8)))
        var paths: [String] = []
        CGImageMetadataEnumerateTagsUsingBlock(
            metadata,
            nil,
            [kCGImageMetadataEnumerateRecursively: true]
        ) { path, _ in
            paths.append(path)
            return true
        }
        #expect(paths.contains("dc:description"))
        #expect(paths.contains("dc:description[en]"))
        #expect(paths.contains("dc:description[en]?xml:lang"))
    }

    @Test("Unsupported tag values fail at the creation boundary")
    func unsupportedValueFailsCreation() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "binary",
            .string,
            Data([0x01, 0x02])
        )
        #expect(tag == nil)

        let nestedTag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "nestedBinary",
            .structure,
            ["payload": Data([0x03, 0x04])]
        )
        #expect(nestedTag == nil)
    }
}

// MARK: - CGImageMetadata Equality Tests

@Suite("CGImageMetadata Equality")
struct CGImageMetadataEqualityTests {

    @Test("Same metadata is equal to itself")
    func sameMetadataEqual() {
        let metadata = CGImageMetadataCreateMutable()

        #expect(metadata == metadata)
    }

    @Test("Different metadata objects are not equal")
    func differentMetadataNotEqual() {
        let metadata1 = CGImageMetadataCreateMutable()
        let metadata2 = CGImageMetadataCreateMutable()

        #expect(metadata1 != metadata2)
    }

    @Test("Metadata can be used as dictionary key")
    func metadataAsDictionaryKey() {
        let metadata = CGImageMetadataCreateMutable()

        var dict: [CGImageMetadata: String] = [:]
        dict[metadata] = "test"

        #expect(dict[metadata] == "test")
    }
}

// MARK: - XMP Namespace Tests

@Suite("XMP Namespaces")
struct XMPNamespaceTests {

    @Test("Dublin Core namespace")
    func dublinCoreNamespace() {
        #expect(kCGImageMetadataNamespaceDublinCore == "http://purl.org/dc/elements/1.1/")
        #expect(kCGImageMetadataPrefixDublinCore == "dc")
    }

    @Test("EXIF namespace")
    func exifNamespace() {
        #expect(kCGImageMetadataNamespaceExif == "http://ns.adobe.com/exif/1.0/")
        #expect(kCGImageMetadataPrefixExif == "exif")
    }

    @Test("EXIF Aux namespace")
    func exifAuxNamespace() {
        #expect(kCGImageMetadataNamespaceExifAux == "http://ns.adobe.com/exif/1.0/aux/")
        #expect(kCGImageMetadataPrefixExifAux == "aux")
    }

    @Test("EXIF EX namespace")
    func exifEXNamespace() {
        #expect(kCGImageMetadataNamespaceExifEX == "http://cipa.jp/exif/1.0/")
        #expect(kCGImageMetadataPrefixExifEX == "exifEX")
    }

    @Test("IPTC Core namespace")
    func iptcCoreNamespace() {
        #expect(kCGImageMetadataNamespaceIPTCCore == "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/")
        #expect(kCGImageMetadataPrefixIPTCCore == "Iptc4xmpCore")
    }

    @Test("IPTC Extension namespace")
    func iptcExtensionNamespace() {
        #expect(kCGImageMetadataNamespaceIPTCExtension == "http://iptc.org/std/Iptc4xmpExt/2008-02-29/")
        #expect(kCGImageMetadataPrefixIPTCExtension == "Iptc4xmpExt")
    }

    @Test("Photoshop namespace")
    func photoshopNamespace() {
        #expect(kCGImageMetadataNamespacePhotoshop == "http://ns.adobe.com/photoshop/1.0/")
        #expect(kCGImageMetadataPrefixPhotoshop == "photoshop")
    }

    @Test("TIFF namespace")
    func tiffNamespace() {
        #expect(kCGImageMetadataNamespaceTIFF == "http://ns.adobe.com/tiff/1.0/")
        #expect(kCGImageMetadataPrefixTIFF == "tiff")
    }

    @Test("XMP Basic namespace")
    func xmpBasicNamespace() {
        #expect(kCGImageMetadataNamespaceXMPBasic == "http://ns.adobe.com/xap/1.0/")
        #expect(kCGImageMetadataPrefixXMPBasic == "xmp")
    }

    @Test("XMP Rights namespace")
    func xmpRightsNamespace() {
        #expect(kCGImageMetadataNamespaceXMPRights == "http://ns.adobe.com/xap/1.0/rights/")
        #expect(kCGImageMetadataPrefixXMPRights == "xmpRights")
    }
}
