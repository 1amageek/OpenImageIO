// CoreFoundationTypesTests.swift
// OpenImageIO Tests
//
// Comprehensive tests for CoreFoundation type compatibility

import Testing
@testable import OpenImageIO

// MARK: - CFData Tests

@Suite("CFData")
struct CFDataTests {

    @Test("Create CFData with bytes")
    func createWithBytes() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let data = CFData(bytes: bytes)

        #expect(data.data == bytes)
        #expect(data.length == 4)
    }

    @Test("Create CFData with empty bytes")
    func createWithEmptyBytes() {
        let data = CFData(bytes: [])

        #expect(data.data.isEmpty)
        #expect(data.length == 0)
    }

    @Test("CFData length property")
    func lengthProperty() {
        let data = CFData(bytes: [1, 2, 3, 4, 5])

        #expect(data.length == 5)
    }
}

// MARK: - CFMutableData Tests

@Suite("CFMutableData")
struct CFMutableDataTests {

    @Test("Create CFMutableData with initial bytes")
    func createWithInitialBytes() {
        let bytes: [UInt8] = [0x01, 0x02]
        let data = CFMutableData(bytes: bytes)

        #expect(data.data == bytes)
        #expect(data.length == 2)
    }

    @Test("Create CFMutableData empty")
    func createEmpty() {
        let data = CFMutableData()

        #expect(data.length == 0)
        #expect(data.bytes.isEmpty)
    }

    @Test("Create CFMutableData with capacity")
    func createWithCapacity() {
        let data = CFMutableData(capacity: 100)

        #expect(data.length == 0) // Empty but with capacity
    }

    @Test("Append bytes to CFMutableData")
    func appendBytes() {
        let data = CFMutableData()
        data.append([0x01, 0x02])
        data.append([0x03, 0x04])

        #expect(data.bytes == [0x01, 0x02, 0x03, 0x04])
        #expect(data.length == 4)
    }

    @Test("CFMutableData bytes property")
    func bytesProperty() {
        let data = CFMutableData(bytes: [1, 2, 3])

        #expect(data.bytes == [1, 2, 3])
    }
}

// MARK: - CFURL Tests

@Suite("CFURL")
struct CFURLTests {

    @Test("Create file URL")
    func createFileURL() {
        let url = CFURL(fileURLWithPath: "/path/to/file.png")

        #expect(url.path == "/path/to/file.png")
        #expect(url.isFileURL == true)
    }

    @Test("Create URL from string")
    func createFromString() {
        let url = CFURL(string: "https://example.com/image.jpg")

        #expect(url.path == "https://example.com/image.jpg")
        #expect(url.isFileURL == false)
    }

    @Test("CFURL is equatable")
    func isEquatable() {
        let url1 = CFURL(fileURLWithPath: "/test/path")
        let url2 = CFURL(fileURLWithPath: "/test/path")
        let url3 = CFURL(fileURLWithPath: "/different/path")

        #expect(url1 == url2)
        #expect(url1 != url3)
    }

    @Test("CFURL is hashable")
    func isHashable() {
        let url = CFURL(fileURLWithPath: "/test/path")
        var dict: [CFURL: String] = [:]
        dict[url] = "test"

        #expect(dict[url] == "test")
    }
}

// MARK: - CGImage Tests

@Suite("CGImage")
struct CGImageTests {

    @Test("Create CGImage")
    func createCGImage() {
        let image = CGImage(
            width: 100,
            height: 50,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 400,
            data: [UInt8](repeating: 0, count: 20000)
        )

        #expect(image.width == 100)
        #expect(image.height == 50)
        #expect(image.bitsPerComponent == 8)
        #expect(image.bitsPerPixel == 32)
        #expect(image.bytesPerRow == 400)
    }

    @Test("CGImage is equatable by identity")
    func isEquatableByIdentity() {
        let image1 = CGImage(width: 10, height: 10, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40, data: [])
        let image2 = CGImage(width: 10, height: 10, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40, data: [])

        #expect(image1 == image1) // Same instance
        #expect(image1 != image2) // Different instances
    }

    @Test("CGImage is hashable")
    func isHashable() {
        let image = CGImage(width: 10, height: 10, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40, data: [])
        var dict: [CGImage: String] = [:]
        dict[image] = "test"

        #expect(dict[image] == "test")
    }
}

// MARK: - CGDataProvider Tests

@Suite("CGDataProvider")
struct CGDataProviderTests {

