// CGImageMetadataTag.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import OpenFoundation
import OpenCoreGraphics

internal indirect enum CGImageMetadataValue: Sendable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case uint(UInt)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)
    case float(Float)
    case double(Double)
    case array([CGImageMetadataValue])
    case dictionary([String: CGImageMetadataValue])
    case unsupported

    internal init(_ value: Any?) {
        switch value {
        case let value as String: self = .string(value)
        case let value as Bool: self = .bool(value)
        case let value as Int: self = .int(value)
        case let value as Int8: self = .int8(value)
        case let value as Int16: self = .int16(value)
        case let value as Int32: self = .int32(value)
        case let value as Int64: self = .int64(value)
        case let value as UInt: self = .uint(value)
        case let value as UInt8: self = .uint8(value)
        case let value as UInt16: self = .uint16(value)
        case let value as UInt32: self = .uint32(value)
        case let value as UInt64: self = .uint64(value)
        case let value as Float: self = .float(value)
        case let value as Double: self = .double(value)
        case let values as [Any]:
            let captured = values.map(Self.init)
            self = captured.contains(where: { !$0.isSupported }) ? .unsupported : .array(captured)
        case let values as [String: Any]:
            let captured = values.mapValues(Self.init)
            self = captured.values.contains(where: { !$0.isSupported })
                ? .unsupported
                : .dictionary(captured)
        default: self = .unsupported
        }
    }

    internal var isSupported: Bool {
        if case .unsupported = self { return false }
        return true
    }

    internal var materialized: Any? {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value
        case .int(let value): return value
        case .int8(let value): return value
        case .int16(let value): return value
        case .int32(let value): return value
        case .int64(let value): return value
        case .uint(let value): return value
        case .uint8(let value): return value
        case .uint16(let value): return value
        case .uint32(let value): return value
        case .uint64(let value): return value
        case .float(let value): return value
        case .double(let value): return value
        case .array(let values): return values.compactMap(\.materialized)
        case .dictionary(let values): return values.compactMapValues(\.materialized)
        case .unsupported: return nil
        }
    }
}

/// An immutable type that contains information about a single piece of image metadata.
public final class CGImageMetadataTag: Hashable, Equatable, Sendable {

    // MARK: - Internal Storage

    internal let namespace: String
    internal let prefix: String?
    internal let name: String
    internal let type: CGImageMetadataType
    internal let storedValue: CGImageMetadataValue
    internal let qualifiers: [CGImageMetadataTag]
    internal let children: [CGImageMetadataTag]

    // MARK: - Initialization

    internal init(
        namespace: String,
        prefix: String?,
        name: String,
        type: CGImageMetadataType,
        value: Any?,
        qualifiers: [CGImageMetadataTag] = [],
        children: [CGImageMetadataTag] = []
    ) {
        self.namespace = namespace
        self.prefix = prefix
        self.name = name
        self.type = type
        self.storedValue = CGImageMetadataValue(value)
        self.qualifiers = qualifiers
        self.children = children
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageMetadataTag, rhs: CGImageMetadataTag) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    internal var value: Any? {
        storedValue.materialized
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
    guard CGImageMetadataValue(value).isSupported else { return nil }

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
    guard !tag.qualifiers.isEmpty else { return nil }
    return tag.qualifiers
}

// MARK: - CGImageMetadataTag Type Functions

/// Returns the type of the metadata tag's value.
public func CGImageMetadataTagGetType(_ tag: CGImageMetadataTag) -> CGImageMetadataType {
    return tag.type
}
