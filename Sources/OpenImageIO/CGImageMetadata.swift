// CGImageMetadata.swift
// OpenImageIO
//
// ImageIO-compatible API surface for non-Apple platforms

@preconcurrency import OpenFoundation
import OpenCoreGraphics
import Synchronization

internal let standardXMPNamespaces: [String: String] = [
    kCGImageMetadataPrefixDublinCore: kCGImageMetadataNamespaceDublinCore,
    kCGImageMetadataPrefixExif: kCGImageMetadataNamespaceExif,
    kCGImageMetadataPrefixExifAux: kCGImageMetadataNamespaceExifAux,
    kCGImageMetadataPrefixExifEX: kCGImageMetadataNamespaceExifEX,
    kCGImageMetadataPrefixIPTCCore: kCGImageMetadataNamespaceIPTCCore,
    kCGImageMetadataPrefixIPTCExtension: kCGImageMetadataNamespaceIPTCExtension,
    kCGImageMetadataPrefixPhotoshop: kCGImageMetadataNamespacePhotoshop,
    kCGImageMetadataPrefixTIFF: kCGImageMetadataNamespaceTIFF,
    kCGImageMetadataPrefixXMPBasic: kCGImageMetadataNamespaceXMPBasic,
    kCGImageMetadataPrefixXMPRights: kCGImageMetadataNamespaceXMPRights,
    "xml": "http://www.w3.org/XML/1998/namespace"
]

/// An immutable object that contains the XMP metadata associated with an image.
public class CGImageMetadata: Hashable, Equatable {

    internal struct State: Sendable {
        var tags: [CGImageMetadataTag]
        var namespaceByPrefix: [String: String]
    }

    private let state: Mutex<State>

    // MARK: - Initialization

    internal init(tags: [CGImageMetadataTag] = []) {
        self.state = Mutex(State(
            tags: tags,
            namespaceByPrefix: standardXMPNamespaces
        ))
    }

    internal init(tags: [CGImageMetadataTag], namespaceByPrefix: [String: String]) {
        self.state = Mutex(State(
            tags: tags,
            namespaceByPrefix: namespaceByPrefix
        ))
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: CGImageMetadata, rhs: CGImageMetadata) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    internal func snapshot() -> State {
        state.withLock { $0 }
    }

    internal func mutate<Result: Sendable>(
        _ body: (inout sending State) -> sending Result
    ) -> Result {
        state.withLock(body)
    }
}

/// An opaque type for adding or modifying image metadata.
public class CGMutableImageMetadata: CGImageMetadata {

    // MARK: - Initialization

    public override init(tags: [CGImageMetadataTag] = []) {
        super.init(tags: tags)
    }

    internal init(tags: [CGImageMetadataTag], registeredNamespaces: [String: String]) {
        super.init(tags: tags, namespaceByPrefix: registeredNamespaces)
    }
}

// MARK: - CGImageMetadata Creation Functions

/// Creates a collection of metadata tags from the specified XMP data.
public func CGImageMetadataCreateFromXMPData(_ data: Data) -> CGImageMetadata? {
    guard let decoded = XMPCodec.decode(data) else { return nil }
    return CGImageMetadata(
        tags: decoded.tags,
        namespaceByPrefix: standardXMPNamespaces.merging(decoded.namespaces) { _, parsed in parsed }
    )
}

/// Creates a mutable metadata object.
public func CGImageMetadataCreateMutable() -> CGMutableImageMetadata {
    return CGMutableImageMetadata()
}

/// Creates a mutable copy of metadata from an existing metadata object.
public func CGImageMetadataCreateMutableCopy(_ metadata: CGImageMetadata) -> CGMutableImageMetadata? {
    let snapshot = metadata.snapshot()
    return CGMutableImageMetadata(
        tags: snapshot.tags,
        registeredNamespaces: snapshot.namespaceByPrefix
    )
}

// MARK: - CGImageMetadata Tag Access Functions

/// Searches for a specific metadata tag within a metadata collection.
public func CGImageMetadataCopyTagWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String
) -> CGImageMetadataTag? {
    guard let parsedPath = MetadataPath(path) else { return nil }
    guard parent != nil || parsedPath.components.first?.prefix != nil else { return nil }
    return resolve(path: parsedPath, in: metadata.snapshot().tags, parent: parent)
}

/// Returns an array of root-level metadata tags from the specified metadata object.
public func CGImageMetadataCopyTags(_ metadata: CGImageMetadata) -> [CGImageMetadataTag]? {
    let tags = metadata.snapshot().tags
    guard !tags.isEmpty else { return nil }
    return tags
}

