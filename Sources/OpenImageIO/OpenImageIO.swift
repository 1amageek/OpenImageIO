// OpenImageIO.swift
// OpenImageIO
//
// A Swift library providing full API compatibility with Apple's ImageIO framework
// for WebAssembly (WASM) environments.
//
// Usage:
// ```swift
// #if canImport(ImageIO)
// import ImageIO
// #else
// import OpenImageIO
// #endif
// ```

// This file serves as the main module entry point.
// All public types and functions are defined in their respective files:
//
// Types:
// - CGImageSource: Read image data from URLs, data objects, or data providers
// - CGImageDestination: Write image data to URLs, data objects, or data consumers
// - CGImageMetadata: Immutable XMP metadata container
// - CGMutableImageMetadata: Mutable XMP metadata container
// - CGImageMetadataTag: Individual metadata tag
//
// Enums:
// - CGImageSourceStatus: Status values for image sources
// - CGImageMetadataType: XMP metadata types
// - CGImageMetadataErrors: Metadata error codes
// - CGImagePropertyOrientation: Image orientation values
// - CGImageAnimationStatus: Animation result codes
//
// Constants:
// - Image source options (kCGImageSource*)
// - Image destination options (kCGImageDestination*)
// - Image properties (kCGImageProperty*)
// - EXIF dictionary keys (kCGImagePropertyExif*)
// - IPTC dictionary keys (kCGImagePropertyIPTC*)
// - GPS dictionary keys (kCGImagePropertyGPS*)
// - TIFF dictionary keys (kCGImagePropertyTIFF*)
// - PNG dictionary keys (kCGImagePropertyPNG*)
// - GIF dictionary keys (kCGImagePropertyGIF*)
// - XMP namespaces and prefixes (kCGImageMetadataNamespace*, kCGImageMetadataPrefix*)
//
// See CLAUDE.md for implementation guidelines and API documentation.