    @Test("Create CGDataProvider with data")
    func createWithData() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]
        let provider = CGDataProvider(data: bytes)

        #expect(provider.data == bytes)
    }

    @Test("CGDataProvider is equatable by identity")
    func isEquatableByIdentity() {
        let provider1 = CGDataProvider(data: [1, 2, 3])
        let provider2 = CGDataProvider(data: [1, 2, 3])

        #expect(provider1 == provider1)
        #expect(provider1 != provider2)
    }

    @Test("CGDataProvider is hashable")
    func isHashable() {
        let provider = CGDataProvider(data: [1, 2, 3])
        var dict: [CGDataProvider: String] = [:]
        dict[provider] = "test"

        #expect(dict[provider] == "test")
    }
}

// MARK: - CGDataConsumer Tests

@Suite("CGDataConsumer")
struct CGDataConsumerTests {

    @Test("Create CGDataConsumer")
    func createConsumer() {
        let consumer = CGDataConsumer()

        #expect(consumer.data.isEmpty)
    }

    @Test("Write to CGDataConsumer")
    func writeToConsumer() {
        let consumer = CGDataConsumer()
        consumer.write([0x01, 0x02])
        consumer.write([0x03, 0x04])

        #expect(consumer.data == [0x01, 0x02, 0x03, 0x04])
    }

    @Test("CGDataConsumer is equatable by identity")
    func isEquatableByIdentity() {
        let consumer1 = CGDataConsumer()
        let consumer2 = CGDataConsumer()

        #expect(consumer1 == consumer1)
        #expect(consumer1 != consumer2)
    }

    @Test("CGDataConsumer is hashable")
    func isHashable() {
        let consumer = CGDataConsumer()
        var dict: [CGDataConsumer: String] = [:]
        dict[consumer] = "test"

        #expect(dict[consumer] == "test")
    }
}

// MARK: - Type Alias Tests

@Suite("Type Aliases")
struct TypeAliasTests {

    @Test("CFTypeID is UInt")
    func cfTypeIDIsUInt() {
        let id: CFTypeID = 42
        #expect(id == 42)
    }

    @Test("CFString is String")
    func cfStringIsString() {
        let str: CFString = "Hello"
        #expect(str == "Hello")
    }

    @Test("CFDictionary is Dictionary")
    func cfDictionaryIsDictionary() {
        let dict: CFDictionary = ["key": "value"]
        #expect(dict["key"] as? String == "value")
    }

    @Test("CFArray is Array")
    func cfArrayIsArray() {
        let arr: CFArray = [1, 2, 3]
        #expect(arr.count == 3)
    }

    @Test("CFIndex is Int")
    func cfIndexIsInt() {
        let idx: CFIndex = 10
        #expect(idx == 10)
    }

    @Test("CGFloat is Double")
    func cgFloatIsDouble() {
        let f: CGFloat = 3.14
        #expect(f == 3.14)
    }

    @Test("OSStatus is Int32")
    func osStatusIsInt32() {
        let status: OSStatus = -1
        #expect(status == -1)
    }

    @Test("noErr constant")
    func noErrConstant() {
        #expect(noErr == 0)
    }
}

// MARK: - Sendable Conformance Tests

@Suite("Sendable Conformance")
struct SendableConformanceTests {

    @Test("CFData is Sendable")
    func cfDataIsSendable() {
        let data = CFData(bytes: [1, 2, 3])
        Task {
            _ = data.length
        }
    }

    @Test("CFMutableData is Sendable")
    func cfMutableDataIsSendable() {
        let data = CFMutableData(bytes: [1, 2, 3])
        Task {
            _ = data.length
        }
    }

    @Test("CFURL is Sendable")
    func cfurlIsSendable() {
        let url = CFURL(fileURLWithPath: "/test")
        Task {
            _ = url.path
        }
    }

    @Test("CGImage is Sendable")
    func cgImageIsSendable() {
        let image = CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4, data: [0, 0, 0, 0])
        Task {
            _ = image.width
        }
    }

    @Test("CGDataProvider is Sendable")
    func cgDataProviderIsSendable() {
        let provider = CGDataProvider(data: [1, 2, 3])
        Task {
            _ = provider.data
        }
    }

    @Test("CGDataConsumer is Sendable")
    func cgDataConsumerIsSendable() {
        let consumer = CGDataConsumer()
        Task {
            _ = consumer.data
        }
    }
}
