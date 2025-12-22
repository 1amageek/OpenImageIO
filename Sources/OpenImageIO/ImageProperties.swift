// ImageProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Properties that apply to the container in general, and not necessarily to an individual image in the container.

@preconcurrency import Foundation
import OpenCoreGraphics

// MARK: - Platform Compatibility

#if !canImport(Darwin)
/// A numeric value used to represent error codes.
public typealias OSStatus = Int32

/// No error occurred.
public let noErr: OSStatus = 0
#endif

// MARK: - Dictionary

/// A dictionary of properties related to the image's on-disk file.
public let kCGImagePropertyFileContentsDictionary: String = "FileContents"

// MARK: - Container File Size

/// The size of the image file in bytes, if known.
public let kCGImagePropertyFileSize: String = "FileSize"

// MARK: - Image Information

/// The number of images in the file.
public let kCGImagePropertyImageCount: String = "ImageCount"

/// A Boolean value that indicates whether the image contains indexed pixel samples.
public let kCGImagePropertyIsIndexed: String = "IsIndexed"

/// An array of dictionaries, each of which contains metadata for one of the images in the file.
public let kCGImagePropertyImages: String = "Images"

/// An array of dictionaries containing thumbnail images.
public let kCGImagePropertyThumbnailImages: String = "ThumbnailImages"

/// The index of the primary image in the file.
public let kCGImagePropertyPrimaryImage: String = "PrimaryImage"

/// A Boolean value that indicates whether the image contains floating-point pixel samples.
public let kCGImagePropertyIsFloat: String = "IsFloat"

/// The intended display orientation of the image.
public let kCGImagePropertyOrientation: String = "Orientation"

// MARK: - Pixel Information

/// The format of the image's individual pixels.
public let kCGImagePropertyPixelFormat: String = "PixelFormat"

/// The number of pixels along the x-axis of the image.
public let kCGImagePropertyPixelWidth: String = "PixelWidth"

/// The number of pixels along the y-axis of the image.
public let kCGImagePropertyPixelHeight: String = "PixelHeight"

/// The resolution, in dots per inch, in the y dimension.
public let kCGImagePropertyDPIHeight: String = "DPIHeight"

/// The resolution, in dots per inch, in the x dimension.
public let kCGImagePropertyDPIWidth: String = "DPIWidth"

/// The number of bits in the color sample of a pixel.
public let kCGImagePropertyDepth: String = "Depth"

// MARK: - Color Information

/// A Boolean value that indicates whether the image has an alpha channel.
public let kCGImagePropertyHasAlpha: String = "HasAlpha"

/// The name of the image's color space.
public let kCGImagePropertyNamedColorSpace: String = "NamedColorSpace"

/// The name of the optional International Color Consortium (ICC) profile embedded in the image, if known.
public let kCGImagePropertyProfileName: String = "ProfileName"

/// The color model of the image, such as RGB, CMYK, grayscale, or Lab.
public let kCGImagePropertyColorModel: String = "ColorModel"

/// A Red Green Blue (RGB) color model.
public let kCGImagePropertyColorModelRGB: String = "RGB"

/// A Cyan Magenta Yellow Black (CMYK) color model.
public let kCGImagePropertyColorModelCMYK: String = "CMYK"

/// A grayscale color model.
public let kCGImagePropertyColorModelGray: String = "Gray"

/// A Lab color model, where color values contain the amount of light and the amounts of four human-perceivable colors.
public let kCGImagePropertyColorModelLab: String = "Lab"

// MARK: - Individual Image Properties

/// The height of the image, in the image's coordinate space.
public let kCGImagePropertyHeight: String = "Height"

/// The width of the image, in the image's coordinate space.
public let kCGImagePropertyWidth: String = "Width"

/// The total number of bytes in each row of the image.
public let kCGImagePropertyBytesPerRow: String = "BytesPerRow"

// MARK: - Auxiliary Data Types

/// The type for depth map information.
public let kCGImageAuxiliaryDataTypeDepth: String = "kCGImageAuxiliaryDataTypeDepth"

/// The type for image disparity information.
public let kCGImageAuxiliaryDataTypeDisparity: String = "kCGImageAuxiliaryDataTypeDisparity"

