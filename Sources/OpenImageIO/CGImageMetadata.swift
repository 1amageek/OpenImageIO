// CGImageMetadata.swift
// OpenImageIO
//
// Full API compatibility with Apple's ImageIO framework

@preconcurrency import Foundation
import OpenCoreGraphics

/// An immutable object that contains the XMP metadata associated with an image.
public class CGImageMetadata: Hashable, Equatable {

    // MARK: - Internal Storage

    internal var tags: [CGImageMetadataTag]

    // MARK: - Initialization

    internal init(tags: [CGImageMetadataTag] = []) {
        self.tags = tags
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageMetadata, rhs: CGImageMetadata) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// An opaque type for adding or modifying image metadata.
public class CGMutableImageMetadata: CGImageMetadata {

    // MARK: - Initialization

    public override init(tags: [CGImageMetadataTag] = []) {
        super.init(tags: tags)
    }

    // MARK: - Mutating Methods

    internal func addTag(_ tag: CGImageMetadataTag) {
        tags.append(tag)
    }

    internal func removeTag(at index: Int) {
        guard index >= 0 && index < tags.count else { return }
        tags.remove(at: index)
    }
}

// MARK: - CGImageMetadata Creation Functions

/// Creates a collection of metadata tags from the specified XMP data.
public func CGImageMetadataCreateFromXMPData(_ data: Data) -> CGImageMetadata? {
    // Parse XMP data and create metadata tags
    // This is a simplified implementation
    let xmpString = String(data: data, encoding: .utf8) ?? ""

    guard !xmpString.isEmpty else { return nil }

    let metadata = CGImageMetadata()

    // Basic XMP parsing - extract common tags
    // In a full implementation, this would parse the XML structure
    if let titleRange = xmpString.range(of: "<dc:title>"),
       let titleEndRange = xmpString.range(of: "</dc:title>") {
        let titleStart = xmpString.index(titleRange.upperBound, offsetBy: 0)
        let titleContent = String(xmpString[titleStart..<titleEndRange.lowerBound])
        if let tag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceDublinCore,
            kCGImageMetadataPrefixDublinCore,
            "title",
            .string,
            titleContent
        ) {
            metadata.tags.append(tag)
        }
    }

    return metadata
}

/// Creates a mutable metadata object.
public func CGImageMetadataCreateMutable() -> CGMutableImageMetadata {
    return CGMutableImageMetadata()
}

/// Creates a mutable copy of metadata from an existing metadata object.
public func CGImageMetadataCreateMutableCopy(_ metadata: CGImageMetadata) -> CGMutableImageMetadata? {
    let copy = CGMutableImageMetadata()
    copy.tags = metadata.tags
    return copy
}

// MARK: - CGImageMetadata Tag Access Functions

/// Searches for a specific metadata tag within a metadata collection.
public func CGImageMetadataCopyTagWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String
) -> CGImageMetadataTag? {
    let components = path.split(separator: ":")

    for tag in metadata.tags {
        if components.count == 2 {
            let prefix = String(components[0])
            let name = String(components[1])
            if tag.prefix == prefix && tag.name == name {
                return tag
            }
        } else if tag.name == path {
            return tag
        }
    }

    return nil
}

/// Returns an array of root-level metadata tags from the specified metadata object.
public func CGImageMetadataCopyTags(_ metadata: CGImageMetadata) -> [CGImageMetadataTag]? {
    guard !metadata.tags.isEmpty else { return nil }
    return metadata.tags
}

/// Searches for the specified image property and, if found, returns the corresponding tag object.
public func CGImageMetadataCopyTagMatchingImageProperty(
    _ metadata: CGImageMetadata,
    _ dictionaryName: String,
    _ propertyName: String
) -> CGImageMetadataTag? {
    // Map common image properties to XMP tags
    for tag in metadata.tags {
        if tag.namespace.contains(dictionaryName) && tag.name == propertyName {
            return tag
        }
    }

    return nil
}

