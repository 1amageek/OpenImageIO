// CoreFoundationTypes.swift
// OpenImageIO
//
// Type definitions for CoreFoundation compatibility in WASM environments
// These types provide API compatibility with Apple's CoreFoundation types
// for use in environments where CoreFoundation is not available.

import Foundation

/// A type for unique identifiers.
public typealias CFTypeID = UInt

/// An abstract type for Core Foundation data objects.
public final class CFData: @unchecked Sendable {
    public let data: [UInt8]

    public init(bytes: [UInt8]) {
        self.data = bytes
    }

    public var length: Int {
        return data.count
    }
}

/// A mutable data object.
public final class CFMutableData: @unchecked Sendable {
    private var mutableData: [UInt8]

    public init(bytes: [UInt8] = []) {
        self.mutableData = bytes
    }

    public init(capacity: Int) {
        self.mutableData = []
        self.mutableData.reserveCapacity(capacity)
    }

    public func append(_ bytes: [UInt8]) {
        mutableData.append(contentsOf: bytes)
    }

    public var length: Int {
        return mutableData.count
    }

    public var bytes: [UInt8] {
        return mutableData
    }

    public var data: [UInt8] {
        return mutableData
    }
}

/// A string type for CoreFoundation compatibility.
public typealias CFString = String

/// A URL type for CoreFoundation compatibility.
public struct CFURL: Hashable, Equatable, Sendable {
    public let path: String
    public let isFileURL: Bool

    public init(fileURLWithPath path: String) {
        self.path = path
        self.isFileURL = true
    }

    public init(string: String) {
        self.path = string
        self.isFileURL = false
    }
}

/// A dictionary type for CoreFoundation compatibility.
public typealias CFDictionary = [String: Any]

/// An array type for CoreFoundation compatibility.
public typealias CFArray = [Any]

/// An index type for CoreFoundation compatibility.
public typealias CFIndex = Int

/// A type for Core Graphics floating-point values.
public typealias CGFloat = Double

/// Placeholder for CGImage - should be provided by OpenCoreGraphics in production.
public final class CGImage: Hashable, Equatable, @unchecked Sendable {
    public let width: Int
    public let height: Int
    public let bitsPerComponent: Int
    public let bitsPerPixel: Int
    public let bytesPerRow: Int
    public let data: [UInt8]

    public init(width: Int, height: Int, bitsPerComponent: Int, bitsPerPixel: Int, bytesPerRow: Int, data: [UInt8]) {
        self.width = width
        self.height = height
        self.bitsPerComponent = bitsPerComponent
        self.bitsPerPixel = bitsPerPixel
        self.bytesPerRow = bytesPerRow
        self.data = data
    }

    public static func == (lhs: CGImage, rhs: CGImage) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Placeholder for CGDataProvider - should be provided by OpenCoreGraphics in production.
public final class CGDataProvider: Hashable, Equatable, @unchecked Sendable {
    public let data: [UInt8]

    public init(data: [UInt8]) {
        self.data = data
    }

    public static func == (lhs: CGDataProvider, rhs: CGDataProvider) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Placeholder for CGDataConsumer - should be provided by OpenCoreGraphics in production.
public final class CGDataConsumer: Hashable, Equatable, @unchecked Sendable {
    public var data: [UInt8] = []

    public init() {}

    public func write(_ bytes: [UInt8]) {
        data.append(contentsOf: bytes)
    }

    public static func == (lhs: CGDataConsumer, rhs: CGDataConsumer) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Placeholder for CFError - using Foundation's NSError.
public typealias CFError = NSError

/// A type for status codes returned by many framework functions.
public typealias OSStatus = Int32

/// The constant for a successful status.
public let noErr: OSStatus = 0
