// FormatProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Format-specific image properties

@preconcurrency import Foundation

// MARK: - TIFF Image Properties

/// A dictionary of key-value pairs for an image that uses TIFF metadata.
public let kCGImagePropertyTIFFDictionary: String = "{TIFF}"

/// The compression scheme used on the image data.
public let kCGImagePropertyTIFFCompression: String = "Compression"

/// The photometric interpretation of the pixel data.
public let kCGImagePropertyTIFFPhotometricInterpretation: String = "PhotometricInterpretation"

/// A string that describes the subject of the image.
public let kCGImagePropertyTIFFDocumentName: String = "DocumentName"

/// A string that describes the image.
public let kCGImagePropertyTIFFImageDescription: String = "ImageDescription"

/// The manufacturer of the scanner, video digitizer, or other equipment used to create the image.
public let kCGImagePropertyTIFFMake: String = "Make"

/// The model name or model number of the scanner, video digitizer, or other equipment.
public let kCGImagePropertyTIFFModel: String = "Model"

/// The image orientation.
public let kCGImagePropertyTIFFOrientation: String = "Orientation"

/// The number of pixels per resolution unit in the x direction.
public let kCGImagePropertyTIFFXResolution: String = "XResolution"

/// The number of pixels per resolution unit in the y direction.
public let kCGImagePropertyTIFFYResolution: String = "YResolution"

/// The unit of measurement for XResolution and YResolution.
public let kCGImagePropertyTIFFResolutionUnit: String = "ResolutionUnit"

/// The name and version number of the software used to create the image.
public let kCGImagePropertyTIFFSoftware: String = "Software"

/// The transfer function for the image.
public let kCGImagePropertyTIFFTransferFunction: String = "TransferFunction"

/// The date and time when the image was created.
public let kCGImagePropertyTIFFDateTime: String = "DateTime"

/// The name of the document from which this image was scanned.
public let kCGImagePropertyTIFFArtist: String = "Artist"

/// The computer or operating system used to create the image.
public let kCGImagePropertyTIFFHostComputer: String = "HostComputer"

/// The copyright notice.
public let kCGImagePropertyTIFFCopyright: String = "Copyright"

/// The chromaticity of the white point of the image.
public let kCGImagePropertyTIFFWhitePoint: String = "WhitePoint"

/// The chromaticities of the primary colors.
public let kCGImagePropertyTIFFPrimaryChromaticities: String = "PrimaryChromaticities"

/// Tile width.
public let kCGImagePropertyTIFFTileWidth: String = "TileWidth"

/// Tile length.
public let kCGImagePropertyTIFFTileLength: String = "TileLength"

// MARK: - PNG Image Properties

/// A dictionary of key-value pairs for an image that uses PNG metadata.
public let kCGImagePropertyPNGDictionary: String = "{PNG}"

/// The gamma value.
public let kCGImagePropertyPNGGamma: String = "Gamma"

/// The ICC profile name.
public let kCGImagePropertyPNGICCProfileName: String = "ICCProfileName"

/// The intended number of times the animation should be played.
public let kCGImagePropertyPNGLoopCount: String = "LoopCount"

/// The delay time for the frame.
public let kCGImagePropertyPNGDelayTime: String = "DelayTime"

/// The default image width.
public let kCGImagePropertyPNGDefaultImageWidth: String = "DefaultImageWidth"

/// The default image height.
public let kCGImagePropertyPNGDefaultImageHeight: String = "DefaultImageHeight"

/// The width of the canvas.
public let kCGImagePropertyPNGCanvasWidth: String = "CanvasWidth"

/// The height of the canvas.
public let kCGImagePropertyPNGCanvasHeight: String = "CanvasHeight"

/// The x offset of the frame.
public let kCGImagePropertyPNGXOffset: String = "XOffset"

/// The y offset of the frame.
public let kCGImagePropertyPNGYOffset: String = "YOffset"

/// The frame's blend operation.
public let kCGImagePropertyPNGBlendOp: String = "BlendOp"