/// The type for High Dynamic Range (HDR) gain map information.
public let kCGImageAuxiliaryDataTypeHDRGainMap: String = "kCGImageAuxiliaryDataTypeHDRGainMap"

/// The type for portrait effects matte information.
public let kCGImageAuxiliaryDataTypePortraitEffectsMatte: String = "kCGImageAuxiliaryDataTypePortraitEffectsMatte"

/// The type for glasses matte information.
public let kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte: String = "kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte"

/// The type for hair matte information.
public let kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte: String = "kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte"

/// The type for skin matte information.
public let kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte: String = "kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte"

/// The type for sky matte information.
public let kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte: String = "kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte"

/// The type for teeth matte information.
public let kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte: String = "kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte"

// MARK: - Auxiliary Image Data

/// An array of dictionaries that contain auxiliary data for the images.
public let kCGImagePropertyAuxiliaryData: String = "AuxiliaryData"

/// The type of the auxiliary data.
public let kCGImagePropertyAuxiliaryDataType: String = "AuxiliaryDataType"

/// The auxiliary data for the image.
public let kCGImageAuxiliaryDataInfoData: String = "kCGImageAuxiliaryDataInfoData"

/// A dictionary of keys that describe the auxiliary data.
public let kCGImageAuxiliaryDataInfoDataDescription: String = "kCGImageAuxiliaryDataInfoDataDescription"

/// The metadata for any auxiliary data.
public let kCGImageAuxiliaryDataInfoMetadata: String = "kCGImageAuxiliaryDataInfoMetadata"

// MARK: - Open EXR Properties

/// A dictionary of properties specific to the OpenEXR metadata standard.
public let kCGImagePropertyOpenEXRDictionary: String = "OpenEXR"

/// The aspect ratio of the image.
public let kCGImagePropertyOpenEXRAspectRatio: String = "AspectRatio"

/// The compression method for OpenEXR images.
public let kCGImagePropertyOpenEXRCompression: String = "Compression"

// MARK: - Animation Properties

/// A property that specifies the index of the first frame of an animation.
public let kCGImageAnimationStartIndex: String = "kCGImageAnimationStartIndex"

/// The number of seconds to wait before displaying the next image in an animated sequence.
public let kCGImageAnimationDelayTime: String = "kCGImageAnimationDelayTime"

/// The number of times to repeat the animated sequence.
public let kCGImageAnimationLoopCount: String = "kCGImageAnimationLoopCount"

// MARK: - Animation Status

/// Constants that indicate the result of animating an image sequence.
public enum CGImageAnimationStatus: Int32, Sendable, Hashable, Equatable, RawRepresentable {
    /// Memory allocation failed.
    case allocationFailure = -22
    /// The input image is corrupt.
    case corruptInputImage = -23
    /// The input image is incomplete.
    case incompleteInputImage = -24
    /// A parameter error occurred.
    case parameterError = -25
    /// The image format is not supported for animation.
    case unsupportedFormat = -26

    public init?(rawValue: Int32) {
        switch rawValue {
        case -22: self = .allocationFailure
        case -23: self = .corruptInputImage
        case -24: self = .incompleteInputImage
        case -25: self = .parameterError
        case -26: self = .unsupportedFormat
        default: return nil
        }
    }
}

// MARK: - Animation Functions

/// The block to execute for each frame of an image animation.
public typealias CGImageSourceAnimationBlock = (Int, CGImage, UnsafeMutablePointer<Bool>) -> Void

/// Animate the sequence of images in the Graphics Interchange Format (GIF) or Animated Portable Network Graphics (APNG) file at the specified URL.
public func CGAnimateImageAtURLWithBlock(
    _ url: URL,
    _ options: [String: Any]?,
    _ block: @escaping CGImageSourceAnimationBlock
) -> OSStatus {
    guard let source = CGImageSourceCreateWithURL(url, options) else {
        return CGImageAnimationStatus.parameterError.rawValue
    }

    let count = CGImageSourceGetCount(source)
    var stop = false

    for index in 0..<count {
        guard !stop else { break }
        if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
            block(index, image, &stop)
        }
    }

    return noErr
}