/// Searches the metadata for the specified tag, and returns its string value if it exists.
public func CGImageMetadataCopyStringValueWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String
) -> String? {
    guard let tag = CGImageMetadataCopyTagWithPath(metadata, parent, path) else {
        return nil
    }

    if let stringValue = tag.value as? String {
        return stringValue
    }

    return nil
}

// MARK: - CGImageMetadata Enumeration Functions

/// The block to execute when enumerating the tags of a metadata object.
public typealias CGImageMetadataTagBlock = (String, CGImageMetadataTag) -> Bool

/// Enumerates the tags of a metadata object and executes the specified block on each tag.
public func CGImageMetadataEnumerateTagsUsingBlock(
    _ metadata: CGImageMetadata,
    _ rootPath: String?,
    _ options: [String: Any]?,
    _ block: CGImageMetadataTagBlock
) {
    let recursive = options?[kCGImageMetadataEnumerateRecursively] as? Bool ?? false
    _ = recursive // Used in full implementation for nested tag enumeration

    for tag in metadata.tags {
        let path = "\(tag.prefix ?? ""):\(tag.name)"
        if !block(path, tag) {
            break
        }
    }
}

/// An option to enumerate recursively through a set of metadata tags.
public let kCGImageMetadataEnumerateRecursively: String = "kCGImageMetadataEnumerateRecursively"

// MARK: - CGImageMetadata XMP Functions

/// Returns a data object that contains the metadata object's contents serialized into the XMP format.
public func CGImageMetadataCreateXMPData(
    _ metadata: CGImageMetadata,
    _ options: [String: Any]?
) -> Data? {
    var xmp = """
    <?xpacket begin='\u{feff}' id='W5M0MpCehiHzreSzNTczkc9d'?>
    <x:xmpmeta xmlns:x='adobe:ns:meta/'>
    <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
    <rdf:Description rdf:about=''
    """

    // Add namespace declarations
    var namespaces = Set<String>()
    for tag in metadata.tags {
        namespaces.insert(tag.namespace)
    }

    for ns in namespaces {
        if let prefix = prefixForNamespace(ns) {
            xmp += " xmlns:\(prefix)='\(ns)'"
        }
    }

    xmp += ">\n"

    // Add tags
    for tag in metadata.tags {
        if let prefix = tag.prefix {
            xmp += "<\(prefix):\(tag.name)>\(tag.value)</\(prefix):\(tag.name)>\n"
        } else {
            xmp += "<\(tag.name)>\(tag.value)</\(tag.name)>\n"
        }
    }

    xmp += """
    </rdf:Description>
    </rdf:RDF>
    </x:xmpmeta>
    <?xpacket end='w'?>
    """

    return xmp.data(using: .utf8)
}

private func prefixForNamespace(_ namespace: String) -> String? {
    switch namespace {
    case kCGImageMetadataNamespaceDublinCore:
        return kCGImageMetadataPrefixDublinCore
    case kCGImageMetadataNamespaceExif:
        return kCGImageMetadataPrefixExif
    case kCGImageMetadataNamespaceExifAux:
        return kCGImageMetadataPrefixExifAux
    case kCGImageMetadataNamespaceExifEX:
        return kCGImageMetadataPrefixExifEX
    case kCGImageMetadataNamespaceIPTCCore:
        return kCGImageMetadataPrefixIPTCCore
    case kCGImageMetadataNamespacePhotoshop:
        return kCGImageMetadataPrefixPhotoshop
    case kCGImageMetadataNamespaceTIFF:
        return kCGImageMetadataPrefixTIFF
    case kCGImageMetadataNamespaceXMPBasic:
        return kCGImageMetadataPrefixXMPBasic
    case kCGImageMetadataNamespaceXMPRights:
        return kCGImageMetadataPrefixXMPRights
    default:
        return nil
    }
}

// MARK: - CGImageMetadata Type Functions


// MARK: - CGMutableImageMetadata Functions

