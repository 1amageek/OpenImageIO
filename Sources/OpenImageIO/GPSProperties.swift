// GPSProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Keys for Global Positioning System (GPS) information

// MARK: - Dictionary

/// A dictionary of key-value pairs for an image that uses GPS data.
public let kCGImagePropertyGPSDictionary: CFString = "{GPS}"

// MARK: - Version

/// The version of the GPS information format.
public let kCGImagePropertyGPSVersion: CFString = "GPSVersion"

// MARK: - Latitude and Longitude

/// The latitude.
public let kCGImagePropertyGPSLatitude: CFString = "GPSLatitude"

/// The latitude reference (N or S).
public let kCGImagePropertyGPSLatitudeRef: CFString = "GPSLatitudeRef"

/// The longitude.
public let kCGImagePropertyGPSLongitude: CFString = "GPSLongitude"

/// The longitude reference (E or W).
public let kCGImagePropertyGPSLongitudeRef: CFString = "GPSLongitudeRef"

// MARK: - Altitude

/// The altitude.
public let kCGImagePropertyGPSAltitude: CFString = "GPSAltitude"

/// The altitude reference (above or below sea level).
public let kCGImagePropertyGPSAltitudeRef: CFString = "GPSAltitudeRef"

// MARK: - Timestamp

/// The GPS time (atomic clock).
public let kCGImagePropertyGPSTimeStamp: CFString = "GPSTimeStamp"

/// The GPS date.
public let kCGImagePropertyGPSDateStamp: CFString = "GPSDateStamp"

// MARK: - Satellites

/// The GPS satellites used for measurement.
public let kCGImagePropertyGPSSatellites: CFString = "GPSSatellites"

// MARK: - Status

/// The GPS receiver status.
public let kCGImagePropertyGPSStatus: CFString = "GPSStatus"

// MARK: - Measurement Mode

/// The GPS measurement mode.
public let kCGImagePropertyGPSMeasureMode: CFString = "GPSMeasureMode"

// MARK: - Precision

/// The GPS DOP (data degree of precision).
public let kCGImagePropertyGPSDOP: CFString = "GPSDOP"

// MARK: - Speed

/// The speed of GPS receiver movement.
public let kCGImagePropertyGPSSpeed: CFString = "GPSSpeed"

/// The unit used to express the GPS receiver speed (K, M, or N).
public let kCGImagePropertyGPSSpeedRef: CFString = "GPSSpeedRef"

// MARK: - Direction of Movement

/// The direction of GPS receiver movement.
public let kCGImagePropertyGPSTrack: CFString = "GPSTrack"

/// The reference for direction of movement (T or M).
public let kCGImagePropertyGPSTrackRef: CFString = "GPSTrackRef"

// MARK: - Image Direction

/// The direction of the image.
public let kCGImagePropertyGPSImgDirection: CFString = "GPSImgDirection"

/// The reference for direction of the image (T or M).
public let kCGImagePropertyGPSImgDirectionRef: CFString = "GPSImgDirectionRef"

// MARK: - Map Datum

/// The geodetic survey data used by the GPS receiver.
public let kCGImagePropertyGPSMapDatum: CFString = "GPSMapDatum"

// MARK: - Destination

/// The latitude of the destination point.
public let kCGImagePropertyGPSDestLatitude: CFString = "GPSDestLatitude"

/// The latitude reference of the destination point.
public let kCGImagePropertyGPSDestLatitudeRef: CFString = "GPSDestLatitudeRef"

/// The longitude of the destination point.
public let kCGImagePropertyGPSDestLongitude: CFString = "GPSDestLongitude"

/// The longitude reference of the destination point.
public let kCGImagePropertyGPSDestLongitudeRef: CFString = "GPSDestLongitudeRef"

/// The bearing to the destination point.
public let kCGImagePropertyGPSDestBearing: CFString = "GPSDestBearing"

/// The reference for bearing to destination (T or M).
public let kCGImagePropertyGPSDestBearingRef: CFString = "GPSDestBearingRef"

/// The distance to the destination point.
public let kCGImagePropertyGPSDestDistance: CFString = "GPSDestDistance"

/// The unit used to express the destination distance (K, M, or N).
public let kCGImagePropertyGPSDestDistanceRef: CFString = "GPSDestDistanceRef"

// MARK: - Processing Method

/// The name of the GPS processing method.
public let kCGImagePropertyGPSProcessingMethod: CFString = "GPSProcessingMethod"

// MARK: - Area Information

/// The name of the GPS area.
public let kCGImagePropertyGPSAreaInformation: CFString = "GPSAreaInformation"

// MARK: - Differential Correction

/// An indication of whether differential correction is applied to the GPS receiver.
public let kCGImagePropertyGPSDifferental: CFString = "GPSDifferental"

/// Whether differential correction was applied to GPS data (alternate spelling).
public let kCGImagePropertyGPSDifferential: CFString = "GPSDifferential"

// MARK: - Horizontal Positioning Error

/// The horizontal positioning error.
public let kCGImagePropertyGPSHPositioningError: CFString = "GPSHPositioningError"
