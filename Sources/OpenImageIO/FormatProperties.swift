// FormatProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Format-specific image properties

// MARK: - TIFF Image Properties

/// A dictionary of key-value pairs for an image that uses TIFF metadata.
public let kCGImagePropertyTIFFDictionary: CFString = "{TIFF}"

/// The compression scheme used on the image data.
public let kCGImagePropertyTIFFCompression: CFString = "Compression"

/// The photometric interpretation of the pixel data.
public let kCGImagePropertyTIFFPhotometricInterpretation: CFString = "PhotometricInterpretation"

/// A string that describes the subject of the image.
public let kCGImagePropertyTIFFDocumentName: CFString = "DocumentName"

/// A string that describes the image.
public let kCGImagePropertyTIFFImageDescription: CFString = "ImageDescription"

/// The manufacturer of the scanner, video digitizer, or other equipment used to create the image.
public let kCGImagePropertyTIFFMake: CFString = "Make"

/// The model name or model number of the scanner, video digitizer, or other equipment.
public let kCGImagePropertyTIFFModel: CFString = "Model"

/// The image orientation.
public let kCGImagePropertyTIFFOrientation: CFString = "Orientation"

/// The number of pixels per resolution unit in the x direction.
public let kCGImagePropertyTIFFXResolution: CFString = "XResolution"

/// The number of pixels per resolution unit in the y direction.
public let kCGImagePropertyTIFFYResolution: CFString = "YResolution"

/// The unit of measurement for XResolution and YResolution.
public let kCGImagePropertyTIFFResolutionUnit: CFString = "ResolutionUnit"

/// The name and version number of the software used to create the image.
public let kCGImagePropertyTIFFSoftware: CFString = "Software"

/// The transfer function for the image.
public let kCGImagePropertyTIFFTransferFunction: CFString = "TransferFunction"

/// The date and time when the image was created.
public let kCGImagePropertyTIFFDateTime: CFString = "DateTime"

/// The name of the document from which this image was scanned.
public let kCGImagePropertyTIFFArtist: CFString = "Artist"

/// The computer or operating system used to create the image.
public let kCGImagePropertyTIFFHostComputer: CFString = "HostComputer"

/// The copyright notice.
public let kCGImagePropertyTIFFCopyright: CFString = "Copyright"

/// The chromaticity of the white point of the image.
public let kCGImagePropertyTIFFWhitePoint: CFString = "WhitePoint"

/// The chromaticities of the primary colors.
public let kCGImagePropertyTIFFPrimaryChromaticities: CFString = "PrimaryChromaticities"

/// Tile width.
public let kCGImagePropertyTIFFTileWidth: CFString = "TileWidth"

/// Tile length.
public let kCGImagePropertyTIFFTileLength: CFString = "TileLength"

// MARK: - PNG Image Properties

/// A dictionary of key-value pairs for an image that uses PNG metadata.
public let kCGImagePropertyPNGDictionary: CFString = "{PNG}"

/// The gamma value.
public let kCGImagePropertyPNGGamma: CFString = "Gamma"

/// The ICC profile name.
public let kCGImagePropertyPNGICCProfileName: CFString = "ICCProfileName"

/// The intended number of times the animation should be played.
public let kCGImagePropertyPNGLoopCount: CFString = "LoopCount"

/// The delay time for the frame.
public let kCGImagePropertyPNGDelayTime: CFString = "DelayTime"

/// The default image width.
public let kCGImagePropertyPNGDefaultImageWidth: CFString = "DefaultImageWidth"

/// The default image height.
public let kCGImagePropertyPNGDefaultImageHeight: CFString = "DefaultImageHeight"

/// The width of the canvas.
public let kCGImagePropertyPNGCanvasWidth: CFString = "CanvasWidth"

/// The height of the canvas.
public let kCGImagePropertyPNGCanvasHeight: CFString = "CanvasHeight"

/// The x offset of the frame.
public let kCGImagePropertyPNGXOffset: CFString = "XOffset"

/// The y offset of the frame.
public let kCGImagePropertyPNGYOffset: CFString = "YOffset"

/// The frame's blend operation.
public let kCGImagePropertyPNGBlendOp: CFString = "BlendOp"

