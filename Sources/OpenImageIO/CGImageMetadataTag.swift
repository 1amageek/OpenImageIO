// CGImageMetadataTag.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

@preconcurrency import Foundation
import OpenCoreGraphics

/// An immutable type that contains information about a single piece of image metadata.
public class CGImageMetadataTag: Hashable, Equatable {

    // MARK: - Internal Storage

    internal let namespace: String
    internal let prefix: String?
    internal let name: String
    internal let type: CGImageMetadataType
    internal let value: Any

    // MARK: - Initialization

    internal init(namespace: String, prefix: String?, name: String, type: CGImageMetadataType, value: Any) {
        self.namespace = namespace
        self.prefix = prefix
        self.name = name
        self.type = type
        self.value = value
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageMetadataTag, rhs: CGImageMetadataTag) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CGImageMetadataTag Creation Functions

/// Creates a new image metadata tag, and fills it with the specified information.
public func CGImageMetadataTagCreate(
    _ xmlns: String,
    _ prefix: String?,
    _ name: String,
    _ type: CGImageMetadataType,
    _ value: Any
) -> CGImageMetadataTag? {
    guard !name.isEmpty else { return nil }
    guard !xmlns.isEmpty else { return nil }

    return CGImageMetadataTag(
        namespace: xmlns,
        prefix: prefix,
        name: name,
        type: type,
        value: value
    )
}

// MARK: - CGImageMetadataTag Attribute Functions

/// Returns an immutable copy of the tag's XMP namespace.
public func CGImageMetadataTagCopyNamespace(_ tag: CGImageMetadataTag) -> String? {
    return tag.namespace
}

/// Returns an immutable copy of the tag's prefix.
public func CGImageMetadataTagCopyPrefix(_ tag: CGImageMetadataTag) -> String? {
    return tag.prefix
}

/// Returns an immutable copy of the tag's name.
public func CGImageMetadataTagCopyName(_ tag: CGImageMetadataTag) -> String? {
    return tag.name
}

/// Returns a shallow copy of the tag's value, which is suitable only for reading.
public func CGImageMetadataTagCopyValue(_ tag: CGImageMetadataTag) -> Any? {
    return tag.value
}

/// Returns a shallow copy of the metadata tags that act as qualifiers for the current tag.
public func CGImageMetadataTagCopyQualifiers(_ tag: CGImageMetadataTag) -> [CGImageMetadataTag]? {
    // Qualifiers are nested tags that provide additional information
    // For now, return nil as basic implementation
    return nil
}

// MARK: - CGImageMetadataTag Type Functions

/// Returns the type of the metadata tag's value.
public func CGImageMetadataTagGetType(_ tag: CGImageMetadataTag) -> CGImageMetadataType {
    return tag.type
}