/// The frame's dispose operation.
public let kCGImagePropertyPNGDisposeOp: String = "DisposeOp"

/// The number of pixels per unit in the x dimension.
public let kCGImagePropertyPNGPixelsPerMeterX: String = "PixelsPerMeterX"

/// The number of pixels per unit in the y dimension.
public let kCGImagePropertyPNGPixelsPerMeterY: String = "PixelsPerMeterY"

/// The intended pixel size or aspect ratio.
public let kCGImagePropertyPNGPixelUnit: String = "PixelUnit"

/// The rendering intent.
public let kCGImagePropertyPNGsRGBIntent: String = "sRGBIntent"

/// The chromaticity of the image.
public let kCGImagePropertyPNGChromaticities: String = "Chromaticities"

/// The image author.
public let kCGImagePropertyPNGAuthor: String = "Author"

/// Copyright information.
public let kCGImagePropertyPNGCopyright: String = "Copyright"

/// The creation time of the image.
public let kCGImagePropertyPNGCreationTime: String = "CreationTime"

/// The image description.
public let kCGImagePropertyPNGDescription: String = "Description"

/// The modification time of the image.
public let kCGImagePropertyPNGModificationTime: String = "ModificationTime"

/// The software used to create the image.
public let kCGImagePropertyPNGSoftware: String = "Software"

/// The image title.
public let kCGImagePropertyPNGTitle: String = "Title"

// MARK: - GIF Image Properties

/// A dictionary of key-value pairs for an image that uses GIF metadata.
public let kCGImagePropertyGIFDictionary: String = "{GIF}"

/// The number of times to loop the animation.
public let kCGImagePropertyGIFLoopCount: String = "LoopCount"

/// The delay time for the frame, in seconds.
public let kCGImagePropertyGIFDelayTime: String = "DelayTime"

/// The unclamped delay time for the frame, in seconds.
public let kCGImagePropertyGIFUnclampedDelayTime: String = "UnclampedDelayTime"

/// Whether the frame has a global color map.
public let kCGImagePropertyGIFHasGlobalColorMap: String = "HasGlobalColorMap"

/// The width of the canvas.
public let kCGImagePropertyGIFCanvasWidth: String = "CanvasWidth"

/// The height of the canvas.
public let kCGImagePropertyGIFCanvasHeight: String = "CanvasHeight"

/// The frame's info dictionary.
public let kCGImagePropertyGIFImageColorMap: String = "ImageColorMap"

// MARK: - JFIF Image Properties

/// A dictionary of key-value pairs for an image that uses JFIF metadata.
public let kCGImagePropertyJFIFDictionary: String = "{JFIF}"

/// The JFIF version.
public let kCGImagePropertyJFIFVersion: String = "JFIFVersion"

/// The horizontal pixel density.
public let kCGImagePropertyJFIFXDensity: String = "XDensity"

/// The vertical pixel density.
public let kCGImagePropertyJFIFYDensity: String = "YDensity"

/// The unit of the density values.
public let kCGImagePropertyJFIFDensityUnit: String = "DensityUnit"

/// Whether the JFIF has a thumbnail.
public let kCGImagePropertyJFIFIsProgressive: String = "IsProgressive"

// MARK: - HEIC Image Properties

/// A dictionary of properties related to an HEIC container.
public let kCGImagePropertyHEICSDictionary: String = "{HEICS}"

/// A dictionary of key-value pairs for an image that uses HEIC metadata.
public let kCGImagePropertyHEICDictionary: String = "{HEIC}"

/// The height of the main image, in pixels.
public let kCGImagePropertyHEICSCanvasPixelHeight: String = "CanvasPixelHeight"

/// The width of the main image, in pixels.
public let kCGImagePropertyHEICSCanvasPixelWidth: String = "CanvasPixelWidth"

// Note: kCGImagePropertyNamedColorSpace is defined in ImageProperties.swift

/// An array of dictionaries that contain timing information for the image sequence.
public let kCGImagePropertyHEICSFrameInfoArray: String = "FrameInfoArray"

