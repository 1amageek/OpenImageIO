// CoreFoundationTypesTests.swift
// OpenImageIO Tests
//
// Tests for OpenCoreGraphics types used in OpenImageIO

import Testing
import Foundation
@testable import OpenImageIO
import OpenCoreGraphics

// MARK: - CGImage Tests

@Suite("CGImage")
struct CGImageTests {

    @Test("Create CGImage with builder")
    func createCGImage() {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            #expect(Bool(false), "Failed to create color space")
            return
        }

        let width = 100
        let height = 50
        let bytesPerRow = width * 4
        let data = [UInt8](repeating: 255, count: bytesPerRow * height)
        let provider = CGDataProvider(data: Data(data))

        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )

        #expect(image != nil)
        #expect(image?.width == 100)
        #expect(image?.height == 50)
    }

    @Test("CGImage is equatable by identity")
    func isEquatableByIdentity() {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return
        }

        let provider1 = CGDataProvider(data: Data([UInt8](repeating: 255, count: 400)))
        let provider2 = CGDataProvider(data: Data([UInt8](repeating: 255, count: 400)))

        let image1 = CGImage(
            width: 10, height: 10,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider1, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
        let image2 = CGImage(
            width: 10, height: 10,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider2, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )

        #expect(image1 == image1) // Same instance
        #expect(image1 != image2) // Different instances
    }

    @Test("CGImage is hashable")
    func isHashable() {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return
        }

        let provider = CGDataProvider(data: Data([UInt8](repeating: 255, count: 400)))
        let image = CGImage(
            width: 10, height: 10,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 40,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )

        guard let img = image else { return }

        var dict: [CGImage: String] = [:]
        dict[img] = "test"

        #expect(dict[img] == "test")
    }
}

// MARK: - CGDataProvider Tests

@Suite("CGDataProvider")
struct CGDataProviderTests {

    @Test("Create CGDataProvider with data")
    func createWithData() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]
        let provider = CGDataProvider(data: Data(bytes))

        #expect(provider.data?.count == 3)
    }

    @Test("CGDataProvider is equatable by identity")
    func isEquatableByIdentity() {
        let provider1 = CGDataProvider(data: Data([1, 2, 3]))
        let provider2 = CGDataProvider(data: Data([1, 2, 3]))

        #expect(provider1 == provider1)
        #expect(provider1 != provider2)
    }

    @Test("CGDataProvider is hashable")
    func isHashable() {
        let provider = CGDataProvider(data: Data([1, 2, 3]))
        var dict: [CGDataProvider: String] = [:]
        dict[provider] = "test"

        #expect(dict[provider] == "test")
    }
}

// MARK: - CGDataConsumer Tests

@Suite("CGDataConsumer")
struct CGDataConsumerTests {

    @Test("Create CGDataConsumer with data")
    func createConsumerWithData() {
        let data = NSMutableData()
        let consumer = CGDataConsumer(data: data as Data)

        #expect(consumer != nil)
    }

    @Test("Write to CGDataConsumer")
    func writeToConsumer() {
        guard let consumer = CGDataConsumer(data: Data()) else {
            #expect(Bool(false), "Failed to create consumer")
            return
        }
        let bytes1: [UInt8] = [0x01, 0x02]
        let bytes2: [UInt8] = [0x03, 0x04]
        bytes1.withUnsafeBytes { buffer in
            _ = consumer.putBytes(buffer.baseAddress, count: buffer.count)
        }
        bytes2.withUnsafeBytes { buffer in
            _ = consumer.putBytes(buffer.baseAddress, count: buffer.count)
        }

        #expect(consumer.data == Data([0x01, 0x02, 0x03, 0x04]))
    }

    @Test("CGDataConsumer is equatable by identity")
    func isEquatableByIdentity() {
        let data1 = NSMutableData()
        let data2 = NSMutableData()
        guard let consumer1 = CGDataConsumer(data: data1 as Data),
              let consumer2 = CGDataConsumer(data: data2 as Data) else {
            #expect(Bool(false), "Failed to create consumers")
            return
        }

        #expect(consumer1 == consumer1)
        #expect(consumer1 != consumer2)
    }

    @Test("CGDataConsumer is hashable")
    func isHashable() {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as Data) else {
            #expect(Bool(false), "Failed to create consumer")
            return
        }
        var dict: [CGDataConsumer: String] = [:]
        dict[consumer] = "test"

        #expect(dict[consumer] == "test")
    }
}

// MARK: - Type Constants Tests

@Suite("Type Constants")
struct TypeConstantsTests {

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