/// Searches for the specified image property and, if found, returns the corresponding tag object.
public func CGImageMetadataCopyTagMatchingImageProperty(
    _ metadata: CGImageMetadata,
    _ dictionaryName: String,
    _ propertyName: String
) -> CGImageMetadataTag? {
    metadata.snapshot().tags.first { tag in
        tag.namespace == dictionaryName && tag.name == propertyName
    }
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
    let roots: [(path: String, tag: CGImageMetadataTag)]
    if let rootPath {
        guard let root = CGImageMetadataCopyTagWithPath(metadata, nil, rootPath) else { return }
        roots = [(rootPath, root)]
    } else {
        roots = metadata.snapshot().tags.map { (qualifiedName(for: $0), $0) }
    }

    for root in roots {
        if !enumerate(tag: root.tag, path: root.path, recursive: recursive, block: block) {
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
    let snapshot = metadata.snapshot()
    return XMPCodec.encode(tags: snapshot.tags, namespaces: snapshot.namespaceByPrefix)
}

// MARK: - CGMutableImageMetadata Functions

/// Registers a namespace and its prefix for use with metadata.
public func CGImageMetadataRegisterNamespaceForPrefix(
    _ metadata: CGMutableImageMetadata,
    _ xmlns: String,
    _ prefix: String,
    _ error: UnsafeMutablePointer<Error?>?
) -> Bool {
    guard isValidMetadataPrefix(prefix),
          isValidMetadataNamespace(xmlns) else {
        error?.pointee = metadataError(.badArgument, description: "Invalid XML namespace or prefix.")
        return false
    }

    let outcome = metadata.mutate { state -> Int in
        if let registeredNamespace = state.namespaceByPrefix[prefix] {
            return registeredNamespace == xmlns ? 0 : 1
        }
        if let registeredPrefix = state.namespaceByPrefix.first(where: { $0.value == xmlns })?.key {
            return registeredPrefix == prefix ? 0 : 2
        }
        state.namespaceByPrefix[prefix] = xmlns
        return 0
    }
    switch outcome {
    case 0:
        return true
    case 1:
        error?.pointee = metadataError(
            .prefixConflict,
            description: "The prefix is already registered for another namespace."
        )
    default:
        error?.pointee = metadataError(
            .prefixConflict,
            description: "The namespace is already registered with another prefix."
        )
    }
    return false
}

/// Sets the value of the metadata tag at the specified path.
@discardableResult
public func CGImageMetadataSetValueWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String,
    _ value: Any
) -> Bool {
    guard let parsedPath = MetadataPath(path) else { return false }
    guard parent != nil || parsedPath.components.first?.prefix != nil else { return false }
    return metadata.mutate { state in
        if let existing = resolve(path: parsedPath, in: state.tags, parent: parent) {
            guard let replacement = tagByReplacingValue(
                existing,
                value: value,
                namespaceByPrefix: state.namespaceByPrefix
            ) else { return false }
            return replaceTag(in: &state.tags, target: existing, replacement: replacement)
        }

        guard isMetadataScalar(value),
              let component = parsedPath.components.last,
              component.selector == nil,
              component.qualifier == nil,
              let prefix = component.prefix ?? parent?.prefix ?? parsedPath.components.dropLast().last?.prefix,
              let namespace = state.namespaceByPrefix[prefix],
              let tag = CGImageMetadataTagCreate(
                namespace,
                prefix,
                component.name,
                .string,
                value
              ) else { return false }
        return insert(
            tag: tag,
            for: parsedPath,
            parent: parent,
            tags: &state.tags
        )
    }
}

/// Sets the value of a metadata tag that matches the specified image property.
public func CGImageMetadataSetValueMatchingImageProperty(
    _ metadata: CGMutableImageMetadata,
    _ dictionaryName: String,
    _ propertyName: String,
    _ value: Any
) -> Bool {
    guard isMetadataScalar(value) else { return false }
    return metadata.mutate { state in
        guard let prefix = state.namespaceByPrefix.first(where: { $0.value == dictionaryName })?.key,
              let tag = CGImageMetadataTagCreate(
                dictionaryName,
                prefix,
                propertyName,
                .string,
                value
              ) else { return false }
        if let existing = state.tags.first(where: {
            $0.namespace == dictionaryName && $0.name == propertyName
        }) {
            return replaceTag(in: &state.tags, target: existing, replacement: tag)
        }
        state.tags.append(tag)
        return true
    }
}

/// Removes the metadata tag at the specified path.
public func CGImageMetadataRemoveTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String
) -> Bool {
    guard let parsedPath = MetadataPath(path),
          parent != nil || parsedPath.components.first?.prefix != nil else { return false }
    return metadata.mutate { state in
        guard let target = resolve(path: parsedPath, in: state.tags, parent: parent) else {
            return false
        }
        return removeTag(from: &state.tags, target: target)
    }
}