/// The frame's dispose operation.
public let kCGImagePropertyPNGDisposeOp: CFString = "DisposeOp"

/// The number of pixels per unit in the x dimension.
public let kCGImagePropertyPNGPixelsPerMeterX: CFString = "PixelsPerMeterX"

/// The number of pixels per unit in the y dimension.
public let kCGImagePropertyPNGPixelsPerMeterY: CFString = "PixelsPerMeterY"

/// The intended pixel size or aspect ratio.
public let kCGImagePropertyPNGPixelUnit: CFString = "PixelUnit"

/// The rendering intent.
public let kCGImagePropertyPNGsRGBIntent: CFString = "sRGBIntent"

/// The chromaticity of the image.
public let kCGImagePropertyPNGChromaticities: CFString = "Chromaticities"

/// The image author.
public let kCGImagePropertyPNGAuthor: CFString = "Author"

/// Copyright information.
public let kCGImagePropertyPNGCopyright: CFString = "Copyright"

/// The creation time of the image.
public let kCGImagePropertyPNGCreationTime: CFString = "CreationTime"

/// The image description.
public let kCGImagePropertyPNGDescription: CFString = "Description"

/// The modification time of the image.
public let kCGImagePropertyPNGModificationTime: CFString = "ModificationTime"

/// The software used to create the image.
public let kCGImagePropertyPNGSoftware: CFString = "Software"

/// The image title.
public let kCGImagePropertyPNGTitle: CFString = "Title"

// MARK: - GIF Image Properties

/// A dictionary of key-value pairs for an image that uses GIF metadata.
public let kCGImagePropertyGIFDictionary: CFString = "{GIF}"

/// The number of times to loop the animation.
public let kCGImagePropertyGIFLoopCount: CFString = "LoopCount"

/// The delay time for the frame, in seconds.
public let kCGImagePropertyGIFDelayTime: CFString = "DelayTime"

/// The unclamped delay time for the frame, in seconds.
public let kCGImagePropertyGIFUnclampedDelayTime: CFString = "UnclampedDelayTime"

/// Whether the frame has a global color map.
public let kCGImagePropertyGIFHasGlobalColorMap: CFString = "HasGlobalColorMap"

/// The width of the canvas.
public let kCGImagePropertyGIFCanvasWidth: CFString = "CanvasWidth"

/// The height of the canvas.
public let kCGImagePropertyGIFCanvasHeight: CFString = "CanvasHeight"

/// The frame's info dictionary.
public let kCGImagePropertyGIFImageColorMap: CFString = "ImageColorMap"

// MARK: - JFIF Image Properties

/// A dictionary of key-value pairs for an image that uses JFIF metadata.
public let kCGImagePropertyJFIFDictionary: CFString = "{JFIF}"

/// The JFIF version.
public let kCGImagePropertyJFIFVersion: CFString = "JFIFVersion"

/// The horizontal pixel density.
public let kCGImagePropertyJFIFXDensity: CFString = "XDensity"

/// The vertical pixel density.
public let kCGImagePropertyJFIFYDensity: CFString = "YDensity"

/// The unit of the density values.
public let kCGImagePropertyJFIFDensityUnit: CFString = "DensityUnit"

/// Whether the JFIF has a thumbnail.
public let kCGImagePropertyJFIFIsProgressive: CFString = "IsProgressive"

// MARK: - HEIC Image Properties

/// A dictionary of properties related to an HEIC container.
public let kCGImagePropertyHEICSDictionary: CFString = "{HEICS}"

/// A dictionary of key-value pairs for an image that uses HEIC metadata.
public let kCGImagePropertyHEICDictionary: CFString = "{HEIC}"

/// The height of the main image, in pixels.
public let kCGImagePropertyHEICSCanvasPixelHeight: CFString = "CanvasPixelHeight"

/// The width of the main image, in pixels.
public let kCGImagePropertyHEICSCanvasPixelWidth: CFString = "CanvasPixelWidth"

// Note: kCGImagePropertyNamedColorSpace is defined in ImageProperties.swift

/// An array of dictionaries that contain timing information for the image sequence.
public let kCGImagePropertyHEICSFrameInfoArray: CFString = "FrameInfoArray"

