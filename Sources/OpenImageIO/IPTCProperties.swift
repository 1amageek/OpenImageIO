// IPTCProperties.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// Metadata keys for International Press Telecommunications Council (IPTC) data

// MARK: - Dictionary

/// A dictionary of key-value pairs for an image that uses International Press Telecommunications Council (IPTC) metadata.
public let kCGImagePropertyIPTCDictionary: CFString = "{IPTC}"

// MARK: - Image Categorization

/// The urgency level.
public let kCGImagePropertyIPTCUrgency: CFString = "Urgency"

/// The subject.
public let kCGImagePropertyIPTCSubjectReference: CFString = "SubjectReference"

/// The category.
public let kCGImagePropertyIPTCCategory: CFString = "Category"

/// A supplemental category.
public let kCGImagePropertyIPTCSupplementalCategory: CFString = "SupplementalCategory"

/// A fixture identifier.
public let kCGImagePropertyIPTCFixtureIdentifier: CFString = "FixtureIdentifier"

/// Keywords relevant to the image.
public let kCGImagePropertyIPTCKeywords: CFString = "Keywords"

/// The content location code.
public let kCGImagePropertyIPTCContentLocationCode: CFString = "ContentLocationCode"

/// The content location name.
public let kCGImagePropertyIPTCContentLocationName: CFString = "ContentLocationName"

/// The edit status.
public let kCGImagePropertyIPTCEditStatus: CFString = "EditStatus"

/// An editorial update.
public let kCGImagePropertyIPTCEditorialUpdate: CFString = "EditorialUpdate"

/// The editorial cycle (morning, evening, or both) of the image.
public let kCGImagePropertyIPTCObjectCycle: CFString = "ObjectCycle"

// MARK: - Image Information

/// The image type.
public let kCGImagePropertyIPTCImageType: CFString = "ImageType"

/// The image orientation (portrait, landscape, or square).
public let kCGImagePropertyIPTCImageOrientation: CFString = "ImageOrientation"

/// The language identifier, a two-letter code defined by ISO 639:1988.
public let kCGImagePropertyIPTCLanguageIdentifier: CFString = "LanguageIdentifier"

/// The description of the image.
public let kCGImagePropertyIPTCCaptionAbstract: CFString = "CaptionAbstract"

/// A summary of the contents of the image.
public let kCGImagePropertyIPTCHeadline: CFString = "Headline"

/// The name of the service that provided the image.
public let kCGImagePropertyIPTCCredit: CFString = "Credit"

/// The star rating.
public let kCGImagePropertyIPTCStarRating: CFString = "StarRating"

/// The scene codes for the image; a scene code is a six-digit string.
public let kCGImagePropertyIPTCScene: CFString = "Scene"

// MARK: - Copyright

/// The copyright notice.
public let kCGImagePropertyIPTCCopyrightNotice: CFString = "CopyrightNotice"

/// The usage rights for the image.
public let kCGImagePropertyIPTCRightsUsageTerms: CFString = "RightsUsageTerms"

// MARK: - Release Information

/// The earliest day on which you can use the image, in the form CCYYMMDD.
public let kCGImagePropertyIPTCReleaseDate: CFString = "ReleaseDate"

/// The earliest time at which you can use the image, in the form HHMMSS.
public let kCGImagePropertyIPTCReleaseTime: CFString = "ReleaseTime"

/// The latest date you can use the image, in the form CCYYMMDD.
public let kCGImagePropertyIPTCExpirationDate: CFString = "ExpirationDate"

/// The latest time on the expiration date you can use the image, in the form HHMMSS.
public let kCGImagePropertyIPTCExpirationTime: CFString = "ExpirationTime"

/// Special instructions about the use of the image.
public let kCGImagePropertyIPTCSpecialInstructions: CFString = "SpecialInstructions"

/// The advised action.
public let kCGImagePropertyIPTCActionAdvised: CFString = "ActionAdvised"

/// The reference service.
public let kCGImagePropertyIPTCReferenceService: CFString = "ReferenceService"