/// Sets a tag in a mutable metadata object.
@discardableResult
public func CGImageMetadataSetTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: String,
    _ tag: CGImageMetadataTag
) -> Bool {
    guard let parsedPath = MetadataPath(path) else { return false }
    guard parent != nil || parsedPath.components.first?.prefix != nil else { return false }
    return metadata.mutate { state in
        if let existing = resolve(path: parsedPath, in: state.tags, parent: parent) {
            return replaceTag(in: &state.tags, target: existing, replacement: tag)
        }
        guard let component = parsedPath.components.last,
              component.selector == nil,
              component.qualifier == nil,
              component.name == tag.name,
              component.prefix == nil || component.prefix == tag.prefix else { return false }
        if let prefix = tag.prefix {
            guard state.namespaceByPrefix[prefix].map({ $0 == tag.namespace }) ?? true else {
                return false
            }
            state.namespaceByPrefix[prefix] = tag.namespace
        }
        return insert(tag: tag, for: parsedPath, parent: parent, tags: &state.tags)
    }
}

private struct MetadataPath: Sendable {
    struct Name: Sendable {
        let prefix: String?
        let name: String
    }

    struct Component: Sendable {
        let prefix: String?
        let name: String
        let selector: String?
        let qualifier: Name?
    }

    let components: [Component]

    init(components: [Component]) {
        self.components = components
    }

    init?(_ source: String) {
        guard !source.isEmpty else { return nil }
        var parsed: [Component] = []
        for rawComponent in source.split(separator: ".", omittingEmptySubsequences: false) {
            var component = String(rawComponent)
            guard !component.isEmpty else { return nil }

            var qualifier: Name?
            if let marker = component.firstIndex(of: "?") {
                let qualifierSource = String(component[component.index(after: marker)...])
                guard let parsedQualifier = MetadataPath.parseName(qualifierSource) else { return nil }
                qualifier = parsedQualifier
                component = String(component[..<marker])
            }

            var selector: String?
            if component.hasSuffix("]"), let opening = component.lastIndex(of: "[") {
                let valueStart = component.index(after: opening)
                let valueEnd = component.index(before: component.endIndex)
                let value = String(component[valueStart..<valueEnd])
                guard !value.isEmpty else { return nil }
                selector = value
                component = String(component[..<opening])
            }

            guard let name = MetadataPath.parseName(component) else { return nil }
            parsed.append(Component(
                prefix: name.prefix,
                name: name.name,
                selector: selector,
                qualifier: qualifier
            ))
        }
        guard !parsed.isEmpty else { return nil }
        self.components = parsed
    }

    private static func parseName(_ source: String) -> Name? {
        let parts = source.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count <= 2, parts.allSatisfy({ isValidMetadataPrefix(String($0)) }) else {
            return nil
        }
        if parts.count == 2 {
            return Name(prefix: String(parts[0]), name: String(parts[1]))
        }
        return Name(prefix: nil, name: source)
    }
}

private func resolve(
    path: MetadataPath,
    in roots: [CGImageMetadataTag],
    parent: CGImageMetadataTag?
) -> CGImageMetadataTag? {
    var candidates = parent?.children ?? roots
    var current: CGImageMetadataTag?

    for (index, component) in path.components.enumerated() {
        guard let matched = candidates.first(where: {
            $0.name == component.name && (component.prefix == nil || $0.prefix == component.prefix)
        }) else { return nil }
        current = matched

        if let selector = component.selector {
            guard matched.type == .arrayOrdered ||
                    matched.type == .arrayUnordered ||
                    matched.type == .alternateArray ||
                    matched.type == .alternateText else { return nil }
            if let itemIndex = Int(selector) {
                guard itemIndex >= 0 && itemIndex < matched.children.count else { return nil }
                current = matched.children[itemIndex]
            } else {
                current = matched.children.first { item in
                    item.qualifiers.contains { qualifier in
                        qualifier.namespace == "http://www.w3.org/XML/1998/namespace" &&
                        qualifier.name == "lang" &&
                        (qualifier.value as? String) == selector
                    }
                }
                guard current != nil else { return nil }
            }
        }

        if let qualifier = component.qualifier {
            guard current?.type == .default || current?.type == .string else { return nil }
            guard let resolved = current?.qualifiers.first(where: {
                $0.name == qualifier.name && (qualifier.prefix == nil || $0.prefix == qualifier.prefix)
            }) else { return nil }
            current = resolved
        }

        if index < path.components.count - 1 {
            guard let current else { return nil }
            candidates = current.children
        }
    }
    return current
}

