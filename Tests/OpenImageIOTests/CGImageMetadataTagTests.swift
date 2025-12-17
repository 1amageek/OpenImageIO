// CGImageMetadataTagTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CGImageMetadataTag functionality

import Testing
import Foundation
@testable import OpenImageIO

// MARK: - CGImageMetadataTag Creation Tests

@Suite("CGImageMetadataTag Creation")
struct CGImageMetadataTagCreationTests {

    @Test("Create tag with string value")
    func createWithStringValue() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test Title"
        )

        #expect(tag != nil)
    }

    @Test("Create tag with integer value")
    func createWithIntegerValue() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceExif,
            kCGImageMetadataPrefixExif,
            "ISOSpeedRatings",
            .string,
            100
        )

        #expect(tag != nil)
    }

    @Test("Create tag with array value")
    func createWithArrayValue() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "subject",
            .arrayOrdered,
            ["keyword1", "keyword2", "keyword3"]
        )

        #expect(tag != nil)
        #expect(CGImageMetadataTagGetType(tag!) == .arrayOrdered)
    }

    @Test("Create tag with nil prefix")
    func createWithNilPrefix() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            nil,
            "title",
            .string,
            "Test"
        )

        #expect(tag != nil)
        #expect(CGImageMetadataTagCopyPrefix(tag!) == nil)
    }

    @Test("Create tag with empty name returns nil")
    func createWithEmptyName() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "",
            .string,
            "Test"
        )

        #expect(tag == nil)
    }

    @Test("Create tag with empty namespace returns nil")
    func createWithEmptyNamespace() {
        let tag = CGImageMetadataTagCreate(
            "",
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )

        #expect(tag == nil)
    }

    @Test("Get tag type ID returns consistent value")
    func getTypeID() {
        let typeID1 = CGImageMetadataTagGetTypeID()
        let typeID2 = CGImageMetadataTagGetTypeID()

        // Verify it returns a consistent value
        #expect(typeID1 == typeID2)
        #expect(typeID1 >= 0)
    }
}

// MARK: - CGImageMetadataTag Attribute Tests

@Suite("CGImageMetadataTag Attributes")
struct CGImageMetadataTagAttributeTests {

    @Test("Copy namespace")
    func copyNamespace() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        let namespace = CGImageMetadataTagCopyNamespace(tag)

        #expect(namespace == kCGImageMetadataNamespaceDublinCore)
    }

    @Test("Copy prefix")
    func copyPrefix() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        let prefix = CGImageMetadataTagCopyPrefix(tag)

        #expect(prefix == kCGImageMetadataPrefixDublinCore)
    }

    @Test("Copy name")
    func copyName() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        let name = CGImageMetadataTagCopyName(tag)

        #expect(name == "title")
    }

    @Test("Copy string value")
    func copyStringValue() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "My Title"
        )!

        let value = CGImageMetadataTagCopyValue(tag)

        #expect(value as? String == "My Title")
    }

    @Test("Copy integer value")
    func copyIntegerValue() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceExif,
            kCGImageMetadataPrefixExif,
            "ISOSpeedRatings",
            .string,
            400
        )!

        let value = CGImageMetadataTagCopyValue(tag)

        #expect(value as? Int == 400)
    }

    @Test("Copy array value")
    func copyArrayValue() {
        let keywords = ["nature", "landscape", "sunset"]
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "subject",
            .arrayUnordered,
            keywords
        )!

        let value = CGImageMetadataTagCopyValue(tag)

        #expect(value as? [String] == keywords)
    }

    @Test("Copy qualifiers returns nil for basic tag")
    func copyQualifiersReturnsNil() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        let qualifiers = CGImageMetadataTagCopyQualifiers(tag)

        #expect(qualifiers == nil)
    }
}

// MARK: - CGImageMetadataTag Type Tests

@Suite("CGImageMetadataTag Type")
struct CGImageMetadataTagTypeTests {

