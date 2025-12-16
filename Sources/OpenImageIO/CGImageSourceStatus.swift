// CGImageSourceStatus.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

/// The set of status values for images and image sources.
public enum CGImageSourceStatus: Int32, Sendable, Hashable, Equatable, RawRepresentable {
    /// The end of the file occurred unexpectedly.
    case statusUnexpectedEOF = -5

    /// The data is not valid.
    case statusInvalidData = -4

    /// The image is an unknown type.
    case statusUnknownType = -3

    /// The image source is reading the header.
    case statusReadingHeader = -2

    /// The operation is not complete.
    case statusIncomplete = -1

    /// The operation is complete.
    case statusComplete = 0

    public init?(rawValue: Int32) {
        switch rawValue {
        case -5: self = .statusUnexpectedEOF
        case -4: self = .statusInvalidData
        case -3: self = .statusUnknownType
        case -2: self = .statusReadingHeader
        case -1: self = .statusIncomplete
        case 0: self = .statusComplete
        default: return nil
        }
    }
}
