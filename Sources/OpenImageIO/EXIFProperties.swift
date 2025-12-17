// EXIFProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Metadata keys for Exchangeable Image File Format (EXIF) data

@preconcurrency import Foundation

// MARK: - Dictionaries

/// A dictionary of key-value pairs for an image that uses Exchangeable Image File Format (EXIF).
public let kCGImagePropertyExifDictionary: String = "{Exif}"

/// An auxiliary dictionary of key-value pairs for an image that uses Exchangeable Image File Format (EXIF).
public let kCGImagePropertyExifAuxDictionary: String = "{ExifAux}"

// MARK: - Camera Settings

/// For a particular camera mode, indicates the conditions for taking the picture.
public let kCGImagePropertyExifDeviceSettingDescription: String = "DeviceSettingDescription"

/// The F-number.
public let kCGImagePropertyExifFNumber: String = "FNumber"

/// The shutter speed value.
public let kCGImagePropertyExifShutterSpeedValue: String = "ShutterSpeedValue"

/// The aperture value.
public let kCGImagePropertyExifApertureValue: String = "ApertureValue"

/// The maximum aperture value.
public let kCGImagePropertyExifMaxApertureValue: String = "MaxApertureValue"

/// The focal length.
public let kCGImagePropertyExifFocalLength: String = "FocalLength"

/// The spectral sensitivity of each channel.
public let kCGImagePropertyExifSpectralSensitivity: String = "SpectralSensitivity"

/// The ISO speed ratings.
public let kCGImagePropertyExifISOSpeedRatings: String = "ISOSpeedRatings"

/// The distance to the subject, in meters.
public let kCGImagePropertyExifSubjectDistance: String = "SubjectDistance"

/// The metering mode.
public let kCGImagePropertyExifMeteringMode: String = "MeteringMode"

/// The subject area.
public let kCGImagePropertyExifSubjectArea: String = "SubjectArea"

/// The location of the image's primary subject.
public let kCGImagePropertyExifSubjectLocation: String = "SubjectLocation"

/// The sensor type of the camera or input device.
public let kCGImagePropertyExifSensingMethod: String = "SensingMethod"

/// The scene type.
public let kCGImagePropertyExifSceneType: String = "SceneType"

/// The digital zoom ratio.
public let kCGImagePropertyExifDigitalZoomRatio: String = "DigitalZoomRatio"

/// The equivalent focal length in 35 mm film.
public let kCGImagePropertyExifFocalLenIn35mmFilm: String = "FocalLenIn35mmFilm"

/// The scene capture type; for example, standard, landscape, portrait, or night.
public let kCGImagePropertyExifSceneCaptureType: String = "SceneCaptureType"

/// The distance to the subject.
public let kCGImagePropertyExifSubjectDistRange: String = "SubjectDistRange"

// MARK: - Exposure

/// The exposure time.
public let kCGImagePropertyExifExposureTime: String = "ExposureTime"

/// The exposure program.
public let kCGImagePropertyExifExposureProgram: String = "ExposureProgram"

/// The selected exposure index.
public let kCGImagePropertyExifExposureIndex: String = "ExposureIndex"

/// The exposure mode setting.
public let kCGImagePropertyExifExposureMode: String = "ExposureMode"

/// The ISO speed setting used to capture the image.
public let kCGImagePropertyExifISOSpeed: String = "ISOSpeed"

/// The ISO speed latitude yyy value.
public let kCGImagePropertyExifISOSpeedLatitudeyyy: String = "ISOSpeedLatitudeyyy"

/// The ISO speed latitude zzz value.
public let kCGImagePropertyExifISOSpeedLatitudezzz: String = "ISOSpeedLatitudezzz"

/// The recommended exposure index.
public let kCGImagePropertyExifRecommendedExposureIndex: String = "RecommendedExposureIndex"

/// The exposure bias value.
public let kCGImagePropertyExifExposureBiasValue: String = "ExposureBiasValue"

/// The type of sensitivity data stored for the image.
public let kCGImagePropertyExifSensitivityType: String = "SensitivityType"

/// The sensitivity data for the image.
public let kCGImagePropertyExifStandardOutputSensitivity: String = "StandardOutputSensitivity"

/// The exposure times for composite images.
public let kCGImagePropertyExifSourceExposureTimesOfCompositeImage: String = "SourceExposureTimesOfCompositeImage"

// MARK: - Image Quality

/// The color filter array (CFA) pattern.
public let kCGImagePropertyExifCFAPattern: String = "CFAPattern"

/// The brightness value.
public let kCGImagePropertyExifBrightnessValue: String = "BrightnessValue"

/// The light source.
public let kCGImagePropertyExifLightSource: String = "LightSource"

/// The flash status when the image was shot.
public let kCGImagePropertyExifFlash: String = "Flash"

/// The spatial frequency table and spatial frequency response values.
public let kCGImagePropertyExifSpatialFrequencyResponse: String = "SpatialFrequencyResponse"

/// The contrast setting.
public let kCGImagePropertyExifContrast: String = "Contrast"

/// The saturation setting.
public let kCGImagePropertyExifSaturation: String = "Saturation"

/// The sharpness setting.
public let kCGImagePropertyExifSharpness: String = "Sharpness"

/// The gamma setting.
public let kCGImagePropertyExifGamma: String = "Gamma"

/// The white balance mode.
public let kCGImagePropertyExifWhiteBalance: String = "WhiteBalance"

// MARK: - Image Settings

/// The gain adjustment setting.
public let kCGImagePropertyExifGainControl: String = "GainControl"

/// The unique ID of the image.
public let kCGImagePropertyExifImageUniqueID: String = "ImageUniqueID"