/// The number of seconds to wait before displaying the next image in the sequence, clamped to a minimum of 0.1 seconds.
public let kCGImagePropertyHEICSDelayTime: String = "DelayTime"

/// The unclamped number of seconds to wait before displaying the next image in the sequence.
public let kCGImagePropertyHEICSUnclampedDelayTime: String = "UnclampedDelayTime"

/// The number of times to play the sequence.
public let kCGImagePropertyHEICSLoopCount: String = "LoopCount"

/// The canvas width for HEIC images (legacy).
public let kCGImagePropertyHEICSCanvasWidth: String = "CanvasWidth"

/// The canvas height for HEIC images (legacy).
public let kCGImagePropertyHEICSCanvasHeight: String = "CanvasHeight"

// MARK: - WebP Image Properties

/// A dictionary of key-value pairs for an image that uses WebP metadata.
public let kCGImagePropertyWebPDictionary: String = "{WebP}"

/// The loop count for WebP animations.
public let kCGImagePropertyWebPLoopCount: String = "LoopCount"

/// The delay time for WebP animation frames.
public let kCGImagePropertyWebPDelayTime: String = "DelayTime"

/// The unclamped delay time for WebP animation frames.
public let kCGImagePropertyWebPUnclampedDelayTime: String = "UnclampedDelayTime"

/// The canvas width for WebP images.
public let kCGImagePropertyWebPCanvasWidth: String = "CanvasWidth"

/// The canvas height for WebP images.
public let kCGImagePropertyWebPCanvasHeight: String = "CanvasHeight"

/// The frame count for WebP animations.
public let kCGImagePropertyWebPFrameCount: String = "FrameCount"

// MARK: - Raw Image Properties

/// A dictionary of key-value pairs for an image that contains raw data.
public let kCGImagePropertyRawDictionary: String = "{Raw}"

// MARK: - CIFF Image Properties (Canon)

/// A dictionary of key-value pairs for an image that uses Camera Image File Format (CIFF).
public let kCGImagePropertyCIFFDictionary: String = "{CIFF}"

/// The camera description.
public let kCGImagePropertyCIFFDescription: String = "Description"

/// The image name.
public let kCGImagePropertyCIFFImageName: String = "ImageName"

/// The image file name.
public let kCGImagePropertyCIFFImageFileName: String = "ImageFileName"

/// The firmware version.
public let kCGImagePropertyCIFFFirmware: String = "Firmware"

/// The owner name.
public let kCGImagePropertyCIFFOwnerName: String = "OwnerName"

/// The model name.
public let kCGImagePropertyCIFFModelName: String = "ModelName"

/// The release method.
public let kCGImagePropertyCIFFReleaseMethod: String = "ReleaseMethod"

/// The release timing.
public let kCGImagePropertyCIFFReleaseTiming: String = "ReleaseTiming"

/// The record ID.
public let kCGImagePropertyCIFFRecordID: String = "RecordID"

/// The self-timing time.
public let kCGImagePropertyCIFFSelfTimingTime: String = "SelfTimingTime"

/// The camera serial number.
public let kCGImagePropertyCIFFCameraSerialNumber: String = "CameraSerialNumber"

/// The image serial number.
public let kCGImagePropertyCIFFImageSerialNumber: String = "ImageSerialNumber"

/// The continuous drive mode.
public let kCGImagePropertyCIFFContinuousDrive: String = "ContinuousDrive"

/// The focus mode.
public let kCGImagePropertyCIFFFocusMode: String = "FocusMode"

/// The metering mode.
public let kCGImagePropertyCIFFMeteringMode: String = "MeteringMode"

/// The shooting mode.
public let kCGImagePropertyCIFFShootingMode: String = "ShootingMode"

/// The lens model.
public let kCGImagePropertyCIFFLensModel: String = "LensModel"

/// The lens maximum millimeters.
public let kCGImagePropertyCIFFLensMaxMM: String = "LensMaxMM"

/// The lens minimum millimeters.
public let kCGImagePropertyCIFFLensMinMM: String = "LensMinMM"