/// The reference date.
public let kCGImagePropertyIPTCReferenceDate: CFString = "ReferenceDate"

/// The reference number.
public let kCGImagePropertyIPTCReferenceNumber: CFString = "ReferenceNumber"

/// The creation date.
public let kCGImagePropertyIPTCDateCreated: CFString = "DateCreated"

/// The creation time.
public let kCGImagePropertyIPTCTimeCreated: CFString = "TimeCreated"

/// The digital creation date.
public let kCGImagePropertyIPTCDigitalCreationDate: CFString = "DigitalCreationDate"

/// The digital creation time.
public let kCGImagePropertyIPTCDigitalCreationTime: CFString = "DigitalCreationTime"

// MARK: - Personnel

/// The name of the person who created the image.
public let kCGImagePropertyIPTCByline: CFString = "Byline"

/// The title of the person who created the image.
public let kCGImagePropertyIPTCBylineTitle: CFString = "BylineTitle"

/// The original owner of the image.
public let kCGImagePropertyIPTCSource: CFString = "Source"

/// The contact information for getting details about the image.
public let kCGImagePropertyIPTCContact: CFString = "Contact"

/// The name of the person who wrote or edited the description of the image.
public let kCGImagePropertyIPTCWriterEditor: CFString = "WriterEditor"

/// The creator's contact info.
public let kCGImagePropertyIPTCCreatorContactInfo: CFString = "CreatorContactInfo"

// MARK: - Location Data

/// The city where the image was created.
public let kCGImagePropertyIPTCCity: CFString = "City"

/// The location within the city where the image was created.
public let kCGImagePropertyIPTCSubLocation: CFString = "SubLocation"

/// The province or state.
public let kCGImagePropertyIPTCProvinceState: CFString = "ProvinceState"

/// The primary country code, a three-letter code defined by ISO 3166-1.
public let kCGImagePropertyIPTCCountryPrimaryLocationCode: CFString = "CountryPrimaryLocationCode"

/// The primary country name.
public let kCGImagePropertyIPTCCountryPrimaryLocationName: CFString = "CountryPrimaryLocationName"

/// The call letter or number combination associated with the originating point of an image.
public let kCGImagePropertyIPTCOriginalTransmissionReference: CFString = "OriginalTransmissionReference"

// MARK: - Software Program

/// The originating application.
public let kCGImagePropertyIPTCOriginatingProgram: CFString = "OriginatingProgram"

/// The application version.
public let kCGImagePropertyIPTCProgramVersion: CFString = "ProgramVersion"

// MARK: - Object Details

/// The object type.
public let kCGImagePropertyIPTCObjectTypeReference: CFString = "ObjectTypeReference"

/// The object attribute.
public let kCGImagePropertyIPTCObjectAttributeReference: CFString = "ObjectAttributeReference"

/// The object name.
public let kCGImagePropertyIPTCObjectName: CFString = "ObjectName"

// MARK: - Creator Contact Info Dictionary Keys

/// The contact city.
public let kCGImagePropertyIPTCContactInfoCity: CFString = "CiAdrCity"

/// The contact country.
public let kCGImagePropertyIPTCContactInfoCountry: CFString = "CiAdrCtry"

/// The contact address.
public let kCGImagePropertyIPTCContactInfoAddress: CFString = "CiAdrExtadr"

/// The contact postal code.
public let kCGImagePropertyIPTCContactInfoPostalCode: CFString = "CiAdrPcode"

/// The contact region.
public let kCGImagePropertyIPTCContactInfoStateProvince: CFString = "CiAdrRegion"

/// The contact email.
public let kCGImagePropertyIPTCContactInfoEmails: CFString = "CiEmailWork"

/// The contact phone.
public let kCGImagePropertyIPTCContactInfoPhones: CFString = "CiTelWork"

/// The contact website.
public let kCGImagePropertyIPTCContactInfoWebURLs: CFString = "CiUrlWork"
