// CGImageMetadataErrors.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

@preconcurrency import Foundation

/// Constants for errors that occur when getting or setting metadata information.
public enum CGImageMetadataErrors: Int32, Sendable, Hashable, Equatable, RawRepresentable {
    /// An error that indicates an unknown condition occurred.
    case unknown = 0

    /// An error that indicates the metadata was in an unsupported format.
    case unsupportedFormat = 1

    /// An error that indicates a parameter was malformed or contained invalid data.
    case badArgument = 2

    /// An error that indicates an attempt to save conflicting metadata values.
    case conflictingArguments = 3

    /// An error that indicates an attempt to register a namespace with a prefix
    /// that is different than the namespace's existing prefix.
    case prefixConflict = 4

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0: self = .unknown
        case 1: self = .unsupportedFormat
        case 2: self = .badArgument
        case 3: self = .conflictingArguments
        case 4: self = .prefixConflict
        default: return nil
        }
    }
}

/// The domain for metadata-related errors that originate in the Image I/O framework.
public let kCFErrorDomainCGImageMetadata: String = "com.apple.ImageIO.cgimagemetadata"