/// The white balance index.
public let kCGImagePropertyCIFFWhiteBalanceIndex: String = "WhiteBalanceIndex"

/// The flash exposure compensation.
public let kCGImagePropertyCIFFFlashExposureComp: String = "FlashExposureComp"

/// The measured EV.
public let kCGImagePropertyCIFFMeasuredEV: String = "MeasuredEV"

// MARK: - DNG Image Properties

// Dictionary
/// A dictionary of key-value pairs for an image that uses the Digital Negative (DNG) archival format.
public let kCGImagePropertyDNGDictionary: String = "{DNG}"

// Quality
/// The amount of sharpening required for this camera model.
public let kCGImagePropertyDNGBaselineSharpness: String = "BaselineSharpness"

/// The fraction of the encoding range, above which the response may become significantly non-linear.
public let kCGImagePropertyDNGLinearResponseLimit: String = "LinearResponseLimit"

/// A hint to the DNG reader about how much chroma blur to apply to the image.
public let kCGImagePropertyDNGChromaBlurRadius: String = "ChromaBlurRadius"

/// A hint to the DNG reader about how strong the camera's antialias filter is.
public let kCGImagePropertyDNGAntiAliasStrength: String = "AntiAliasStrength"

/// A tag that Adobe Camera Raw uses to control the sensitivity of its Shadows slider.
public let kCGImagePropertyDNGShadowScale: String = "ShadowScale"

/// The scale factor to apply to the default scale to achieve the best quality image size.
public let kCGImagePropertyDNGBestQualityScale: String = "BestQualityScale"

/// The default scale factors for each direction to convert the image to square pixels.
public let kCGImagePropertyDNGDefaultScale: String = "DefaultScale"

/// A lookup table that maps stored values into linear values.
public let kCGImagePropertyDNGLinearizationTable: String = "LinearizationTable"

// Exposure
/// The amount by which to adjust the zero point of the exposure, specified in EV units.
public let kCGImagePropertyDNGBaselineExposure: String = "BaselineExposure"

/// The relative noise level of the camera model at an ISO of 100.
public let kCGImagePropertyDNGBaselineNoise: String = "BaselineNoise"

/// The amount of EV units to add to the baseline exposure during image rendering.
public let kCGImagePropertyDNGBaselineExposureOffset: String = "BaselineExposureOffset"

// Color Balance
/// The analog or digital gain that applies to the stored raw values.
public let kCGImagePropertyDNGAnalogBalance: String = "AnalogBalance"

/// The selected white balance at the time of capture, encoded as the coordinates of a neutral color in linear reference space values.
public let kCGImagePropertyDNGAsShotNeutral: String = "AsShotNeutral"

/// The selected white balance at the time of capture, encoded as x-y chromaticity coordinates.
public let kCGImagePropertyDNGAsShotWhiteXY: String = "AsShotWhiteXY"

/// A value that specifies how closely green pixels in the blue/green rows track the green pixels in red/green rows.
public let kCGImagePropertyDNGBayerGreenSplit: String = "BayerGreenSplit"

/// A matrix that maps white balanced camera colors to XYZ D50 colors.
public let kCGImagePropertyDNGForwardMatrix1: String = "ForwardMatrix1"

/// A matrix that maps white balanced camera colors to XYZ D50 colors.
public let kCGImagePropertyDNGForwardMatrix2: String = "ForwardMatrix2"

/// A hint to the raw converter about how to handle the black point during rendering.
public let kCGImagePropertyDNGDefaultBlackRender: String = "DefaultBlackRender"

// Color Calibration
/// The repeat pattern size for the black level tag.
public let kCGImagePropertyDNGBlackLevelRepeatDim: String = "BlackLevelRepeatDim"

/// The zero light encoding level, specified as a repeating pattern.
public let kCGImagePropertyDNGBlackLevel: String = "BlackLevel"

/// The difference between the zero-light encoding level for each column and the baseline zero-light encoding level.
public let kCGImagePropertyDNGBlackLevelDeltaH: String = "BlackLevelDeltaH"