/// The number of seconds to wait before displaying the next image in the sequence, clamped to a minimum of 0.1 seconds.
public let kCGImagePropertyHEICSDelayTime: CFString = "DelayTime"

/// The unclamped number of seconds to wait before displaying the next image in the sequence.
public let kCGImagePropertyHEICSUnclampedDelayTime: CFString = "UnclampedDelayTime"

/// The number of times to play the sequence.
public let kCGImagePropertyHEICSLoopCount: CFString = "LoopCount"

/// The canvas width for HEIC images (legacy).
public let kCGImagePropertyHEICSCanvasWidth: CFString = "CanvasWidth"

/// The canvas height for HEIC images (legacy).
public let kCGImagePropertyHEICSCanvasHeight: CFString = "CanvasHeight"

// MARK: - WebP Image Properties

/// A dictionary of key-value pairs for an image that uses WebP metadata.
public let kCGImagePropertyWebPDictionary: CFString = "{WebP}"

/// The loop count for WebP animations.
public let kCGImagePropertyWebPLoopCount: CFString = "LoopCount"

/// The delay time for WebP animation frames.
public let kCGImagePropertyWebPDelayTime: CFString = "DelayTime"

/// The unclamped delay time for WebP animation frames.
public let kCGImagePropertyWebPUnclampedDelayTime: CFString = "UnclampedDelayTime"

/// The canvas width for WebP images.
public let kCGImagePropertyWebPCanvasWidth: CFString = "CanvasWidth"

/// The canvas height for WebP images.
public let kCGImagePropertyWebPCanvasHeight: CFString = "CanvasHeight"

/// The frame count for WebP animations.
public let kCGImagePropertyWebPFrameCount: CFString = "FrameCount"

// MARK: - Raw Image Properties

/// A dictionary of key-value pairs for an image that contains raw data.
public let kCGImagePropertyRawDictionary: CFString = "{Raw}"

// MARK: - CIFF Image Properties (Canon)

/// A dictionary of key-value pairs for an image that uses Camera Image File Format (CIFF).
public let kCGImagePropertyCIFFDictionary: CFString = "{CIFF}"

/// The camera description.
public let kCGImagePropertyCIFFDescription: CFString = "Description"

/// The image name.
public let kCGImagePropertyCIFFImageName: CFString = "ImageName"

/// The image file name.
public let kCGImagePropertyCIFFImageFileName: CFString = "ImageFileName"

/// The firmware version.
public let kCGImagePropertyCIFFFirmware: CFString = "Firmware"

/// The owner name.
public let kCGImagePropertyCIFFOwnerName: CFString = "OwnerName"

/// The model name.
public let kCGImagePropertyCIFFModelName: CFString = "ModelName"

/// The release method.
public let kCGImagePropertyCIFFReleaseMethod: CFString = "ReleaseMethod"

/// The release timing.
public let kCGImagePropertyCIFFReleaseTiming: CFString = "ReleaseTiming"

/// The record ID.
public let kCGImagePropertyCIFFRecordID: CFString = "RecordID"

/// The self-timing time.
public let kCGImagePropertyCIFFSelfTimingTime: CFString = "SelfTimingTime"

/// The camera serial number.
public let kCGImagePropertyCIFFCameraSerialNumber: CFString = "CameraSerialNumber"

/// The image serial number.
public let kCGImagePropertyCIFFImageSerialNumber: CFString = "ImageSerialNumber"

/// The continuous drive mode.
public let kCGImagePropertyCIFFContinuousDrive: CFString = "ContinuousDrive"

/// The focus mode.
public let kCGImagePropertyCIFFFocusMode: CFString = "FocusMode"

/// The metering mode.
public let kCGImagePropertyCIFFMeteringMode: CFString = "MeteringMode"

/// The shooting mode.
public let kCGImagePropertyCIFFShootingMode: CFString = "ShootingMode"

/// The lens model.
public let kCGImagePropertyCIFFLensModel: CFString = "LensModel"

/// The lens maximum millimeters.
public let kCGImagePropertyCIFFLensMaxMM: CFString = "LensMaxMM"

/// The lens minimum millimeters.
public let kCGImagePropertyCIFFLensMinMM: CFString = "LensMinMM"