    @Test("Get type for string tag")
    func getTypeString() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        #expect(CGImageMetadataTagGetType(tag) == .string)
    }

    @Test("Get type for default tag")
    func getTypeDefault() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .default,
            "Test"
        )!

        #expect(CGImageMetadataTagGetType(tag) == .default)
    }

    @Test("Get type for array unordered tag")
    func getTypeArrayUnordered() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "subject",
            .arrayUnordered,
            ["a", "b"]
        )!

        #expect(CGImageMetadataTagGetType(tag) == .arrayUnordered)
    }

    @Test("Get type for array ordered tag")
    func getTypeArrayOrdered() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "subject",
            .arrayOrdered,
            ["a", "b"]
        )!

        #expect(CGImageMetadataTagGetType(tag) == .arrayOrdered)
    }

    @Test("Get type for alternate array tag")
    func getTypeAlternateArray() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .alternateArray,
            ["en-US: Title", "de-DE: Titel"]
        )!

        #expect(CGImageMetadataTagGetType(tag) == .alternateArray)
    }

    @Test("Get type for alternate text tag")
    func getTypeAlternateText() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .alternateText,
            ["en-US: Title", "fr-FR: Titre"]
        )!

        #expect(CGImageMetadataTagGetType(tag) == .alternateText)
    }

    @Test("Get type for structure tag")
    func getTypeStructure() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceExif,
            kCGImageMetadataPrefixExif,
            "GPSCoordinate",
            .structure,
            ["latitude": 40.7128, "longitude": -74.0060]
        )!

        #expect(CGImageMetadataTagGetType(tag) == .structure)
    }
}

// MARK: - CGImageMetadataTag Different Namespaces Tests

@Suite("CGImageMetadataTag Different Namespaces")
struct CGImageMetadataTagNamespaceTests {

    @Test("Create tag with Dublin Core namespace")
    func createDublinCoreTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "creator",
            .string,
            "John Doe"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceDublinCore)
        #expect(CGImageMetadataTagCopyPrefix(tag) == "dc")
    }

    @Test("Create tag with EXIF namespace")
    func createExifTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceExif,
            kCGImageMetadataPrefixExif,
            "ExposureTime",
            .string,
            "1/125"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceExif)
        #expect(CGImageMetadataTagCopyPrefix(tag) == "exif")
    }

    @Test("Create tag with TIFF namespace")
    func createTiffTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceTIFF,
            kCGImageMetadataPrefixTIFF,
            "Make",
            .string,
            "Canon"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceTIFF)
        #expect(CGImageMetadataTagCopyPrefix(tag) == "tiff")
    }

    @Test("Create tag with XMP Basic namespace")
    func createXmpBasicTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceXMPBasic,
            kCGImageMetadataPrefixXMPBasic,
            "CreateDate",
            .string,
            "2024-01-15T10:30:00"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceXMPBasic)
        #expect(CGImageMetadataTagCopyPrefix(tag) == "xmp")
    }

    @Test("Create tag with IPTC namespace")
    func createIptcTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceIPTCCore,
            kCGImageMetadataPrefixIPTCCore,
            "Location",
            .string,
            "New York City"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceIPTCCore)
    }

    @Test("Create tag with Photoshop namespace")
    func createPhotoshopTag() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespacePhotoshop,
            kCGImageMetadataPrefixPhotoshop,
            "Credit",
            .string,
            "AP Photo"
        )!

        #expect(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespacePhotoshop)
    }
}

// MARK: - CGImageMetadataTag Equality Tests

@Suite("CGImageMetadataTag Equality")
struct CGImageMetadataTagEqualityTests {

    @Test("Same tag is equal to itself")
    func sameTagEqual() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        #expect(tag == tag)
    }

    @Test("Different tags are not equal")
    func differentTagsNotEqual() {
        let tag1 = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        let tag2 = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        #expect(tag1 != tag2) // Different instances
    }

    @Test("Tag can be used as dictionary key")
    func tagAsDictionaryKey() {
        let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            "Test"
        )!

        var dict: [CGImageMetadataTag: String] = [:]
        dict[tag] = "found"

        #expect(dict[tag] == "found")
    }
}
