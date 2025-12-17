// IPTCProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Metadata keys for International Press Telecommunications Council (IPTC) data

@preconcurrency import Foundation

// MARK: - Dictionary

/// A dictionary of key-value pairs for an image that uses International Press Telecommunications Council (IPTC) metadata.
public let kCGImagePropertyIPTCDictionary: String = "{IPTC}"

// MARK: - Image Categorization

/// The urgency level.
public let kCGImagePropertyIPTCUrgency: String = "Urgency"

/// The subject.
public let kCGImagePropertyIPTCSubjectReference: String = "SubjectReference"

/// The category.
public let kCGImagePropertyIPTCCategory: String = "Category"

/// A supplemental category.
public let kCGImagePropertyIPTCSupplementalCategory: String = "SupplementalCategory"

/// A fixture identifier.
public let kCGImagePropertyIPTCFixtureIdentifier: String = "FixtureIdentifier"

/// Keywords relevant to the image.
public let kCGImagePropertyIPTCKeywords: String = "Keywords"

/// The content location code.
public let kCGImagePropertyIPTCContentLocationCode: String = "ContentLocationCode"

/// The content location name.
public let kCGImagePropertyIPTCContentLocationName: String = "ContentLocationName"

/// The edit status.
public let kCGImagePropertyIPTCEditStatus: String = "EditStatus"

/// An editorial update.
public let kCGImagePropertyIPTCEditorialUpdate: String = "EditorialUpdate"

/// The editorial cycle (morning, evening, or both) of the image.
public let kCGImagePropertyIPTCObjectCycle: String = "ObjectCycle"

// MARK: - Image Information

/// The image type.
public let kCGImagePropertyIPTCImageType: String = "ImageType"

/// The image orientation (portrait, landscape, or square).
public let kCGImagePropertyIPTCImageOrientation: String = "ImageOrientation"

/// The language identifier, a two-letter code defined by ISO 639:1988.
public let kCGImagePropertyIPTCLanguageIdentifier: String = "LanguageIdentifier"

/// The description of the image.
public let kCGImagePropertyIPTCCaptionAbstract: String = "CaptionAbstract"

/// A summary of the contents of the image.
public let kCGImagePropertyIPTCHeadline: String = "Headline"

/// The name of the service that provided the image.
public let kCGImagePropertyIPTCCredit: String = "Credit"

/// The star rating.
public let kCGImagePropertyIPTCStarRating: String = "StarRating"

/// The scene codes for the image; a scene code is a six-digit string.
public let kCGImagePropertyIPTCScene: String = "Scene"

// MARK: - Copyright

/// The copyright notice.
public let kCGImagePropertyIPTCCopyrightNotice: String = "CopyrightNotice"

/// The usage rights for the image.
public let kCGImagePropertyIPTCRightsUsageTerms: String = "RightsUsageTerms"

// MARK: - Release Information

/// The earliest day on which you can use the image, in the form CCYYMMDD.
public let kCGImagePropertyIPTCReleaseDate: String = "ReleaseDate"

/// The earliest time at which you can use the image, in the form HHMMSS.
public let kCGImagePropertyIPTCReleaseTime: String = "ReleaseTime"

/// The latest date you can use the image, in the form CCYYMMDD.
public let kCGImagePropertyIPTCExpirationDate: String = "ExpirationDate"

/// The latest time on the expiration date you can use the image, in the form HHMMSS.
public let kCGImagePropertyIPTCExpirationTime: String = "ExpirationTime"

/// Special instructions about the use of the image.
public let kCGImagePropertyIPTCSpecialInstructions: String = "SpecialInstructions"

/// The advised action.
public let kCGImagePropertyIPTCActionAdvised: String = "ActionAdvised"

/// The reference service.
public let kCGImagePropertyIPTCReferenceService: String = "ReferenceService"

/// The reference date.
public let kCGImagePropertyIPTCReferenceDate: String = "ReferenceDate"

/// The reference number.
public let kCGImagePropertyIPTCReferenceNumber: String = "ReferenceNumber"

/// The creation date.
public let kCGImagePropertyIPTCDateCreated: String = "DateCreated"

/// The creation time.
public let kCGImagePropertyIPTCTimeCreated: String = "TimeCreated"

/// The digital creation date.
public let kCGImagePropertyIPTCDigitalCreationDate: String = "DigitalCreationDate"

/// The digital creation time.
public let kCGImagePropertyIPTCDigitalCreationTime: String = "DigitalCreationTime"

// MARK: - Personnel

/// The name of the person who created the image.
public let kCGImagePropertyIPTCByline: String = "Byline"

/// The title of the person who created the image.
public let kCGImagePropertyIPTCBylineTitle: String = "BylineTitle"

/// The original owner of the image.
public let kCGImagePropertyIPTCSource: String = "Source"

/// The contact information for getting details about the image.
public let kCGImagePropertyIPTCContact: String = "Contact"

/// The name of the person who wrote or edited the description of the image.
public let kCGImagePropertyIPTCWriterEditor: String = "WriterEditor"

/// The creator's contact info.
public let kCGImagePropertyIPTCCreatorContactInfo: String = "CreatorContactInfo"

// MARK: - Location Data

/// The city where the image was created.
public let kCGImagePropertyIPTCCity: String = "City"

/// The location within the city where the image was created.
public let kCGImagePropertyIPTCSubLocation: String = "SubLocation"

/// The province or state.
public let kCGImagePropertyIPTCProvinceState: String = "ProvinceState"

/// The primary country code, a three-letter code defined by ISO 3166-1.
public let kCGImagePropertyIPTCCountryPrimaryLocationCode: String = "CountryPrimaryLocationCode"

/// The primary country name.
public let kCGImagePropertyIPTCCountryPrimaryLocationName: String = "CountryPrimaryLocationName"

/// The call letter or number combination associated with the originating point of an image.
public let kCGImagePropertyIPTCOriginalTransmissionReference: String = "OriginalTransmissionReference"

// MARK: - Software Program

/// The originating application.
public let kCGImagePropertyIPTCOriginatingProgram: String = "OriginatingProgram"

/// The application version.
public let kCGImagePropertyIPTCProgramVersion: String = "ProgramVersion"

// MARK: - Object Details

/// The object type.
public let kCGImagePropertyIPTCObjectTypeReference: String = "ObjectTypeReference"

/// The object attribute.
public let kCGImagePropertyIPTCObjectAttributeReference: String = "ObjectAttributeReference"

/// The object name.
public let kCGImagePropertyIPTCObjectName: String = "ObjectName"

// MARK: - Creator Contact Info Dictionary Keys

/// The contact city.
public let kCGImagePropertyIPTCContactInfoCity: String = "CiAdrCity"

/// The contact country.
public let kCGImagePropertyIPTCContactInfoCountry: String = "CiAdrCtry"

/// The contact address.
public let kCGImagePropertyIPTCContactInfoAddress: String = "CiAdrExtadr"

/// The contact postal code.
public let kCGImagePropertyIPTCContactInfoPostalCode: String = "CiAdrPcode"

/// The contact region.
public let kCGImagePropertyIPTCContactInfoStateProvince: String = "CiAdrRegion"

/// The contact email.
public let kCGImagePropertyIPTCContactInfoEmails: String = "CiEmailWork"

/// The contact phone.
public let kCGImagePropertyIPTCContactInfoPhones: String = "CiTelWork"

/// The contact website.
public let kCGImagePropertyIPTCContactInfoWebURLs: String = "CiUrlWork"