/// The difference between the zero-light encoding level for each row and the baseline zero-light encoding level.
public let kCGImagePropertyDNGBlackLevelDeltaV: String = "BlackLevelDeltaV"

/// The saturated encoding level for the raw sample values.
public let kCGImagePropertyDNGWhiteLevel: String = "WhiteLevel"

/// The illuminant for the first set of color calibration tags.
public let kCGImagePropertyDNGCalibrationIlluminant1: String = "CalibrationIlluminant1"

/// The illuminant for an optional second set of color calibration tags.
public let kCGImagePropertyDNGCalibrationIlluminant2: String = "CalibrationIlluminant2"

/// A transformation matrix that converts XYZ values to reference camera native color spaces, under the first calibration illuminant.
public let kCGImagePropertyDNGColorMatrix1: String = "ColorMatrix1"

/// A transformation matrix that converts XYZ values to reference camera native color spaces, under the second calibration illuminant.
public let kCGImagePropertyDNGColorMatrix2: String = "ColorMatrix2"

/// A matrix that transforms reference camera native space values to camera-native space values under the first calibration illuminant.
public let kCGImagePropertyDNGCameraCalibration1: String = "CameraCalibration1"

/// A matrix that transforms reference camera native space values to camera-native space values under the second calibration illuminant.
public let kCGImagePropertyDNGCameraCalibration2: String = "CameraCalibration2"

/// A reduction matrix that converts color camera-native space values to XYZ values, under the first calibration illuminant.
public let kCGImagePropertyDNGReductionMatrix1: String = "ReductionMatrix1"

/// A reduction matrix that converts color camera-native space values to XYZ values, under the second calibration illuminant.
public let kCGImagePropertyDNGReductionMatrix2: String = "ReductionMatrix2"

/// A profile that specifies default color rendering from camera color-space coordinates into the ICC profile space.
public let kCGImagePropertyDNGAsShotICCProfile: String = "AsShotICCProfile"

/// A matrix to apply to the camera color-space coordinates before processing values through the ICC profile.
public let kCGImagePropertyDNGAsShotPreProfileMatrix: String = "AsShotPreProfileMatrix"

/// A profile that specifies default color rendering from camera color-space coordinates into the ICC profile space.
public let kCGImagePropertyDNGCurrentICCProfile: String = "CurrentICCProfile"

/// A matrix to apply to the current camera color-space coordinates before processing values through the ICC profile.
public let kCGImagePropertyDNGCurrentPreProfileMatrix: String = "CurrentPreProfileMatrix"

/// The colorimetric reference for the CIE XYZ values.
public let kCGImagePropertyDNGColorimetricReference: String = "ColorimetricReference"

/// A string to match against the profile calibration signature for the selected camera profile.
public let kCGImagePropertyDNGCameraCalibrationSignature: String = "CameraCalibrationSignature"

/// A string that describes the calibration for the current profile.
public let kCGImagePropertyDNGProfileCalibrationSignature: String = "ProfileCalibrationSignature"

// Crop Data
/// The rectangle that defines the non-masked pixels of the sensor.
public let kCGImagePropertyDNGActiveArea: String = "ActiveArea"

/// A list of non-overlapping rectangles that contain fully masked pixels in the image.
public let kCGImagePropertyDNGMaskedAreas: String = "MaskedAreas"

/// The origin of the final image area, relative to the top-left corner of the active area rectangle.
public let kCGImagePropertyDNGDefaultCropOrigin: String = "DefaultCropOrigin"

/// The size of the final image area, in raw image coordinates.
public let kCGImagePropertyDNGDefaultCropSize: String = "DefaultCropSize"

/// A default user-crop rectangle in relative coordinates.
public let kCGImagePropertyDNGDefaultUserCrop: String = "DefaultUserCrop"

// RAW Data
/// The file name of the original raw file.
public let kCGImagePropertyDNGOriginalRawFileName: String = "OriginalRawFileName"

/// The compressed contents of the original raw file.
public let kCGImagePropertyDNGOriginalRawFileData: String = "OriginalRawFileData"

