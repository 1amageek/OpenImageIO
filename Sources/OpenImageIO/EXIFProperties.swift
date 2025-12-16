// EXIFProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Metadata keys for Exchangeable Image File Format (EXIF) data

// MARK: - Dictionaries

/// A dictionary of key-value pairs for an image that uses Exchangeable Image File Format (EXIF).
public let kCGImagePropertyExifDictionary: CFString = "{Exif}"

/// An auxiliary dictionary of key-value pairs for an image that uses Exchangeable Image File Format (EXIF).
public let kCGImagePropertyExifAuxDictionary: CFString = "{ExifAux}"

// MARK: - Camera Settings

/// For a particular camera mode, indicates the conditions for taking the picture.
public let kCGImagePropertyExifDeviceSettingDescription: CFString = "DeviceSettingDescription"

/// The F-number.
public let kCGImagePropertyExifFNumber: CFString = "FNumber"

/// The shutter speed value.
public let kCGImagePropertyExifShutterSpeedValue: CFString = "ShutterSpeedValue"

/// The aperture value.
public let kCGImagePropertyExifApertureValue: CFString = "ApertureValue"

/// The maximum aperture value.
public let kCGImagePropertyExifMaxApertureValue: CFString = "MaxApertureValue"

/// The focal length.
public let kCGImagePropertyExifFocalLength: CFString = "FocalLength"

/// The spectral sensitivity of each channel.
public let kCGImagePropertyExifSpectralSensitivity: CFString = "SpectralSensitivity"

/// The ISO speed ratings.
public let kCGImagePropertyExifISOSpeedRatings: CFString = "ISOSpeedRatings"

/// The distance to the subject, in meters.
public let kCGImagePropertyExifSubjectDistance: CFString = "SubjectDistance"

/// The metering mode.
public let kCGImagePropertyExifMeteringMode: CFString = "MeteringMode"

/// The subject area.
public let kCGImagePropertyExifSubjectArea: CFString = "SubjectArea"

/// The location of the image's primary subject.
public let kCGImagePropertyExifSubjectLocation: CFString = "SubjectLocation"

/// The sensor type of the camera or input device.
public let kCGImagePropertyExifSensingMethod: CFString = "SensingMethod"

/// The scene type.
public let kCGImagePropertyExifSceneType: CFString = "SceneType"

/// The digital zoom ratio.
public let kCGImagePropertyExifDigitalZoomRatio: CFString = "DigitalZoomRatio"

/// The equivalent focal length in 35 mm film.
public let kCGImagePropertyExifFocalLenIn35mmFilm: CFString = "FocalLenIn35mmFilm"

/// The scene capture type; for example, standard, landscape, portrait, or night.
public let kCGImagePropertyExifSceneCaptureType: CFString = "SceneCaptureType"

/// The distance to the subject.
public let kCGImagePropertyExifSubjectDistRange: CFString = "SubjectDistRange"

// MARK: - Exposure

/// The exposure time.
public let kCGImagePropertyExifExposureTime: CFString = "ExposureTime"

/// The exposure program.
public let kCGImagePropertyExifExposureProgram: CFString = "ExposureProgram"

/// The selected exposure index.
public let kCGImagePropertyExifExposureIndex: CFString = "ExposureIndex"

/// The exposure mode setting.
public let kCGImagePropertyExifExposureMode: CFString = "ExposureMode"

/// The ISO speed setting used to capture the image.
public let kCGImagePropertyExifISOSpeed: CFString = "ISOSpeed"

/// The ISO speed latitude yyy value.
public let kCGImagePropertyExifISOSpeedLatitudeyyy: CFString = "ISOSpeedLatitudeyyy"

/// The ISO speed latitude zzz value.
public let kCGImagePropertyExifISOSpeedLatitudezzz: CFString = "ISOSpeedLatitudezzz"

/// The recommended exposure index.
public let kCGImagePropertyExifRecommendedExposureIndex: CFString = "RecommendedExposureIndex"

