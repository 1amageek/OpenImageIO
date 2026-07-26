// XMPCodec.swift
// OpenImageIO

@preconcurrency import Foundation

internal enum XMPCodec {
    private static let rdfNamespace = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    private static let xmlNamespace = "http://www.w3.org/XML/1998/namespace"

    internal struct DecodedMetadata {
        let tags: [CGImageMetadataTag]
        let namespaces: [String: String]
    }

    private struct Attribute {
        let name: String
        let value: String
    }

    private struct Node {
        let name: String
        let attributes: [Attribute]
        let children: [Node]
        let text: String
        let namespaces: [String: String]

        var localName: String {
            XMPCodec.qualifiedName(name).localName
        }

        var prefix: String? {
            XMPCodec.qualifiedName(name).prefix
        }

        var namespace: String? {
            guard let prefix else { return namespaces[""] }
            return namespaces[prefix]
        }
    }

    private enum ParseError: Error {
        case malformedXML
        case invalidEntity
    }

    internal static func decode(_ data: Data) -> DecodedMetadata? {
        guard let source = String(data: data, encoding: .utf8) else { return nil }

        do {
            var parser = XMLTreeParser(source: source)
            let root = try parser.parseDocument()
            let descriptions = descendants(of: root).filter {
                $0.namespace == rdfNamespace && $0.localName == "Description"
            }
            guard !descriptions.isEmpty else { return nil }

            var decodedTags: [CGImageMetadataTag] = []
            var namespaces = root.namespaces
            for description in descriptions {
                decodedTags.append(contentsOf: try tags(from: description))
                namespaces.merge(description.namespaces) { _, nested in nested }
            }
            return DecodedMetadata(tags: decodedTags, namespaces: namespaces)
        } catch {
            return nil
        }
    }

    internal static func encode(
        tags: [CGImageMetadataTag],
        namespaces registeredNamespaces: [String: String]
    ) -> Data? {
        var namespaces = registeredNamespaces
        namespaces["rdf"] = rdfNamespace
        namespaces["x"] = "adobe:ns:meta/"
        collectNamespaces(from: tags, into: &namespaces)

        var declarations = ""
        for prefix in namespaces.keys.sorted() where !prefix.isEmpty && prefix != "xml" {
            guard let namespace = namespaces[prefix],
                  isValidXMLName(prefix) else { return nil }
            declarations += " xmlns:\(prefix)=\"\(escapeAttribute(namespace))\""
        }

        var body = ""
        for tag in tags {
            guard let encoded = encode(tag: tag, namespaces: namespaces) else { return nil }
            body += encoded
        }

        let packet = """
        <?xpacket begin='\u{feff}' id='W5M0MpCehiHzreSzNTczkc9d'?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="\(rdfNamespace)">
        <rdf:Description rdf:about=""\(declarations)>
        \(body)</rdf:Description>
        </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end='w'?>
        """
        return packet.data(using: .utf8)
    }

    private static func tags(from description: Node) throws -> [CGImageMetadataTag] {
        var result: [CGImageMetadataTag] = []

        for attribute in description.attributes {
            let name = qualifiedName(attribute.name)
            guard name.prefix != "xmlns", attribute.name != "xmlns" else { continue }
            guard let prefix = name.prefix,
                  prefix != "rdf",
                  prefix != "xml",
                  let namespace = description.namespaces[prefix] else { continue }
            result.append(CGImageMetadataTag(
                namespace: namespace,
                prefix: prefix,
                name: name.localName,
                type: .string,
                value: attribute.value
            ))
        }

        for child in description.children {
            guard child.namespace != rdfNamespace else { continue }
            result.append(try tag(from: child))
        }
        return result
    }