/// The white balance index.
public let kCGImagePropertyCIFFWhiteBalanceIndex: CFString = "WhiteBalanceIndex"

/// The flash exposure compensation.
public let kCGImagePropertyCIFFFlashExposureComp: CFString = "FlashExposureComp"

/// The measured EV.
public let kCGImagePropertyCIFFMeasuredEV: CFString = "MeasuredEV"

// MARK: - DNG Image Properties

// Dictionary
/// A dictionary of key-value pairs for an image that uses the Digital Negative (DNG) archival format.
public let kCGImagePropertyDNGDictionary: CFString = "{DNG}"

// Quality
/// The amount of sharpening required for this camera model.
public let kCGImagePropertyDNGBaselineSharpness: CFString = "BaselineSharpness"

/// The fraction of the encoding range, above which the response may become significantly non-linear.
public let kCGImagePropertyDNGLinearResponseLimit: CFString = "LinearResponseLimit"

/// A hint to the DNG reader about how much chroma blur to apply to the image.
public let kCGImagePropertyDNGChromaBlurRadius: CFString = "ChromaBlurRadius"

/// A hint to the DNG reader about how strong the camera's antialias filter is.
public let kCGImagePropertyDNGAntiAliasStrength: CFString = "AntiAliasStrength"

/// A tag that Adobe Camera Raw uses to control the sensitivity of its Shadows slider.
public let kCGImagePropertyDNGShadowScale: CFString = "ShadowScale"

/// The scale factor to apply to the default scale to achieve the best quality image size.
public let kCGImagePropertyDNGBestQualityScale: CFString = "BestQualityScale"

/// The default scale factors for each direction to convert the image to square pixels.
public let kCGImagePropertyDNGDefaultScale: CFString = "DefaultScale"

/// A lookup table that maps stored values into linear values.
public let kCGImagePropertyDNGLinearizationTable: CFString = "LinearizationTable"

// Exposure
/// The amount by which to adjust the zero point of the exposure, specified in EV units.
public let kCGImagePropertyDNGBaselineExposure: CFString = "BaselineExposure"

/// The relative noise level of the camera model at an ISO of 100.
public let kCGImagePropertyDNGBaselineNoise: CFString = "BaselineNoise"

/// The amount of EV units to add to the baseline exposure during image rendering.
public let kCGImagePropertyDNGBaselineExposureOffset: CFString = "BaselineExposureOffset"

// Color Balance
/// The analog or digital gain that applies to the stored raw values.
public let kCGImagePropertyDNGAnalogBalance: CFString = "AnalogBalance"

/// The selected white balance at the time of capture, encoded as the coordinates of a neutral color in linear reference space values.
public let kCGImagePropertyDNGAsShotNeutral: CFString = "AsShotNeutral"

/// The selected white balance at the time of capture, encoded as x-y chromaticity coordinates.
public let kCGImagePropertyDNGAsShotWhiteXY: CFString = "AsShotWhiteXY"

/// A value that specifies how closely green pixels in the blue/green rows track the green pixels in red/green rows.
public let kCGImagePropertyDNGBayerGreenSplit: CFString = "BayerGreenSplit"

/// A matrix that maps white balanced camera colors to XYZ D50 colors.
public let kCGImagePropertyDNGForwardMatrix1: CFString = "ForwardMatrix1"

/// A matrix that maps white balanced camera colors to XYZ D50 colors.
public let kCGImagePropertyDNGForwardMatrix2: CFString = "ForwardMatrix2"

/// A hint to the raw converter about how to handle the black point during rendering.
public let kCGImagePropertyDNGDefaultBlackRender: CFString = "DefaultBlackRender"

// Color Calibration
/// The repeat pattern size for the black level tag.
public let kCGImagePropertyDNGBlackLevelRepeatDim: CFString = "BlackLevelRepeatDim"

/// The zero light encoding level, specified as a repeating pattern.
public let kCGImagePropertyDNGBlackLevel: CFString = "BlackLevel"

/// The difference between the zero-light encoding level for each column and the baseline zero-light encoding level.
public let kCGImagePropertyDNGBlackLevelDeltaH: CFString = "BlackLevelDeltaH"