/// The exposure bias value.
public let kCGImagePropertyExifExposureBiasValue: CFString = "ExposureBiasValue"

/// The type of sensitivity data stored for the image.
public let kCGImagePropertyExifSensitivityType: CFString = "SensitivityType"

/// The sensitivity data for the image.
public let kCGImagePropertyExifStandardOutputSensitivity: CFString = "StandardOutputSensitivity"

/// The exposure times for composite images.
public let kCGImagePropertyExifSourceExposureTimesOfCompositeImage: CFString = "SourceExposureTimesOfCompositeImage"

// MARK: - Image Quality

/// The color filter array (CFA) pattern.
public let kCGImagePropertyExifCFAPattern: CFString = "CFAPattern"

/// The brightness value.
public let kCGImagePropertyExifBrightnessValue: CFString = "BrightnessValue"

/// The light source.
public let kCGImagePropertyExifLightSource: CFString = "LightSource"

/// The flash status when the image was shot.
public let kCGImagePropertyExifFlash: CFString = "Flash"

/// The spatial frequency table and spatial frequency response values.
public let kCGImagePropertyExifSpatialFrequencyResponse: CFString = "SpatialFrequencyResponse"

/// The contrast setting.
public let kCGImagePropertyExifContrast: CFString = "Contrast"

/// The saturation setting.
public let kCGImagePropertyExifSaturation: CFString = "Saturation"

/// The sharpness setting.
public let kCGImagePropertyExifSharpness: CFString = "Sharpness"

/// The gamma setting.
public let kCGImagePropertyExifGamma: CFString = "Gamma"

/// The white balance mode.
public let kCGImagePropertyExifWhiteBalance: CFString = "WhiteBalance"

// MARK: - Image Settings

/// The gain adjustment setting.
public let kCGImagePropertyExifGainControl: CFString = "GainControl"

/// The unique ID of the image.
public let kCGImagePropertyExifImageUniqueID: CFString = "ImageUniqueID"

/// The bits per pixel of the compression mode.
public let kCGImagePropertyExifCompressedBitsPerPixel: CFString = "CompressedBitsPerPixel"

/// The color space.
public let kCGImagePropertyExifColorSpace: CFString = "ColorSpace"

/// The x dimension of a pixel.
public let kCGImagePropertyExifPixelXDimension: CFString = "PixelXDimension"

/// The y dimension of a pixel.
public let kCGImagePropertyExifPixelYDimension: CFString = "PixelYDimension"

/// A sound file related to the image.
public let kCGImagePropertyExifRelatedSoundFile: CFString = "RelatedSoundFile"

/// The number of image-width pixels (x-axis) per focal plane resolution unit.
public let kCGImagePropertyExifFocalPlaneXResolution: CFString = "FocalPlaneXResolution"

/// The number of image-height pixels (y-axis) per focal plane resolution unit.
public let kCGImagePropertyExifFocalPlaneYResolution: CFString = "FocalPlaneYResolution"

/// The unit of measurement for the focal plane x and y resolutions.
public let kCGImagePropertyExifFocalPlaneResolutionUnit: CFString = "FocalPlaneResolutionUnit"

/// Special rendering performed on the image data.
public let kCGImagePropertyExifCustomRendered: CFString = "CustomRendered"

/// Composite image indicator.
public let kCGImagePropertyExifCompositeImage: CFString = "CompositeImage"

/// The opto-electric conversion function (OECF).
public let kCGImagePropertyExifOECF: CFString = "OECF"

/// The components configuration for compressed data.
public let kCGImagePropertyExifComponentsConfiguration: CFString = "ComponentsConfiguration"

/// The number of images that make up a composite image.
public let kCGImagePropertyExifSourceImageNumberOfCompositeImage: CFString = "SourceImageNumberOfCompositeImage"

/// The image source.
public let kCGImagePropertyExifFileSource: CFString = "FileSource"