    private static func tag(from node: Node) throws -> CGImageMetadataTag {
        guard let namespace = node.namespace, !namespace.isEmpty else {
            throw ParseError.malformedXML
        }

        let qualifiers = try qualifierTags(from: node)
        if node.children.count == 1,
           let container = node.children.first,
           container.namespace == rdfNamespace,
           ["Bag", "Seq", "Alt"].contains(container.localName) {
            let itemNodes = container.children.filter {
                $0.namespace == rdfNamespace && $0.localName == "li"
            }
            guard itemNodes.count == container.children.count else {
                throw ParseError.malformedXML
            }

            let itemTags = try itemNodes.map { try arrayItemTag(from: $0) }
            let values = itemTags.compactMap(\.value)
            let type: CGImageMetadataType
            switch container.localName {
            case "Bag":
                type = .arrayUnordered
            case "Seq":
                type = .arrayOrdered
            default:
                let isLocalized = itemTags.contains { item in
                    item.qualifiers.contains { $0.namespace == xmlNamespace && $0.name == "lang" }
                }
                type = isLocalized ? .alternateText : .alternateArray
            }
            return CGImageMetadataTag(
                namespace: namespace,
                prefix: node.prefix,
                name: node.localName,
                type: type,
                value: values,
                qualifiers: qualifiers,
                children: itemTags
            )
        }

        let structuralChildren = structureChildren(from: node)
        if !structuralChildren.isEmpty {
            let children = try structuralChildren.map { try tag(from: $0) }
            var dictionary: [String: Any] = [:]
            for child in children {
                dictionary[qualifiedPathName(for: child)] = child.value
            }
            return CGImageMetadataTag(
                namespace: namespace,
                prefix: node.prefix,
                name: node.localName,
                type: .structure,
                value: dictionary,
                qualifiers: qualifiers,
                children: children
            )
        }

        guard node.children.isEmpty else { throw ParseError.malformedXML }
        return CGImageMetadataTag(
            namespace: namespace,
            prefix: node.prefix,
            name: node.localName,
            type: .string,
            value: node.text.trimmingCharacters(in: .whitespacesAndNewlines),
            qualifiers: qualifiers
        )
    }

    private static func arrayItemTag(from node: Node) throws -> CGImageMetadataTag {
        let qualifiers = try qualifierTags(from: node)
        let structuralChildren = structureChildren(from: node)
        if !structuralChildren.isEmpty {
            let children = try structuralChildren.map { try tag(from: $0) }
            var dictionary: [String: Any] = [:]
            for child in children {
                dictionary[qualifiedPathName(for: child)] = child.value
            }
            return CGImageMetadataTag(
                namespace: rdfNamespace,
                prefix: "rdf",
                name: "li",
                type: .structure,
                value: dictionary,
                qualifiers: qualifiers,
                children: children
            )
        }
        guard node.children.isEmpty else { throw ParseError.malformedXML }
        return CGImageMetadataTag(
            namespace: rdfNamespace,
            prefix: "rdf",
            name: "li",
            type: .string,
            value: node.text.trimmingCharacters(in: .whitespacesAndNewlines),
            qualifiers: qualifiers
        )
    }

    private static func structureChildren(from node: Node) -> [Node] {
        if node.children.count == 1,
           let description = node.children.first,
           description.namespace == rdfNamespace,
           description.localName == "Description" {
            return description.children.filter { $0.namespace != rdfNamespace }
        }
        return node.children.filter { $0.namespace != rdfNamespace }
    }

    private static func qualifierTags(from node: Node) throws -> [CGImageMetadataTag] {
        var result: [CGImageMetadataTag] = []
        for attribute in node.attributes {
            let name = qualifiedName(attribute.name)
            guard name.prefix != "xmlns", attribute.name != "xmlns" else { continue }
            guard let prefix = name.prefix else { continue }
            if prefix == "rdf" && ["about", "parseType", "resource"].contains(name.localName) {
                continue
            }
            let namespace: String
            if prefix == "xml" {
                namespace = xmlNamespace
            } else if let resolved = node.namespaces[prefix] {
                namespace = resolved
            } else {
                throw ParseError.malformedXML
            }
            result.append(CGImageMetadataTag(
                namespace: namespace,
                prefix: prefix,
                name: name.localName,
                type: .string,
                value: attribute.value
            ))
        }
        return result
    }

    private static func descendants(of node: Node) -> [Node] {
        [node] + node.children.flatMap(descendants(of:))
    }

    private static func collectNamespaces(
        from tags: [CGImageMetadataTag],
        into namespaces: inout [String: String]
    ) {
        for tag in tags {
            if let prefix = tag.prefix, !prefix.isEmpty {
                namespaces[prefix] = tag.namespace
            }
            collectNamespaces(from: tag.qualifiers, into: &namespaces)
            collectNamespaces(from: tag.children, into: &namespaces)
        }
    }