/// The amount of noise reduction applied to the raw data on a scale of 0.0 to 1.0.
public let kCGImagePropertyDNGNoiseReductionApplied: String = "NoiseReductionApplied"

/// An MD5 digest of the raw image data.
public let kCGImagePropertyDNGNewRawImageDigest: String = "NewRawImageDigest"

/// An MD5 digest of the data stored for the original raw file data.
public let kCGImagePropertyDNGOriginalRawFileDigest: String = "OriginalRawFileDigest"

/// A modified MD5 digest of the raw image data.
public let kCGImagePropertyDNGRawImageDigest: String = "RawImageDigest"

/// The default final size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalDefaultFinalSize: String = "OriginalDefaultFinalSize"

/// The best-quality final size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalBestQualityFinalSize: String = "OriginalBestQualityFinalSize"

/// The default crop size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalDefaultCropSize: String = "OriginalDefaultCropSize"

/// The gain between the main raw IFD and the preview IFD that contains this tag.
public let kCGImagePropertyDNGRawToPreviewGain: String = "RawToPreviewGain"

/// The amount of noise in the raw image.
public let kCGImagePropertyDNGNoiseProfile: String = "NoiseProfile"

/// The spatial layout of the CFA.
public let kCGImagePropertyDNGCFALayout: String = "CFALayout"

/// A mapping between the values in the CFA pattern tag and the plane numbers in linear raw space.
public let kCGImagePropertyDNGCFAPlaneColor: String = "CFAPlaneColor"

/// The list of opcodes to apply to the raw image, as read directly from the file.
public let kCGImagePropertyDNGOpcodeList1: String = "OpcodeList1"

/// The list of opcodes to apply to the raw image, after mapping it to linear reference values.
public let kCGImagePropertyDNGOpcodeList2: String = "OpcodeList2"

/// The list of opcodes to apply to the raw image, after demosaicing it.
public let kCGImagePropertyDNGOpcodeList3: String = "OpcodeList3"

/// An opcode to apply a warp to an image to correct for geometric distortion and lateral chromatic aberration for rectilinear lenses.
public let kCGImagePropertyDNGWarpRectilinear: String = "WarpRectilinear"

/// An opcode to unwrap an image captured with a fisheye lens and map it to a perspective projection.
public let kCGImagePropertyDNGWarpFisheye: String = "WarpFisheye"

/// An opcode to apply a gain function to an image to correct vignetting.
public let kCGImagePropertyDNGFixVignetteRadial: String = "FixVignetteRadial"

// Image File Data
/// Private data that manufacturers may store with an image and use in their own converters.
public let kCGImagePropertyDNGPrivateData: String = "PrivateData"

/// A Boolean value that tells the DNG reader whether the EXIF MakerNote tag is safe to preserve.
public let kCGImagePropertyDNGMakerNoteSafety: String = "MakerNoteSafety"

/// A 16-byte unique identifier for the raw image data.
public let kCGImagePropertyDNGRawDataUniqueID: String = "RawDataUniqueID"

/// The size of rectangular blocks that tiles use to group pixels.
public let kCGImagePropertyDNGSubTileBlockSize: String = "SubTileBlockSize"

/// The number of interleaved fields for the rows of the image.
public let kCGImagePropertyDNGRowInterleaveFactor: String = "RowInterleaveFactor"

/// The oldest version for which a file is compatible.
public let kCGImagePropertyDNGBackwardVersion: String = "DNGBackwardVersion"

/// An encoding of the four-tier version number.
public let kCGImagePropertyDNGVersion: String = "DNGVersion"

// Profile Data
/// A list of file offsets to extra camera profiles.
public let kCGImagePropertyDNGExtraCameraProfiles: String = "ExtraCameraProfiles"

/// A string containing the name of the "as shot" camera profile, if any.
public let kCGImagePropertyDNGAsShotProfileName: String = "AsShotProfileName"

/// The number of input samples in each dimension of the hue/saturation/value mapping tables.
public let kCGImagePropertyDNGProfileHueSatMapDims: String = "ProfileHueSatMapDims"