// MARK: - Timestamp

/// The original date and time.
public let kCGImagePropertyExifDateTimeOriginal: CFString = "DateTimeOriginal"

/// The digitized date and time.
public let kCGImagePropertyExifDateTimeDigitized: CFString = "DateTimeDigitized"

/// The fraction of seconds for the date and time tag.
public let kCGImagePropertyExifSubsecTime: CFString = "SubsecTime"

/// The fraction of seconds for the original date and time tag (deprecated spelling).
@available(*, deprecated, renamed: "kCGImagePropertyExifSubsecTimeOriginal")
public let kCGImagePropertyExifSubsecTimeOrginal: CFString = "SubsecTimeOriginal"

/// The fraction of seconds for the original date and time tag.
public let kCGImagePropertyExifSubsecTimeOriginal: CFString = "SubsecTimeOriginal"

/// The fraction of seconds for the digitized date and time tag.
public let kCGImagePropertyExifSubsecTimeDigitized: CFString = "SubsecTimeDigitized"

/// The offset time.
public let kCGImagePropertyExifOffsetTime: CFString = "OffsetTime"

/// The offset time for the original date and time.
public let kCGImagePropertyExifOffsetTimeOriginal: CFString = "OffsetTimeOriginal"

/// The offset time for the digitized date and time.
public let kCGImagePropertyExifOffsetTimeDigitized: CFString = "OffsetTimeDigitized"

// MARK: - Lens Information

/// The specification information for the camera lens.
public let kCGImagePropertyExifLensSpecification: CFString = "LensSpecification"

/// A string with the name of the lens manufacturer.
public let kCGImagePropertyExifLensMake: CFString = "LensMake"

/// A string with the lens model information.
public let kCGImagePropertyExifLensModel: CFString = "LensModel"

/// A string with the lens's serial number.
public let kCGImagePropertyExifLensSerialNumber: CFString = "LensSerialNumber"

// MARK: - Camera Information

/// Information specified by the camera manufacturer.
public let kCGImagePropertyExifMakerNote: CFString = "MakerNote"

/// A user comment.
public let kCGImagePropertyExifUserComment: CFString = "UserComment"

/// A string with the name of the camera's owner.
public let kCGImagePropertyExifCameraOwnerName: CFString = "CameraOwnerName"

/// A string with the serial number of the camera.
public let kCGImagePropertyExifBodySerialNumber: CFString = "BodySerialNumber"

// MARK: - Flash Information

/// The FlashPix version supported by an FPXR file.
public let kCGImagePropertyExifFlashPixVersion: CFString = "FlashPixVersion"

/// The strobe energy when the image was captured, in beam candle power seconds.
public let kCGImagePropertyExifFlashEnergy: CFString = "FlashEnergy"

// MARK: - Auxiliary Keys

/// Lens information.
public let kCGImagePropertyExifAuxLensInfo: CFString = "LensInfo"

/// The lens model.
public let kCGImagePropertyExifAuxLensModel: CFString = "LensModel"

/// The serial number.
public let kCGImagePropertyExifAuxSerialNumber: CFString = "SerialNumber"

/// The lens ID.
public let kCGImagePropertyExifAuxLensID: CFString = "LensID"

/// The lens serial number.
public let kCGImagePropertyExifAuxLensSerialNumber: CFString = "LensSerialNumber"

/// The image number.
public let kCGImagePropertyExifAuxImageNumber: CFString = "ImageNumber"

/// Flash compensation.
public let kCGImagePropertyExifAuxFlashCompensation: CFString = "FlashCompensation"

/// The owner name.
public let kCGImagePropertyExifAuxOwnerName: CFString = "OwnerName"

/// Firmware information.
public let kCGImagePropertyExifAuxFirmware: CFString = "Firmware"

// MARK: - EXIF Format

/// The EXIF version.
public let kCGImagePropertyExifVersion: CFString = "ExifVersion"