    private static func encode(
        tag: CGImageMetadataTag,
        namespaces: [String: String]
    ) -> String? {
        guard let qualifiedName = serializedName(for: tag, namespaces: namespaces) else { return nil }
        guard let qualifierAttributes = encodeQualifiers(tag.qualifiers, namespaces: namespaces) else {
            return nil
        }

        switch tag.type {
        case .invalid:
            return nil
        case .default, .string:
            guard let value = scalarString(tag.value) else { return nil }
            return "<\(qualifiedName)\(qualifierAttributes)>\(escapeText(value))</\(qualifiedName)>\n"
        case .arrayUnordered, .arrayOrdered, .alternateArray, .alternateText:
            let containerName: String
            switch tag.type {
            case .arrayUnordered: containerName = "rdf:Bag"
            case .arrayOrdered: containerName = "rdf:Seq"
            default: containerName = "rdf:Alt"
            }
            let values: [Any]
            if !tag.children.isEmpty {
                values = tag.children.map(\.value)
            } else if let array = tag.value as? [Any] {
                values = array
            } else {
                return nil
            }
            var items = ""
            for (index, value) in values.enumerated() {
                let item = index < tag.children.count ? tag.children[index] : nil
                let itemQualifiers = item?.qualifiers ?? []
                guard let attributes = encodeQualifiers(itemQualifiers, namespaces: namespaces) else {
                    return nil
                }
                if let scalar = scalarString(value) {
                    items += "<rdf:li\(attributes)>\(escapeText(scalar))</rdf:li>\n"
                } else if let dictionary = value as? [String: Any],
                          let structure = encodeStructure(dictionary, children: item?.children ?? [], namespaces: namespaces) {
                    items += "<rdf:li\(attributes) rdf:parseType=\"Resource\">\(structure)</rdf:li>\n"
                } else {
                    return nil
                }
            }
            return "<\(qualifiedName)\(qualifierAttributes)><\(containerName)>\n\(items)</\(containerName)></\(qualifiedName)>\n"
        case .structure:
            guard let dictionary = tag.value as? [String: Any],
                  let structure = encodeStructure(dictionary, children: tag.children, namespaces: namespaces) else {
                return nil
            }
            return "<\(qualifiedName)\(qualifierAttributes) rdf:parseType=\"Resource\">\(structure)</\(qualifiedName)>\n"
        }
    }

    private static func encodeStructure(
        _ dictionary: [String: Any],
        children: [CGImageMetadataTag],
        namespaces: [String: String]
    ) -> String? {
        if !children.isEmpty {
            var result = ""
            for child in children {
                guard let encoded = encode(tag: child, namespaces: namespaces) else { return nil }
                result += encoded
            }
            return result
        }

        var result = ""
        for key in dictionary.keys.sorted() {
            let components = key.split(separator: ":", maxSplits: 1).map(String.init)
            guard components.count == 2,
                  isValidXMLName(components[0]),
                  isValidXMLName(components[1]),
                  namespaces[components[0]] != nil,
                  let value = dictionary[key],
                  let scalar = scalarString(value) else { return nil }
            result += "<\(key)>\(escapeText(scalar))</\(key)>\n"
        }
        return result
    }

    private static func encodeQualifiers(
        _ qualifiers: [CGImageMetadataTag],
        namespaces: [String: String]
    ) -> String? {
        var result = ""
        for qualifier in qualifiers {
            guard let name = serializedName(for: qualifier, namespaces: namespaces),
                  let value = scalarString(qualifier.value) else { return nil }
            result += " \(name)=\"\(escapeAttribute(value))\""
        }
        return result
    }

    private static func serializedName(
        for tag: CGImageMetadataTag,
        namespaces: [String: String]
    ) -> String? {
        guard isValidXMLName(tag.name) else { return nil }
        if let prefix = tag.prefix, !prefix.isEmpty {
            guard isValidXMLName(prefix), namespaces[prefix] == tag.namespace else { return nil }
            return "\(prefix):\(tag.name)"
        }
        guard let prefix = namespaces.first(where: { $0.value == tag.namespace && !$0.key.isEmpty })?.key,
              isValidXMLName(prefix) else { return nil }
        return "\(prefix):\(tag.name)"
    }