/// The difference between the zero-light encoding level for each row and the baseline zero-light encoding level.
public let kCGImagePropertyDNGBlackLevelDeltaV: CFString = "BlackLevelDeltaV"

/// The saturated encoding level for the raw sample values.
public let kCGImagePropertyDNGWhiteLevel: CFString = "WhiteLevel"

/// The illuminant for the first set of color calibration tags.
public let kCGImagePropertyDNGCalibrationIlluminant1: CFString = "CalibrationIlluminant1"

/// The illuminant for an optional second set of color calibration tags.
public let kCGImagePropertyDNGCalibrationIlluminant2: CFString = "CalibrationIlluminant2"

/// A transformation matrix that converts XYZ values to reference camera native color spaces, under the first calibration illuminant.
public let kCGImagePropertyDNGColorMatrix1: CFString = "ColorMatrix1"

/// A transformation matrix that converts XYZ values to reference camera native color spaces, under the second calibration illuminant.
public let kCGImagePropertyDNGColorMatrix2: CFString = "ColorMatrix2"

/// A matrix that transforms reference camera native space values to camera-native space values under the first calibration illuminant.
public let kCGImagePropertyDNGCameraCalibration1: CFString = "CameraCalibration1"

/// A matrix that transforms reference camera native space values to camera-native space values under the second calibration illuminant.
public let kCGImagePropertyDNGCameraCalibration2: CFString = "CameraCalibration2"

/// A reduction matrix that converts color camera-native space values to XYZ values, under the first calibration illuminant.
public let kCGImagePropertyDNGReductionMatrix1: CFString = "ReductionMatrix1"

/// A reduction matrix that converts color camera-native space values to XYZ values, under the second calibration illuminant.
public let kCGImagePropertyDNGReductionMatrix2: CFString = "ReductionMatrix2"

/// A profile that specifies default color rendering from camera color-space coordinates into the ICC profile space.
public let kCGImagePropertyDNGAsShotICCProfile: CFString = "AsShotICCProfile"

/// A matrix to apply to the camera color-space coordinates before processing values through the ICC profile.
public let kCGImagePropertyDNGAsShotPreProfileMatrix: CFString = "AsShotPreProfileMatrix"

/// A profile that specifies default color rendering from camera color-space coordinates into the ICC profile space.
public let kCGImagePropertyDNGCurrentICCProfile: CFString = "CurrentICCProfile"

/// A matrix to apply to the current camera color-space coordinates before processing values through the ICC profile.
public let kCGImagePropertyDNGCurrentPreProfileMatrix: CFString = "CurrentPreProfileMatrix"

/// The colorimetric reference for the CIE XYZ values.
public let kCGImagePropertyDNGColorimetricReference: CFString = "ColorimetricReference"

/// A string to match against the profile calibration signature for the selected camera profile.
public let kCGImagePropertyDNGCameraCalibrationSignature: CFString = "CameraCalibrationSignature"

/// A string that describes the calibration for the current profile.
public let kCGImagePropertyDNGProfileCalibrationSignature: CFString = "ProfileCalibrationSignature"

// Crop Data
/// The rectangle that defines the non-masked pixels of the sensor.
public let kCGImagePropertyDNGActiveArea: CFString = "ActiveArea"

/// A list of non-overlapping rectangles that contain fully masked pixels in the image.
public let kCGImagePropertyDNGMaskedAreas: CFString = "MaskedAreas"

/// The origin of the final image area, relative to the top-left corner of the active area rectangle.
public let kCGImagePropertyDNGDefaultCropOrigin: CFString = "DefaultCropOrigin"

/// The size of the final image area, in raw image coordinates.
public let kCGImagePropertyDNGDefaultCropSize: CFString = "DefaultCropSize"

/// A default user-crop rectangle in relative coordinates.
public let kCGImagePropertyDNGDefaultUserCrop: CFString = "DefaultUserCrop"

// RAW Data
/// The file name of the original raw file.
public let kCGImagePropertyDNGOriginalRawFileName: CFString = "OriginalRawFileName"

/// The compressed contents of the original raw file.
public let kCGImagePropertyDNGOriginalRawFileData: CFString = "OriginalRawFileData"