private func insert(
    tag: CGImageMetadataTag,
    for path: MetadataPath,
    parent: CGImageMetadataTag?,
    tags: inout [CGImageMetadataTag]
) -> Bool {
    if parent == nil && path.components.count == 1 {
        tags.append(tag)
        return true
    }

    let destinationParent: CGImageMetadataTag?
    if let parent {
        guard path.components.count == 1 else { return false }
        destinationParent = parent
    } else {
        let parentComponents = Array(path.components.dropLast())
        guard !parentComponents.isEmpty else { return false }
        destinationParent = resolve(
            path: MetadataPath(components: parentComponents),
            in: tags,
            parent: nil
        )
    }
    guard let destinationParent,
          destinationParent.type == .structure else { return false }
    let replacement = rebuilt(
        destinationParent,
        children: destinationParent.children + [tag],
        qualifiers: destinationParent.qualifiers
    )
    return replaceTag(in: &tags, target: destinationParent, replacement: replacement)
}

private func tagByReplacingValue(
    _ tag: CGImageMetadataTag,
    value: Any,
    namespaceByPrefix: [String: String]
) -> CGImageMetadataTag? {
    let children: [CGImageMetadataTag]
    switch tag.type {
    case .invalid:
        return nil
    case .default, .string:
        guard isMetadataScalar(value) else { return nil }
        children = []
    case .arrayUnordered, .arrayOrdered, .alternateArray, .alternateText:
        guard let values = value as? [Any], values.allSatisfy(isMetadataScalar) else { return nil }
        children = values.enumerated().map { index, item in
            let existingItem = index < tag.children.count ? tag.children[index] : nil
            return CGImageMetadataTag(
                namespace: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                prefix: "rdf",
                name: "li",
                type: .string,
                value: item,
                qualifiers: existingItem?.qualifiers ?? []
            )
        }
    case .structure:
        guard let dictionary = value as? [String: Any] else { return nil }
        var newChildren: [CGImageMetadataTag] = []
        for key in dictionary.keys.sorted() {
            guard let childValue = dictionary[key], isMetadataScalar(childValue) else { return nil }
            let nameParts = key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let childPrefix: String?
            let childName: String
            let childNamespace: String
            if nameParts.count == 2 {
                childPrefix = String(nameParts[0])
                childName = String(nameParts[1])
                guard let childPrefix,
                      let namespace = namespaceByPrefix[childPrefix] else { return nil }
                childNamespace = namespace
            } else {
                childPrefix = tag.children.first(where: { $0.name == key })?.prefix ?? tag.prefix
                childName = key
                childNamespace = childPrefix.flatMap { namespaceByPrefix[$0] } ?? tag.namespace
            }
            guard !childName.isEmpty else { return nil }
            newChildren.append(CGImageMetadataTag(
                namespace: childNamespace,
                prefix: childPrefix,
                name: childName,
                type: .string,
                value: childValue
            ))
        }
        children = newChildren
    }
    return CGImageMetadataTag(
        namespace: tag.namespace,
        prefix: tag.prefix,
        name: tag.name,
        type: tag.type,
        value: value,
        qualifiers: tag.qualifiers,
        children: children
    )
}

private func isMetadataScalar(_ value: Any) -> Bool {
    switch value {
    case is String, is Bool,
         is Int, is Int8, is Int16, is Int32, is Int64,
         is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
         is Float, is Double:
        return true
    default:
        return false
    }
}

private func replaceTag(
    in tags: inout [CGImageMetadataTag],
    target: CGImageMetadataTag,
    replacement: CGImageMetadataTag
) -> Bool {
    for index in tags.indices {
        if tags[index] === target {
            tags[index] = replacement
            return true
        }
        if let rebuilt = replacingDescendant(in: tags[index], target: target, replacement: replacement) {
            tags[index] = rebuilt
            return true
        }
    }
    return false
}