/// The data for the first hue/saturation/value mapping table.
public let kCGImagePropertyDNGProfileHueSatMapData1: String = "ProfileHueSatMapData1"

/// The data for the second hue/saturation/value mapping table.
public let kCGImagePropertyDNGProfileHueSatMapData2: String = "ProfileHueSatMapData2"

/// The encoding option to use when indexing into a 3D look table during raw conversion.
public let kCGImagePropertyDNGProfileHueSatMapEncoding: String = "ProfileHueSatMapEncoding"

/// The default tone curve to apply when processing the image as a starting point for user adjustments.
public let kCGImagePropertyDNGProfileToneCurve: String = "ProfileToneCurve"

/// A string containing the name of the camera profile.
public let kCGImagePropertyDNGProfileName: String = "ProfileName"

/// The usage rules for the camera profile.
public let kCGImagePropertyDNGProfileEmbedPolicy: String = "ProfileEmbedPolicy"

/// The copyright information for the camera profile.
public let kCGImagePropertyDNGProfileCopyright: String = "ProfileCopyright"

/// The number of input samples in each dimension of a default "look" table.
public let kCGImagePropertyDNGProfileLookTableDims: String = "ProfileLookTableDims"

/// The default "look" table to apply when processing the image as a starting point for user adjustment.
public let kCGImagePropertyDNGProfileLookTableData: String = "ProfileLookTableData"

/// The encoding option to use when indexing into a 3D look table during raw conversion.
public let kCGImagePropertyDNGProfileLookTableEncoding: String = "ProfileLookTableEncoding"

// Preview
/// The name of the app that created the preview stored in the IFD.
public let kCGImagePropertyDNGPreviewApplicationName: String = "PreviewApplicationName"

/// The version number of the app that created the preview stored in the IFD.
public let kCGImagePropertyDNGPreviewApplicationVersion: String = "PreviewApplicationVersion"

/// The name of the conversion settings for the preview.
public let kCGImagePropertyDNGPreviewSettingsName: String = "PreviewSettingsName"

/// A unique ID of the conversion settings used to render the preview.
public let kCGImagePropertyDNGPreviewSettingsDigest: String = "PreviewSettingsDigest"

/// The color space associated with the rendered preview.
public let kCGImagePropertyDNGPreviewColorSpace: String = "PreviewColorSpace"

/// The date and time for the render of the preview.
public let kCGImagePropertyDNGPreviewDateTime: String = "PreviewDateTime"

// Camera Details
/// Information about the lens used for the image.
public let kCGImagePropertyDNGLensInfo: String = "LensInfo"

/// A unique, nonlocalized name for the camera model.
public let kCGImagePropertyDNGUniqueCameraModel: String = "UniqueCameraModel"

/// The localized camera model name.
public let kCGImagePropertyDNGLocalizedCameraModel: String = "LocalizedCameraModel"

/// The camera serial number.
public let kCGImagePropertyDNGCameraSerialNumber: String = "CameraSerialNumber"

// MARK: - TGA Image Properties

/// A dictionary of key-value pairs for an image that uses TGA metadata.
public let kCGImagePropertyTGADictionary: String = "{TGA}"

/// The compression type for a TGA image.
public let kCGImagePropertyTGACompression: String = "Compression"

/// Compression types for TGA images.
public enum CGImagePropertyTGACompression: Int32 {
    /// No compression.
    case none = 0
    /// Run-length encoding compression.
    case rle = 1
}

// MARK: - 8BIM Image Properties (Adobe Photoshop)

/// A dictionary of key-value pairs for an image that uses 8BIM metadata.
public let kCGImageProperty8BIMDictionary: String = "{8BIM}"

/// The layer names.
public let kCGImageProperty8BIMLayerNames: String = "LayerNames"

/// The version.
public let kCGImageProperty8BIMVersion: String = "Version"

// MARK: - Manufacturer-Specific Properties

/// A dictionary of key-value pairs for an image from a Nikon camera.
public let kCGImagePropertyMakerNikonDictionary: String = "{MakerNikon}"