/// The amount of noise reduction applied to the raw data on a scale of 0.0 to 1.0.
public let kCGImagePropertyDNGNoiseReductionApplied: CFString = "NoiseReductionApplied"

/// An MD5 digest of the raw image data.
public let kCGImagePropertyDNGNewRawImageDigest: CFString = "NewRawImageDigest"

/// An MD5 digest of the data stored for the original raw file data.
public let kCGImagePropertyDNGOriginalRawFileDigest: CFString = "OriginalRawFileDigest"

/// A modified MD5 digest of the raw image data.
public let kCGImagePropertyDNGRawImageDigest: CFString = "RawImageDigest"

/// The default final size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalDefaultFinalSize: CFString = "OriginalDefaultFinalSize"

/// The best-quality final size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalBestQualityFinalSize: CFString = "OriginalBestQualityFinalSize"

/// The default crop size of the larger original file that was the source of this proxy.
public let kCGImagePropertyDNGOriginalDefaultCropSize: CFString = "OriginalDefaultCropSize"

/// The gain between the main raw IFD and the preview IFD that contains this tag.
public let kCGImagePropertyDNGRawToPreviewGain: CFString = "RawToPreviewGain"

/// The amount of noise in the raw image.
public let kCGImagePropertyDNGNoiseProfile: CFString = "NoiseProfile"

/// The spatial layout of the CFA.
public let kCGImagePropertyDNGCFALayout: CFString = "CFALayout"

/// A mapping between the values in the CFA pattern tag and the plane numbers in linear raw space.
public let kCGImagePropertyDNGCFAPlaneColor: CFString = "CFAPlaneColor"

/// The list of opcodes to apply to the raw image, as read directly from the file.
public let kCGImagePropertyDNGOpcodeList1: CFString = "OpcodeList1"

/// The list of opcodes to apply to the raw image, after mapping it to linear reference values.
public let kCGImagePropertyDNGOpcodeList2: CFString = "OpcodeList2"

/// The list of opcodes to apply to the raw image, after demosaicing it.
public let kCGImagePropertyDNGOpcodeList3: CFString = "OpcodeList3"

/// An opcode to apply a warp to an image to correct for geometric distortion and lateral chromatic aberration for rectilinear lenses.
public let kCGImagePropertyDNGWarpRectilinear: CFString = "WarpRectilinear"

/// An opcode to unwrap an image captured with a fisheye lens and map it to a perspective projection.
public let kCGImagePropertyDNGWarpFisheye: CFString = "WarpFisheye"

/// An opcode to apply a gain function to an image to correct vignetting.
public let kCGImagePropertyDNGFixVignetteRadial: CFString = "FixVignetteRadial"

// Image File Data
/// Private data that manufacturers may store with an image and use in their own converters.
public let kCGImagePropertyDNGPrivateData: CFString = "PrivateData"

/// A Boolean value that tells the DNG reader whether the EXIF MakerNote tag is safe to preserve.
public let kCGImagePropertyDNGMakerNoteSafety: CFString = "MakerNoteSafety"

/// A 16-byte unique identifier for the raw image data.
public let kCGImagePropertyDNGRawDataUniqueID: CFString = "RawDataUniqueID"

/// The size of rectangular blocks that tiles use to group pixels.
public let kCGImagePropertyDNGSubTileBlockSize: CFString = "SubTileBlockSize"

/// The number of interleaved fields for the rows of the image.
public let kCGImagePropertyDNGRowInterleaveFactor: CFString = "RowInterleaveFactor"

/// The oldest version for which a file is compatible.
public let kCGImagePropertyDNGBackwardVersion: CFString = "DNGBackwardVersion"

/// An encoding of the four-tier version number.
public let kCGImagePropertyDNGVersion: CFString = "DNGVersion"

// Profile Data
/// A list of file offsets to extra camera profiles.
public let kCGImagePropertyDNGExtraCameraProfiles: CFString = "ExtraCameraProfiles"

/// A string containing the name of the "as shot" camera profile, if any.
public let kCGImagePropertyDNGAsShotProfileName: CFString = "AsShotProfileName"

/// The number of input samples in each dimension of the hue/saturation/value mapping tables.
public let kCGImagePropertyDNGProfileHueSatMapDims: CFString = "ProfileHueSatMapDims"