    private static func scalarString(_ value: Any?) -> String? {
        switch value {
        case let string as String: return string
        case let value as Bool: return value ? "true" : "false"
        case let value as Int: return String(value)
        case let value as Int8: return String(value)
        case let value as Int16: return String(value)
        case let value as Int32: return String(value)
        case let value as Int64: return String(value)
        case let value as UInt: return String(value)
        case let value as UInt8: return String(value)
        case let value as UInt16: return String(value)
        case let value as UInt32: return String(value)
        case let value as UInt64: return String(value)
        case let value as Float: return String(value)
        case let value as Double: return String(value)
        default: return nil
        }
    }

    private static func qualifiedPathName(for tag: CGImageMetadataTag) -> String {
        guard let prefix = tag.prefix, !prefix.isEmpty else { return tag.name }
        return "\(prefix):\(tag.name)"
    }

    private static func qualifiedName(_ name: String) -> (prefix: String?, localName: String) {
        let components = name.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if components.count == 2 {
            return (String(components[0]), String(components[1]))
        }
        return (nil, name)
    }

    private static func isValidXMLName(_ name: String) -> Bool {
        guard let first = name.first,
              first == "_" || first.isLetter else { return false }
        return name.dropFirst().allSatisfy { character in
            character == "_" || character == "-" || character == "." || character.isLetter || character.isNumber
        }
    }

