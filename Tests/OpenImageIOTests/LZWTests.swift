// LZWTests.swift
// OpenImageIO Tests
//
// Regression tests for `LZW.decode(data:minCodeSize:)`. Specifically covers
// the truncation-handling path: a stream that ends without an explicit end
// code must decode to nil (not return partial output), otherwise corrupted
// GIFs silently produce garbage.

import Testing
import Foundation
@testable import OpenImageIO

@Suite("LZW Roundtrip & Truncation")
struct LZWTests {

    /// Round-trip of a small byte sequence with `minCodeSize: 8`. Verifies the
    /// encoder and decoder agree and that the full input survives
    /// compress/decompress.
    @Test("Round-trip 0..<16 with minCodeSize 8")
    func roundtripSmallSequence() throws {
        let original = Data((0..<16).map { UInt8($0) })

        let encoded = try #require(
            LZW.encode(data: original, minCodeSize: 8),
            "Encoder must succeed for valid input"
        )
        let decoded = try #require(
            LZW.decode(data: encoded, minCodeSize: 8),
            "Decoder must succeed for well-formed stream"
        )

        #expect(decoded == original, "Round-trip must preserve bytes")
    }

    @Test("Code-width transitions and dictionary reset round-trip")
    func codeWidthTransitionsRoundTrip() throws {
        let input = Data((0..<16_384).map { UInt8(truncatingIfNeeded: ($0 * 73) ^ ($0 >> 3)) })
        let encoded = try #require(LZW.encode(data: input, minCodeSize: 8))
        let decoded = try #require(LZW.decode(data: encoded, minCodeSize: 8))
        #expect(decoded == input)
    }

    /// A correctly-terminated short stream decodes fine. Regression guard for
    /// the `sawEndCode` check in `LZWDecoder.decode` — a valid short stream
    /// must not be rejected as truncated.
    @Test("Correctly terminated short stream decodes fine")
    func shortStreamDecodesSuccessfully() throws {
        let original = Data([42, 7, 99])

        let encoded = try #require(
            LZW.encode(data: original, minCodeSize: 8),
            "Encoder must succeed for valid input"
        )
        let decoded = try #require(
            LZW.decode(data: encoded, minCodeSize: 8),
            "Short but terminated stream must decode"
        )

        #expect(decoded == original)
    }

    /// Truncate the encoded stream by dropping the last byte (which carries
    /// the end code in the tail). The decoder must return nil, not partial
    /// output — this is the behaviour the `sawEndCode` guard exists to
    /// enforce.
    @Test("Truncation by 1 byte yields nil from decoder")
    func truncationByOneByteReturnsNil() throws {
        let original = Data((0..<16).map { UInt8($0) })
        let encoded = try #require(LZW.encode(data: original, minCodeSize: 8))
        try #require(encoded.count >= 2, "Encoded stream should be long enough to truncate")

        let truncated = encoded.dropLast(1)
        let decoded = LZW.decode(data: Data(truncated), minCodeSize: 8)

        #expect(decoded == nil, "Decoder must report truncation as nil, not partial output")
    }

    /// Drop the last two bytes of the encoded stream. Same contract: the
    /// decoder must not silently return partial bytes.
    @Test("Truncation by 2 bytes yields nil from decoder")
    func truncationByTwoBytesReturnsNil() throws {
        let original = Data((0..<16).map { UInt8($0) })
        let encoded = try #require(LZW.encode(data: original, minCodeSize: 8))
        try #require(encoded.count >= 3, "Encoded stream should be long enough to truncate")

        let truncated = encoded.dropLast(2)
        let decoded = LZW.decode(data: Data(truncated), minCodeSize: 8)

        #expect(decoded == nil, "Decoder must report truncation as nil, not partial output")
    }
}