/// A dictionary of key-value pairs for an image from a Canon camera.
public let kCGImagePropertyMakerCanonDictionary: String = "{MakerCanon}"

/// A dictionary of key-value pairs for an image from an Apple camera.
public let kCGImagePropertyMakerAppleDictionary: String = "{MakerApple}"

/// A dictionary of key-value pairs for an image from a Minolta camera.
public let kCGImagePropertyMakerMinoltaDictionary: String = "{MakerMinolta}"

/// A dictionary of key-value pairs for an image from a Fuji camera.
public let kCGImagePropertyMakerFujiDictionary: String = "{MakerFuji}"

/// A dictionary of key-value pairs for an image from an Olympus camera.
public let kCGImagePropertyMakerOlympusDictionary: String = "{MakerOlympus}"

/// A dictionary of key-value pairs for an image from a Pentax camera.
public let kCGImagePropertyMakerPentaxDictionary: String = "{MakerPentax}"

// MARK: - Nikon Camera Properties

/// The ISO setting.
public let kCGImagePropertyMakerNikonISOSetting: String = "ISOSetting"

/// The color mode.
public let kCGImagePropertyMakerNikonColorMode: String = "ColorMode"

/// The quality.
public let kCGImagePropertyMakerNikonQuality: String = "Quality"

/// The white balance mode.
public let kCGImagePropertyMakerNikonWhiteBalanceMode: String = "WhiteBalanceMode"

/// The sharpness adjustment.
public let kCGImagePropertyMakerNikonSharpenMode: String = "SharpenMode"

/// The focus mode.
public let kCGImagePropertyMakerNikonFocusMode: String = "FocusMode"

/// The flash setting.
public let kCGImagePropertyMakerNikonFlashSetting: String = "FlashSetting"

/// The ISO selection.
public let kCGImagePropertyMakerNikonISOSelection: String = "ISOSelection"

/// The flash exposure compensation.
public let kCGImagePropertyMakerNikonFlashExposureComp: String = "FlashExposureComp"

/// The image adjustment.
public let kCGImagePropertyMakerNikonImageAdjustment: String = "ImageAdjustment"

/// The lens adapter.
public let kCGImagePropertyMakerNikonLensAdapter: String = "LensAdapter"

/// The lens type.
public let kCGImagePropertyMakerNikonLensType: String = "LensType"

/// The lens info.
public let kCGImagePropertyMakerNikonLensInfo: String = "LensInfo"

/// The focus distance.
public let kCGImagePropertyMakerNikonFocusDistance: String = "FocusDistance"

/// The digital zoom.
public let kCGImagePropertyMakerNikonDigitalZoom: String = "DigitalZoom"

/// The shooting mode.
public let kCGImagePropertyMakerNikonShootingMode: String = "ShootingMode"

/// The camera serial number.
public let kCGImagePropertyMakerNikonCameraSerialNumber: String = "CameraSerialNumber"

/// The shutter count.
public let kCGImagePropertyMakerNikonShutterCount: String = "ShutterCount"

// MARK: - Canon Camera Properties

/// The owner name.
public let kCGImagePropertyMakerCanonOwnerName: String = "OwnerName"

/// The camera serial number.
public let kCGImagePropertyMakerCanonCameraSerialNumber: String = "CameraSerialNumber"

/// The image serial number.
public let kCGImagePropertyMakerCanonImageSerialNumber: String = "ImageSerialNumber"

/// The flash exposure compensation.
public let kCGImagePropertyMakerCanonFlashExposureComp: String = "FlashExposureComp"

/// The continuous drive mode.
public let kCGImagePropertyMakerCanonContinuousDrive: String = "ContinuousDrive"

/// The lens model.
public let kCGImagePropertyMakerCanonLensModel: String = "LensModel"

/// The firmware version.
public let kCGImagePropertyMakerCanonFirmware: String = "Firmware"

/// The aspect ratio information.
public let kCGImagePropertyMakerCanonAspectRatioInfo: String = "AspectRatioInfo"