/// The data for the first hue/saturation/value mapping table.
public let kCGImagePropertyDNGProfileHueSatMapData1: CFString = "ProfileHueSatMapData1"

/// The data for the second hue/saturation/value mapping table.
public let kCGImagePropertyDNGProfileHueSatMapData2: CFString = "ProfileHueSatMapData2"

/// The encoding option to use when indexing into a 3D look table during raw conversion.
public let kCGImagePropertyDNGProfileHueSatMapEncoding: CFString = "ProfileHueSatMapEncoding"

/// The default tone curve to apply when processing the image as a starting point for user adjustments.
public let kCGImagePropertyDNGProfileToneCurve: CFString = "ProfileToneCurve"

/// A string containing the name of the camera profile.
public let kCGImagePropertyDNGProfileName: CFString = "ProfileName"

/// The usage rules for the camera profile.
public let kCGImagePropertyDNGProfileEmbedPolicy: CFString = "ProfileEmbedPolicy"

/// The copyright information for the camera profile.
public let kCGImagePropertyDNGProfileCopyright: CFString = "ProfileCopyright"

/// The number of input samples in each dimension of a default "look" table.
public let kCGImagePropertyDNGProfileLookTableDims: CFString = "ProfileLookTableDims"

/// The default "look" table to apply when processing the image as a starting point for user adjustment.
public let kCGImagePropertyDNGProfileLookTableData: CFString = "ProfileLookTableData"

/// The encoding option to use when indexing into a 3D look table during raw conversion.
public let kCGImagePropertyDNGProfileLookTableEncoding: CFString = "ProfileLookTableEncoding"

// Preview
/// The name of the app that created the preview stored in the IFD.
public let kCGImagePropertyDNGPreviewApplicationName: CFString = "PreviewApplicationName"

/// The version number of the app that created the preview stored in the IFD.
public let kCGImagePropertyDNGPreviewApplicationVersion: CFString = "PreviewApplicationVersion"

/// The name of the conversion settings for the preview.
public let kCGImagePropertyDNGPreviewSettingsName: CFString = "PreviewSettingsName"

/// A unique ID of the conversion settings used to render the preview.
public let kCGImagePropertyDNGPreviewSettingsDigest: CFString = "PreviewSettingsDigest"

/// The color space associated with the rendered preview.
public let kCGImagePropertyDNGPreviewColorSpace: CFString = "PreviewColorSpace"

/// The date and time for the render of the preview.
public let kCGImagePropertyDNGPreviewDateTime: CFString = "PreviewDateTime"

// Camera Details
/// Information about the lens used for the image.
public let kCGImagePropertyDNGLensInfo: CFString = "LensInfo"

/// A unique, nonlocalized name for the camera model.
public let kCGImagePropertyDNGUniqueCameraModel: CFString = "UniqueCameraModel"

/// The localized camera model name.
public let kCGImagePropertyDNGLocalizedCameraModel: CFString = "LocalizedCameraModel"

/// The camera serial number.
public let kCGImagePropertyDNGCameraSerialNumber: CFString = "CameraSerialNumber"

// MARK: - TGA Image Properties

/// A dictionary of key-value pairs for an image that uses TGA metadata.
public let kCGImagePropertyTGADictionary: CFString = "{TGA}"

/// The compression type for a TGA image.
public let kCGImagePropertyTGACompression: CFString = "Compression"

/// Compression types for TGA images.
public enum CGImagePropertyTGACompression: Int32 {
    /// No compression.
    case none = 0
    /// Run-length encoding compression.
    case rle = 1
}

// MARK: - 8BIM Image Properties (Adobe Photoshop)

/// A dictionary of key-value pairs for an image that uses 8BIM metadata.
public let kCGImageProperty8BIMDictionary: CFString = "{8BIM}"

/// The layer names.
public let kCGImageProperty8BIMLayerNames: CFString = "LayerNames"

/// The version.
public let kCGImageProperty8BIMVersion: CFString = "Version"

// MARK: - Manufacturer-Specific Properties

/// A dictionary of key-value pairs for an image from a Nikon camera.
public let kCGImagePropertyMakerNikonDictionary: CFString = "{MakerNikon}"