private func replacingDescendant(
    in tag: CGImageMetadataTag,
    target: CGImageMetadataTag,
    replacement: CGImageMetadataTag
) -> CGImageMetadataTag? {
    var children = tag.children
    if replaceTag(in: &children, target: target, replacement: replacement) {
        return rebuilt(tag, children: children, qualifiers: tag.qualifiers)
    }
    var qualifiers = tag.qualifiers
    if replaceTag(in: &qualifiers, target: target, replacement: replacement) {
        return rebuilt(tag, children: tag.children, qualifiers: qualifiers)
    }
    return nil
}

private func removeTag(
    from tags: inout [CGImageMetadataTag],
    target: CGImageMetadataTag
) -> Bool {
    if let index = tags.firstIndex(where: { $0 === target }) {
        tags.remove(at: index)
        return true
    }
    for index in tags.indices {
        var children = tags[index].children
        if removeTag(from: &children, target: target) {
            tags[index] = rebuilt(tags[index], children: children, qualifiers: tags[index].qualifiers)
            return true
        }
        var qualifiers = tags[index].qualifiers
        if removeTag(from: &qualifiers, target: target) {
            tags[index] = rebuilt(tags[index], children: tags[index].children, qualifiers: qualifiers)
            return true
        }
    }
    return false
}

private func rebuilt(
    _ tag: CGImageMetadataTag,
    children: [CGImageMetadataTag],
    qualifiers: [CGImageMetadataTag]
) -> CGImageMetadataTag {
    let value: Any?
    switch tag.type {
    case .arrayUnordered, .arrayOrdered, .alternateArray, .alternateText:
        value = children.compactMap(\.value)
    case .structure:
        var dictionary: [String: Any] = [:]
        for child in children {
            if let childValue = child.value {
                dictionary[qualifiedName(for: child)] = childValue
            }
        }
        value = dictionary
    default:
        value = tag.value
    }
    return CGImageMetadataTag(
        namespace: tag.namespace,
        prefix: tag.prefix,
        name: tag.name,
        type: tag.type,
        value: value,
        qualifiers: qualifiers,
        children: children
    )
}

private func enumerate(
    tag: CGImageMetadataTag,
    path: String,
    recursive: Bool,
    block: CGImageMetadataTagBlock
) -> Bool {
    guard block(path, tag) else { return false }
    guard recursive else { return true }

    for qualifier in tag.qualifiers {
        let qualifierPath = "\(path)?\(qualifiedName(for: qualifier))"
        guard enumerate(tag: qualifier, path: qualifierPath, recursive: true, block: block) else {
            return false
        }
    }
    for (index, child) in tag.children.enumerated() {
        let childPath: String
        if tag.type == .alternateText,
           let language = child.qualifiers.first(where: {
               $0.namespace == "http://www.w3.org/XML/1998/namespace" && $0.name == "lang"
           })?.value as? String {
            childPath = "\(path)[\(language)]"
        } else if tag.type == .arrayOrdered ||
                    tag.type == .arrayUnordered ||
                    tag.type == .alternateArray {
            childPath = "\(path)[\(index)]"
        } else {
            childPath = "\(path).\(qualifiedName(for: child))"
        }
        guard enumerate(tag: child, path: childPath, recursive: true, block: block) else {
            return false
        }
    }
    return true
}

private func qualifiedName(for tag: CGImageMetadataTag) -> String {
    guard let prefix = tag.prefix, !prefix.isEmpty else { return tag.name }
    return "\(prefix):\(tag.name)"
}

private func isValidMetadataPrefix(_ prefix: String) -> Bool {
    guard let first = prefix.first,
          first == "_" || first.isLetter else { return false }
    return prefix.dropFirst().allSatisfy { character in
        character == "_" || character == "-" || character == "." || character.isLetter || character.isNumber
    }
}

private func isValidMetadataNamespace(_ namespace: String) -> Bool {
    guard !namespace.isEmpty,
          !namespace.contains(where: { $0.isWhitespace || $0 == "<" || $0 == ">" || $0 == "\"" }) else {
        return false
    }
    return namespace.contains(":")
}

private func metadataError(
    _ code: CGImageMetadataErrors,
    description: String
) -> Error {
    NSError(
        domain: kCFErrorDomainCGImageMetadata,
        code: Int(code.rawValue),
        userInfo: [NSLocalizedDescriptionKey: description]
    )
}
