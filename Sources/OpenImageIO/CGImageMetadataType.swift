// CGImageMetadataType.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

/// Constants that indicate the XMP type for a metadata tag.
public enum CGImageMetadataType: Int32, Sendable, Hashable, Equatable, RawRepresentable {
    /// An invalid metadata type.
    case invalid = -1

    /// The default type for new tags.
    case `default` = 0

    /// A string value.
    case string = 1

    /// An array that doesn't preserve the order of items.
    case arrayUnordered = 2

    /// An array that preserves the order of items.
    case arrayOrdered = 3

    /// An ordered array, in which all elements are alternates for the same value.
    case alternateArray = 4

    /// An alternate array, in which all elements are localized strings for the same value.
    case alternateText = 5

    /// A collection of keys and values.
    case structure = 6

    public init?(rawValue: Int32) {
        switch rawValue {
        case -1: self = .invalid
        case 0: self = .default
        case 1: self = .string
        case 2: self = .arrayUnordered
        case 3: self = .arrayOrdered
        case 4: self = .alternateArray
        case 5: self = .alternateText
        case 6: self = .structure
        default: return nil
        }
    }
}