/// A dictionary of key-value pairs for an image from a Canon camera.
public let kCGImagePropertyMakerCanonDictionary: CFString = "{MakerCanon}"

/// A dictionary of key-value pairs for an image from an Apple camera.
public let kCGImagePropertyMakerAppleDictionary: CFString = "{MakerApple}"

/// A dictionary of key-value pairs for an image from a Minolta camera.
public let kCGImagePropertyMakerMinoltaDictionary: CFString = "{MakerMinolta}"

/// A dictionary of key-value pairs for an image from a Fuji camera.
public let kCGImagePropertyMakerFujiDictionary: CFString = "{MakerFuji}"

/// A dictionary of key-value pairs for an image from an Olympus camera.
public let kCGImagePropertyMakerOlympusDictionary: CFString = "{MakerOlympus}"

/// A dictionary of key-value pairs for an image from a Pentax camera.
public let kCGImagePropertyMakerPentaxDictionary: CFString = "{MakerPentax}"

// MARK: - Nikon Camera Properties

/// The ISO setting.
public let kCGImagePropertyMakerNikonISOSetting: CFString = "ISOSetting"

/// The color mode.
public let kCGImagePropertyMakerNikonColorMode: CFString = "ColorMode"

/// The quality.
public let kCGImagePropertyMakerNikonQuality: CFString = "Quality"

/// The white balance mode.
public let kCGImagePropertyMakerNikonWhiteBalanceMode: CFString = "WhiteBalanceMode"

/// The sharpness adjustment.
public let kCGImagePropertyMakerNikonSharpenMode: CFString = "SharpenMode"

/// The focus mode.
public let kCGImagePropertyMakerNikonFocusMode: CFString = "FocusMode"

/// The flash setting.
public let kCGImagePropertyMakerNikonFlashSetting: CFString = "FlashSetting"

/// The ISO selection.
public let kCGImagePropertyMakerNikonISOSelection: CFString = "ISOSelection"

/// The flash exposure compensation.
public let kCGImagePropertyMakerNikonFlashExposureComp: CFString = "FlashExposureComp"

/// The image adjustment.
public let kCGImagePropertyMakerNikonImageAdjustment: CFString = "ImageAdjustment"

/// The lens adapter.
public let kCGImagePropertyMakerNikonLensAdapter: CFString = "LensAdapter"

/// The lens type.
public let kCGImagePropertyMakerNikonLensType: CFString = "LensType"

/// The lens info.
public let kCGImagePropertyMakerNikonLensInfo: CFString = "LensInfo"

/// The focus distance.
public let kCGImagePropertyMakerNikonFocusDistance: CFString = "FocusDistance"

/// The digital zoom.
public let kCGImagePropertyMakerNikonDigitalZoom: CFString = "DigitalZoom"

/// The shooting mode.
public let kCGImagePropertyMakerNikonShootingMode: CFString = "ShootingMode"

/// The camera serial number.
public let kCGImagePropertyMakerNikonCameraSerialNumber: CFString = "CameraSerialNumber"

/// The shutter count.
public let kCGImagePropertyMakerNikonShutterCount: CFString = "ShutterCount"

// MARK: - Canon Camera Properties

/// The owner name.
public let kCGImagePropertyMakerCanonOwnerName: CFString = "OwnerName"

/// The camera serial number.
public let kCGImagePropertyMakerCanonCameraSerialNumber: CFString = "CameraSerialNumber"

/// The image serial number.
public let kCGImagePropertyMakerCanonImageSerialNumber: CFString = "ImageSerialNumber"

/// The flash exposure compensation.
public let kCGImagePropertyMakerCanonFlashExposureComp: CFString = "FlashExposureComp"

/// The continuous drive mode.
public let kCGImagePropertyMakerCanonContinuousDrive: CFString = "ContinuousDrive"

/// The lens model.
public let kCGImagePropertyMakerCanonLensModel: CFString = "LensModel"

/// The firmware version.
public let kCGImagePropertyMakerCanonFirmware: CFString = "Firmware"

/// The aspect ratio information.
public let kCGImagePropertyMakerCanonAspectRatioInfo: CFString = "AspectRatioInfo"
