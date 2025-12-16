// CGImagePropertyOrientation.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

/// A value describing the intended display orientation for an image.
@frozen public enum CGImagePropertyOrientation: UInt32, Sendable, Hashable, Equatable, RawRepresentable {
    /// The encoded image data matches the image's intended display orientation.
    case up = 1

    /// The encoded image data is horizontally flipped from the image's intended display orientation.
    case upMirrored = 2

    /// The encoded image data is rotated 180° from the image's intended display orientation.
    case down = 3

    /// The encoded image data is vertically flipped from the image's intended display orientation.
    case downMirrored = 4

    /// The encoded image data is horizontally flipped and rotated 90° counter-clockwise
    /// from the image's intended display orientation.
    case leftMirrored = 5

    /// The encoded image data is rotated 90° clockwise from the image's intended display orientation.
    case right = 6

    /// The encoded image data is horizontally flipped and rotated 90° clockwise
    /// from the image's intended display orientation.
    case rightMirrored = 7

    /// The encoded image data is rotated 90° counter-clockwise from the image's intended display orientation.
    case left = 8

    public init?(rawValue: UInt32) {
        switch rawValue {
        case 1: self = .up
        case 2: self = .upMirrored
        case 3: self = .down
        case 4: self = .downMirrored
        case 5: self = .leftMirrored
        case 6: self = .right
        case 7: self = .rightMirrored
        case 8: self = .left
        default: return nil
        }
    }
}
