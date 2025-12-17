// XMPNamespaces.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework
// XMP Namespaces and Prefixes

@preconcurrency import Foundation

// MARK: - Public Namespaces

/// The namespace for the Dublin Core Metadata Element Set.
public let kCGImageMetadataNamespaceDublinCore: String = "http://purl.org/dc/elements/1.1/"

/// The namespace for the Exchangeable Image File (EXIF) format.
public let kCGImageMetadataNamespaceExif: String = "http://ns.adobe.com/exif/1.0/"

/// The namespace for EXIF auxiliary keys.
public let kCGImageMetadataNamespaceExifAux: String = "http://ns.adobe.com/exif/1.0/aux/"

/// The namespace for the exifEX format.
public let kCGImageMetadataNamespaceExifEX: String = "http://cipa.jp/exif/1.0/"

/// The namespace for the IPTC format.
public let kCGImageMetadataNamespaceIPTCCore: String = "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/"

/// The namespace for Photoshop image metadata.
public let kCGImageMetadataNamespacePhotoshop: String = "http://ns.adobe.com/photoshop/1.0/"

/// The namespace for TIFF image metadata.
public let kCGImageMetadataNamespaceTIFF: String = "http://ns.adobe.com/tiff/1.0/"

/// The namespace for the Extensible Metadata Platform (XMP) format.
public let kCGImageMetadataNamespaceXMPBasic: String = "http://ns.adobe.com/xap/1.0/"

/// The namespace for XMP metadata that conveys legal restrictions associated with a resource.
public let kCGImageMetadataNamespaceXMPRights: String = "http://ns.adobe.com/xap/1.0/rights/"

// MARK: - Public Prefixes

/// The prefix string for tags in the Dublin Core Metadata Element Set.
public let kCGImageMetadataPrefixDublinCore: String = "dc"

/// The prefix string for tags in the Exchangeable Image File (EXIF) metadata.
public let kCGImageMetadataPrefixExif: String = "exif"

/// The prefix string for tags in the EXIF auxiliary metadata collection.
public let kCGImageMetadataPrefixExifAux: String = "aux"

/// The prefix string for tags in the exifEX metadata.
public let kCGImageMetadataPrefixExifEX: String = "exifEX"

/// The prefix string for tags in the IPTC metadata.
public let kCGImageMetadataPrefixIPTCCore: String = "Iptc4xmpCore"

/// The prefix string for tags in the Photoshop image metadata.
public let kCGImageMetadataPrefixPhotoshop: String = "photoshop"

/// The prefix string for tags in the TIFF image metadata.
public let kCGImageMetadataPrefixTIFF: String = "tiff"

/// The prefix string for tags in the XMP metadata.
public let kCGImageMetadataPrefixXMPBasic: String = "xmp"

/// The prefix string for tags in the XMP metadata that convey legal restrictions for the resource.
public let kCGImageMetadataPrefixXMPRights: String = "xmpRights"

// MARK: - IPTC Extension

/// The namespace for IPTC Extension metadata.
public let kCGImageMetadataNamespaceIPTCExtension: String = "http://iptc.org/std/Iptc4xmpExt/2008-02-29/"

/// The prefix string for IPTC Extension metadata.
public let kCGImageMetadataPrefixIPTCExtension: String = "Iptc4xmpExt"