/// Animate the sequence of images using data from a Graphics Interchange Format (GIF) or Animated Portable Network Graphics (APNG) file.
public func CGAnimateImageDataWithBlock(
    _ data: Data,
    _ options: [String: Any]?,
    _ block: @escaping CGImageSourceAnimationBlock
) -> OSStatus {
    guard let source = CGImageSourceCreateWithData(data, options) else {
        return CGImageAnimationStatus.parameterError.rawValue
    }

    let count = CGImageSourceGetCount(source)
    var stop = false

    for index in 0..<count {
        guard !stop else { break }
        if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
            block(index, image, &stop)
        }
    }

    return noErr
}

// MARK: - HDR Properties

/// Compute HDR statistics.
public let kCGComputeHDRStats: String = "kCGComputeHDRStats"

// MARK: - Image Destination Encoding Properties

/// Encode alternate color space.
public let kCGImageDestinationEncodeAlternateColorSpace: String = "kCGImageDestinationEncodeAlternateColorSpace"

/// Encode base color space.
public let kCGImageDestinationEncodeBaseColorSpace: String = "kCGImageDestinationEncodeBaseColorSpace"

/// Encode base is SDR.
public let kCGImageDestinationEncodeBaseIsSDR: String = "kCGImageDestinationEncodeBaseIsSDR"

/// Encode base pixel format request.
public let kCGImageDestinationEncodeBasePixelFormatRequest: String = "kCGImageDestinationEncodeBasePixelFormatRequest"

/// Encode gain map pixel format request.
public let kCGImageDestinationEncodeGainMapPixelFormatRequest: String = "kCGImageDestinationEncodeGainMapPixelFormatRequest"

/// Encode gain map subsample factor.
public let kCGImageDestinationEncodeGainMapSubsampleFactor: String = "kCGImageDestinationEncodeGainMapSubsampleFactor"

/// Encode generate gain map with base image.
public let kCGImageDestinationEncodeGenerateGainMapWithBaseImage: String = "kCGImageDestinationEncodeGenerateGainMapWithBaseImage"

/// Encode is base image.
public let kCGImageDestinationEncodeIsBaseImage: String = "kCGImageDestinationEncodeIsBaseImage"

/// Encode request.
public let kCGImageDestinationEncodeRequest: String = "kCGImageDestinationEncodeRequest"

/// Encode request options.
public let kCGImageDestinationEncodeRequestOptions: String = "kCGImageDestinationEncodeRequestOptions"

/// Encode to ISO gain map.
public let kCGImageDestinationEncodeToISOGainmap: String = "kCGImageDestinationEncodeToISOGainmap"

/// Encode to ISO HDR.
public let kCGImageDestinationEncodeToISOHDR: String = "kCGImageDestinationEncodeToISOHDR"

/// Encode to SDR.
public let kCGImageDestinationEncodeToSDR: String = "kCGImageDestinationEncodeToSDR"

/// Encode tonemap mode.
public let kCGImageDestinationEncodeTonemapMode: String = "kCGImageDestinationEncodeTonemapMode"

// MARK: - Texture Properties

/// ASTC block size.
public let kCGImagePropertyASTCBlockSize: String = "kCGImagePropertyASTCBlockSize"

/// ASTC block size 4x4.
public let kCGImagePropertyASTCBlockSize4x4: String = "kCGImagePropertyASTCBlockSize4x4"

/// ASTC block size 8x8.
public let kCGImagePropertyASTCBlockSize8x8: String = "kCGImagePropertyASTCBlockSize8x8"

/// ASTC encoder.
public let kCGImagePropertyASTCEncoder: String = "kCGImagePropertyASTCEncoder"

/// BC encoder.
public let kCGImagePropertyBCEncoder: String = "kCGImagePropertyBCEncoder"

/// BC format.
public let kCGImagePropertyBCFormat: String = "kCGImagePropertyBCFormat"

/// Encoder.
public let kCGImagePropertyEncoder: String = "kCGImagePropertyEncoder"

/// PVR encoder.
public let kCGImagePropertyPVREncoder: String = "kCGImagePropertyPVREncoder"

// MARK: - Image Provider Properties

/// Preferred tile height.
public let kCGImageProviderPreferredTileHeight: String = "kCGImageProviderPreferredTileHeight"

/// Preferred tile width.
public let kCGImageProviderPreferredTileWidth: String = "kCGImageProviderPreferredTileWidth"