/// Registers a namespace and its prefix for use with metadata.
public func CGImageMetadataRegisterNamespaceForPrefix(
    _ metadata: CGMutableImageMetadata,
    _ xmlns: String,
    _ prefix: String,
    _ error: UnsafeMutablePointer<Error?>?
) -> Bool {
    // In a full implementation, this would store namespace-prefix mappings
    return true
}

/// Sets the value of the metadata tag at the specified path.
@discardableResult
public func CGImageMetadataSetValueWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String,
    _ value: Any
) -> Bool {
    let components = path.split(separator: ":")

    // Try to find existing tag
    for (index, tag) in metadata.tags.enumerated() {
        if components.count == 2 {
            let prefix = String(components[0])
            let name = String(components[1])
            if tag.prefix == prefix && tag.name == name {
                // Create new tag with updated value
                if let newTag = CGImageMetadataTagCreate(
                    tag.namespace,
                    tag.prefix,
                    tag.name,
                    tag.type,
                    value
                ) {
                    metadata.tags[index] = newTag
                    return true
                }
            }
        }
    }

    // Create new tag
    if components.count == 2 {
        let prefix = String(components[0])
        let name = String(components[1])

        let namespace = namespaceForPrefix(prefix)
        if let tag = CGImageMetadataTagCreate(
            namespace,
            prefix,
            name,
            .string,
            value
        ) {
            metadata.tags.append(tag)
            return true
        }
    }

    return false
}

/// Sets the value of a metadata tag that matches the specified image property.
public func CGImageMetadataSetValueMatchingImageProperty(
    _ metadata: CGMutableImageMetadata,
    _ dictionaryName: String,
    _ propertyName: String,
    _ value: Any
) -> Bool {
    // Map image property to XMP tag and set value
    if let tag = CGImageMetadataTagCreate(
        dictionaryName,
        prefixForNamespace(dictionaryName),
        propertyName,
        .string,
        value
    ) {
        metadata.tags.append(tag)
        return true
    }

    return false
}

/// Removes the metadata tag at the specified path.
public func CGImageMetadataRemoveTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String
) -> Bool {
    let components = path.split(separator: ":")

    for (index, tag) in metadata.tags.enumerated() {
        if components.count == 2 {
            let prefix = String(components[0])
            let name = String(components[1])
            if tag.prefix == prefix && tag.name == name {
                metadata.tags.remove(at: index)
                return true
            }
        } else if tag.name == path {
            metadata.tags.remove(at: index)
            return true
        }
    }

    return false
}

/// Sets a tag in a mutable metadata object.
@discardableResult
public func CGImageMetadataSetTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String,
    _ tag: CGImageMetadataTag
) -> Bool {
    // Find and replace existing tag with same path, or add new
    let components = path.split(separator: ":")

    for (index, existingTag) in metadata.tags.enumerated() {
        if components.count == 2 {
            let prefix = String(components[0])
            let name = String(components[1])
            if existingTag.prefix == prefix && existingTag.name == name {
                metadata.tags[index] = tag
                return true
            }
        }
    }

    metadata.tags.append(tag)
    return true
}

private func namespaceForPrefix(_ prefix: String) -> String {
    switch prefix {
    case kCGImageMetadataPrefixDublinCore:
        return kCGImageMetadataNamespaceDublinCore
    case kCGImageMetadataPrefixExif:
        return kCGImageMetadataNamespaceExif
    case kCGImageMetadataPrefixExifAux:
        return kCGImageMetadataNamespaceExifAux
    case kCGImageMetadataPrefixExifEX:
        return kCGImageMetadataNamespaceExifEX
    case kCGImageMetadataPrefixIPTCCore:
        return kCGImageMetadataNamespaceIPTCCore
    case kCGImageMetadataPrefixPhotoshop:
        return kCGImageMetadataNamespacePhotoshop
    case kCGImageMetadataPrefixTIFF:
        return kCGImageMetadataNamespaceTIFF
    case kCGImageMetadataPrefixXMPBasic:
        return kCGImageMetadataNamespaceXMPBasic
    case kCGImageMetadataPrefixXMPRights:
        return kCGImageMetadataNamespaceXMPRights
    default:
        return ""
    }
}