    private static func escapeText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func escapeAttribute(_ value: String) -> String {
        escapeText(value)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private struct XMLTreeParser {
        private let characters: [Character]
        private var index: Int = 0

        init(source: String) {
            self.characters = Array(source)
        }

        mutating func parseDocument() throws -> Node {
            try skipMiscellaneous()
            let root = try parseElement(inheritedNamespaces: [
                "xml": XMPCodec.xmlNamespace,
                "rdf": XMPCodec.rdfNamespace
            ])
            try skipMiscellaneous()
            guard index == characters.count else { throw ParseError.malformedXML }
            return root
        }

        private mutating func parseElement(inheritedNamespaces: [String: String]) throws -> Node {
            guard consume("<"), !hasPrefix("/"), !hasPrefix("!"), !hasPrefix("?") else {
                throw ParseError.malformedXML
            }
            let name = try readName()
            var attributes: [Attribute] = []
            var namespaces = inheritedNamespaces

            while true {
                skipWhitespace()
                if consume("/>") {
                    applyNamespaceDeclarations(attributes, to: &namespaces)
                    return Node(name: name, attributes: attributes, children: [], text: "", namespaces: namespaces)
                }
                if consume(">") { break }
                let attributeName = try readName()
                skipWhitespace()
                guard consume("=") else { throw ParseError.malformedXML }
                skipWhitespace()
                let value = try readQuotedValue()
                guard !attributes.contains(where: { $0.name == attributeName }) else {
                    throw ParseError.malformedXML
                }
                attributes.append(Attribute(name: attributeName, value: value))
            }

            applyNamespaceDeclarations(attributes, to: &namespaces)
            var children: [Node] = []
            var text = ""

            while index < characters.count {
                if consume("</") {
                    let closingName = try readName()
                    skipWhitespace()
                    guard closingName == name, consume(">") else { throw ParseError.malformedXML }
                    return Node(
                        name: name,
                        attributes: attributes,
                        children: children,
                        text: try decodeEntities(text),
                        namespaces: namespaces
                    )
                }
                if hasPrefix("<!--") {
                    try skipComment()
                    continue
                }
                if hasPrefix("<?") {
                    try skipProcessingInstruction()
                    continue
                }
                if consume("<![CDATA[") {
                    text += try readUntil("]]>").replacingOccurrences(of: "&", with: "&amp;")
                    continue
                }
                if hasPrefix("<!") { throw ParseError.malformedXML }
                if hasPrefix("<") {
                    children.append(try parseElement(inheritedNamespaces: namespaces))
                } else {
                    text += readText()
                }
            }
            throw ParseError.malformedXML
        }

        private mutating func skipMiscellaneous() throws {
            while true {
                skipWhitespace()
                if hasPrefix("<?") {
                    try skipProcessingInstruction()
                } else if hasPrefix("<!--") {
                    try skipComment()
                } else {
                    return
                }
            }
        }

        private mutating func skipProcessingInstruction() throws {
            guard consume("<?") else { throw ParseError.malformedXML }
            _ = try readUntil("?>")
        }

        private mutating func skipComment() throws {
            guard consume("<!--") else { throw ParseError.malformedXML }
            let contents = try readUntil("-->")
            guard !contents.contains("--") else { throw ParseError.malformedXML }
        }

        private mutating func readName() throws -> String {
            let start = index
            while index < characters.count {
                let character = characters[index]
                if character.isWhitespace || ["/", ">", "=", "?"].contains(character) {
                    break
                }
                index += 1
            }
            guard index > start else { throw ParseError.malformedXML }
            let name = String(characters[start..<index])
            let components = name.split(separator: ":", omittingEmptySubsequences: false)
            guard components.count <= 2,
                  components.allSatisfy({ XMPCodec.isValidXMLName(String($0)) }) else {
                throw ParseError.malformedXML
            }
            return name
        }

        private mutating func readQuotedValue() throws -> String {
            guard index < characters.count,
                  characters[index] == "\"" || characters[index] == "'" else {
                throw ParseError.malformedXML
            }
            let quote = characters[index]
            index += 1
            let start = index
            while index < characters.count && characters[index] != quote {
                guard characters[index] != "<" else { throw ParseError.malformedXML }
                index += 1
            }
            guard index < characters.count else { throw ParseError.malformedXML }
            let raw = String(characters[start..<index])
            index += 1
            return try decodeEntities(raw)
        }

        private mutating func readText() -> String {
            let start = index
            while index < characters.count && characters[index] != "<" {
                index += 1
            }
            return String(characters[start..<index])
        }

        private mutating func readUntil(_ terminator: String) throws -> String {
            let start = index
            while index < characters.count {
                if hasPrefix(terminator) {
                    let result = String(characters[start..<index])
                    index += terminator.count
                    return result
                }
                index += 1
            }
            throw ParseError.malformedXML
        }

        private mutating func applyNamespaceDeclarations(
            _ attributes: [Attribute],
            to namespaces: inout [String: String]
        ) {
            for attribute in attributes {
                if attribute.name == "xmlns" {
                    namespaces[""] = attribute.value
                } else if attribute.name.hasPrefix("xmlns:") {
                    namespaces[String(attribute.name.dropFirst("xmlns:".count))] = attribute.value
                }
            }
        }

        private mutating func skipWhitespace() {
            while index < characters.count && characters[index].isWhitespace {
                index += 1
            }
        }

        private func hasPrefix(_ literal: String) -> Bool {
            let candidate = Array(literal)
            guard index + candidate.count <= characters.count else { return false }
            return characters[index..<(index + candidate.count)].elementsEqual(candidate)
        }

        @discardableResult
        private mutating func consume(_ literal: String) -> Bool {
            guard hasPrefix(literal) else { return false }
            index += literal.count
            return true
        }

        private func decodeEntities(_ source: String) throws -> String {
            var result = ""
            let input = Array(source)
            var position = 0
            while position < input.count {
                guard input[position] == "&" else {
                    result.append(input[position])
                    position += 1
                    continue
                }
                guard let end = input[(position + 1)...].firstIndex(of: ";") else {
                    throw ParseError.invalidEntity
                }
                let entity = String(input[(position + 1)..<end])
                switch entity {
                case "amp": result.append("&")
                case "lt": result.append("<")
                case "gt": result.append(">")
                case "quot": result.append("\"")
                case "apos": result.append("'")
                default:
                    let scalarValue: UInt32?
                    if entity.hasPrefix("#x") {
                        scalarValue = UInt32(entity.dropFirst(2), radix: 16)
                    } else if entity.hasPrefix("#") {
                        scalarValue = UInt32(entity.dropFirst(), radix: 10)
                    } else {
                        scalarValue = nil
                    }
                    guard let scalarValue,
                          let scalar = UnicodeScalar(scalarValue) else {
                        throw ParseError.invalidEntity
                    }
                    result.unicodeScalars.append(scalar)
                }
                position = end + 1
            }
            return result
        }
    }
}
