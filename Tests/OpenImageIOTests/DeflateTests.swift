import Foundation
import Testing
@testable import OpenImageIO

@Suite("DEFLATE Conformance and Failure Handling")
struct DeflateTests {
    @Test("Stored and fixed blocks round-trip empty and large payloads")
    func storedAndFixedRoundTrip() throws {
        let payloads = [
            Data(),
            Data((0..<131_072).map { UInt8(truncatingIfNeeded: ($0 * 31) ^ ($0 >> 5)) }),
        ]

        for payload in payloads {
            for level in [0, 6] {
                let encoded = try #require(Deflate.deflate(data: payload, level: level))
                let decoded = try #require(Deflate.inflate(data: encoded))
                #expect(decoded == payload)
            }
        }
    }

    @Test("Independent dynamic-Huffman zlib stream decodes")
    func dynamicHuffmanFixture() throws {
        let compressed = Data([
            0x78, 0x9C, 0x05, 0xC1, 0x01, 0x0A, 0x80, 0x20,
            0x0C, 0x40, 0xD1, 0x2B, 0x05, 0x45, 0xCB, 0xE3,
            0xFC, 0x39, 0x0B, 0x84, 0x12, 0x93, 0xA9, 0x74,
            0xFA, 0xDE, 0x8B, 0x4F, 0x66, 0xD0, 0x03, 0x48,
            0xCA, 0xB0, 0x94, 0xBA, 0x72, 0xD9, 0xA9, 0xE9,
            0xB8, 0x3D, 0x2A, 0x36, 0x5C, 0x09, 0xA2, 0xE0,
            0x9E, 0x3E, 0x84, 0x82, 0x29, 0x53, 0x5B, 0xCC,
            0x6C, 0xD3, 0xD0, 0x0D, 0x7D, 0x99, 0xD2, 0x2A,
            0xB2, 0xD3, 0x8B, 0xFC, 0xC1, 0x93, 0x1D, 0xE0,
        ])
        let expected = Data("cnjawav9aa7ejaa0oq3agdfbe8mucbadwuba97baauueza7aoadbaxbscja4xdab4abrax7sqa76avo7".utf8)

        #expect(try #require(Deflate.inflate(data: compressed)) == expected)
    }

    @Test("Missing or mismatched Adler-32 checksum is rejected")
    func checksumFailureIsRejected() throws {
        let encoded = try #require(Deflate.deflate(data: Data("checksum".utf8)))
        #expect(Deflate.inflate(data: Data(encoded.dropLast(1))) == nil)

        var corrupted = encoded
        corrupted[corrupted.index(before: corrupted.endIndex)] ^= 0xFF
        #expect(Deflate.inflate(data: corrupted) == nil)
    }

    @Test("Raw inflater rejects offsets outside the input")
    func rawOffsetValidation() {
        #expect(Deflate.inflateRaw(data: Data([0x03, 0x00]), offset: -1) == nil)
        #expect(Deflate.inflateRaw(data: Data([0x03, 0x00]), offset: 3) == nil)
    }
}