/// The bits per pixel of the compression mode.
public let kCGImagePropertyExifCompressedBitsPerPixel: String = "CompressedBitsPerPixel"

/// The color space.
public let kCGImagePropertyExifColorSpace: String = "ColorSpace"

/// The x dimension of a pixel.
public let kCGImagePropertyExifPixelXDimension: String = "PixelXDimension"

/// The y dimension of a pixel.
public let kCGImagePropertyExifPixelYDimension: String = "PixelYDimension"

/// A sound file related to the image.
public let kCGImagePropertyExifRelatedSoundFile: String = "RelatedSoundFile"

/// The number of image-width pixels (x-axis) per focal plane resolution unit.
public let kCGImagePropertyExifFocalPlaneXResolution: String = "FocalPlaneXResolution"

/// The number of image-height pixels (y-axis) per focal plane resolution unit.
public let kCGImagePropertyExifFocalPlaneYResolution: String = "FocalPlaneYResolution"

/// The unit of measurement for the focal plane x and y resolutions.
public let kCGImagePropertyExifFocalPlaneResolutionUnit: String = "FocalPlaneResolutionUnit"

/// Special rendering performed on the image data.
public let kCGImagePropertyExifCustomRendered: String = "CustomRendered"

/// Composite image indicator.
public let kCGImagePropertyExifCompositeImage: String = "CompositeImage"

/// The opto-electric conversion function (OECF).
public let kCGImagePropertyExifOECF: String = "OECF"

/// The components configuration for compressed data.
public let kCGImagePropertyExifComponentsConfiguration: String = "ComponentsConfiguration"

/// The number of images that make up a composite image.
public let kCGImagePropertyExifSourceImageNumberOfCompositeImage: String = "SourceImageNumberOfCompositeImage"

/// The image source.
public let kCGImagePropertyExifFileSource: String = "FileSource"

// MARK: - Timestamp

/// The original date and time.
public let kCGImagePropertyExifDateTimeOriginal: String = "DateTimeOriginal"

/// The digitized date and time.
public let kCGImagePropertyExifDateTimeDigitized: String = "DateTimeDigitized"

/// The fraction of seconds for the date and time tag.
public let kCGImagePropertyExifSubsecTime: String = "SubsecTime"

/// The fraction of seconds for the original date and time tag (deprecated spelling).
@available(*, deprecated, renamed: "kCGImagePropertyExifSubsecTimeOriginal")
public let kCGImagePropertyExifSubsecTimeOrginal: String = "SubsecTimeOriginal"

/// The fraction of seconds for the original date and time tag.
public let kCGImagePropertyExifSubsecTimeOriginal: String = "SubsecTimeOriginal"

/// The fraction of seconds for the digitized date and time tag.
public let kCGImagePropertyExifSubsecTimeDigitized: String = "SubsecTimeDigitized"

/// The offset time.
public let kCGImagePropertyExifOffsetTime: String = "OffsetTime"

/// The offset time for the original date and time.
public let kCGImagePropertyExifOffsetTimeOriginal: String = "OffsetTimeOriginal"

/// The offset time for the digitized date and time.
public let kCGImagePropertyExifOffsetTimeDigitized: String = "OffsetTimeDigitized"

// MARK: - Lens Information

/// The specification information for the camera lens.
public let kCGImagePropertyExifLensSpecification: String = "LensSpecification"

/// A string with the name of the lens manufacturer.
public let kCGImagePropertyExifLensMake: String = "LensMake"

/// A string with the lens model information.
public let kCGImagePropertyExifLensModel: String = "LensModel"

/// A string with the lens's serial number.
public let kCGImagePropertyExifLensSerialNumber: String = "LensSerialNumber"

// MARK: - Camera Information

/// Information specified by the camera manufacturer.
public let kCGImagePropertyExifMakerNote: String = "MakerNote"

/// A user comment.
public let kCGImagePropertyExifUserComment: String = "UserComment"

/// A string with the name of the camera's owner.
public let kCGImagePropertyExifCameraOwnerName: String = "CameraOwnerName"

/// A string with the serial number of the camera.
public let kCGImagePropertyExifBodySerialNumber: String = "BodySerialNumber"

// MARK: - Flash Information

/// The FlashPix version supported by an FPXR file.
public let kCGImagePropertyExifFlashPixVersion: String = "FlashPixVersion"

/// The strobe energy when the image was captured, in beam candle power seconds.
public let kCGImagePropertyExifFlashEnergy: String = "FlashEnergy"

// MARK: - Auxiliary Keys

/// Lens information.
public let kCGImagePropertyExifAuxLensInfo: String = "LensInfo"

/// The lens model.
public let kCGImagePropertyExifAuxLensModel: String = "LensModel"

/// The serial number.
public let kCGImagePropertyExifAuxSerialNumber: String = "SerialNumber"

/// The lens ID.
public let kCGImagePropertyExifAuxLensID: String = "LensID"

/// The lens serial number.
public let kCGImagePropertyExifAuxLensSerialNumber: String = "LensSerialNumber"

/// The image number.
public let kCGImagePropertyExifAuxImageNumber: String = "ImageNumber"

/// Flash compensation.
public let kCGImagePropertyExifAuxFlashCompensation: String = "FlashCompensation"

/// The owner name.
public let kCGImagePropertyExifAuxOwnerName: String = "OwnerName"

/// Firmware information.
public let kCGImagePropertyExifAuxFirmware: String = "Firmware"

// MARK: - EXIF Format

/// The EXIF version.
public let kCGImagePropertyExifVersion: String = "ExifVersion"
