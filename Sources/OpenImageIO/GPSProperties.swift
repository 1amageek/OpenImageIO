// GPSProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Keys for Global Positioning System (GPS) information

@preconcurrency import Foundation

// MARK: - Dictionary

/// A dictionary of key-value pairs for an image that uses GPS data.
public let kCGImagePropertyGPSDictionary: String = "{GPS}"

// MARK: - Version

/// The version of the GPS information format.
public let kCGImagePropertyGPSVersion: String = "GPSVersion"

// MARK: - Latitude and Longitude

/// The latitude.
public let kCGImagePropertyGPSLatitude: String = "GPSLatitude"

/// The latitude reference (N or S).
public let kCGImagePropertyGPSLatitudeRef: String = "GPSLatitudeRef"

/// The longitude.
public let kCGImagePropertyGPSLongitude: String = "GPSLongitude"

/// The longitude reference (E or W).
public let kCGImagePropertyGPSLongitudeRef: String = "GPSLongitudeRef"

// MARK: - Altitude

/// The altitude.
public let kCGImagePropertyGPSAltitude: String = "GPSAltitude"

/// The altitude reference (above or below sea level).
public let kCGImagePropertyGPSAltitudeRef: String = "GPSAltitudeRef"

// MARK: - Timestamp

/// The GPS time (atomic clock).
public let kCGImagePropertyGPSTimeStamp: String = "GPSTimeStamp"

/// The GPS date.
public let kCGImagePropertyGPSDateStamp: String = "GPSDateStamp"

// MARK: - Satellites

/// The GPS satellites used for measurement.
public let kCGImagePropertyGPSSatellites: String = "GPSSatellites"

// MARK: - Status

/// The GPS receiver status.
public let kCGImagePropertyGPSStatus: String = "GPSStatus"

// MARK: - Measurement Mode

/// The GPS measurement mode.
public let kCGImagePropertyGPSMeasureMode: String = "GPSMeasureMode"

// MARK: - Precision

/// The GPS DOP (data degree of precision).
public let kCGImagePropertyGPSDOP: String = "GPSDOP"

// MARK: - Speed

/// The speed of GPS receiver movement.
public let kCGImagePropertyGPSSpeed: String = "GPSSpeed"

/// The unit used to express the GPS receiver speed (K, M, or N).
public let kCGImagePropertyGPSSpeedRef: String = "GPSSpeedRef"

// MARK: - Direction of Movement

/// The direction of GPS receiver movement.
public let kCGImagePropertyGPSTrack: String = "GPSTrack"

/// The reference for direction of movement (T or M).
public let kCGImagePropertyGPSTrackRef: String = "GPSTrackRef"

// MARK: - Image Direction

/// The direction of the image.
public let kCGImagePropertyGPSImgDirection: String = "GPSImgDirection"

/// The reference for direction of the image (T or M).
public let kCGImagePropertyGPSImgDirectionRef: String = "GPSImgDirectionRef"

// MARK: - Map Datum

/// The geodetic survey data used by the GPS receiver.
public let kCGImagePropertyGPSMapDatum: String = "GPSMapDatum"

// MARK: - Destination

/// The latitude of the destination point.
public let kCGImagePropertyGPSDestLatitude: String = "GPSDestLatitude"

/// The latitude reference of the destination point.
public let kCGImagePropertyGPSDestLatitudeRef: String = "GPSDestLatitudeRef"

/// The longitude of the destination point.
public let kCGImagePropertyGPSDestLongitude: String = "GPSDestLongitude"

/// The longitude reference of the destination point.
public let kCGImagePropertyGPSDestLongitudeRef: String = "GPSDestLongitudeRef"

/// The bearing to the destination point.
public let kCGImagePropertyGPSDestBearing: String = "GPSDestBearing"

/// The reference for bearing to destination (T or M).
public let kCGImagePropertyGPSDestBearingRef: String = "GPSDestBearingRef"

/// The distance to the destination point.
public let kCGImagePropertyGPSDestDistance: String = "GPSDestDistance"

/// The unit used to express the destination distance (K, M, or N).
public let kCGImagePropertyGPSDestDistanceRef: String = "GPSDestDistanceRef"

// MARK: - Processing Method

/// The name of the GPS processing method.
public let kCGImagePropertyGPSProcessingMethod: String = "GPSProcessingMethod"

// MARK: - Area Information

/// The name of the GPS area.
public let kCGImagePropertyGPSAreaInformation: String = "GPSAreaInformation"

// MARK: - Differential Correction

/// An indication of whether differential correction is applied to the GPS receiver.
public let kCGImagePropertyGPSDifferental: String = "GPSDifferental"

/// Whether differential correction was applied to GPS data (alternate spelling).
public let kCGImagePropertyGPSDifferential: String = "GPSDifferential"

// MARK: - Horizontal Positioning Error

/// The horizontal positioning error.
public let kCGImagePropertyGPSHPositioningError: String = "GPSHPositioningError"
