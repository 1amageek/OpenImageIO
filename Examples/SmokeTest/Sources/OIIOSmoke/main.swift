// OpenImageIO WASM browser tests, authored as Swift Testing `@Test`
// functions that run inside headless Chromium via BrowserTestRunner.
//
// Boot flow (reactor-ABI):
//   1. `setup()` is exported to JS via `@_cdecl` + `--export=setup`.
//   2. `WasmTestingReactor.boot` installs the JavaScriptKit executor and
//      touches module-scope globals to avoid the reactor-ABI global-init
//      race (see MEMORY + ReactorBoot.swift for background).
//   3. `performSetup()` runs a minimal PNG roundtrip (encode a known
//      4x4 RGBA pattern, then decode it back) and stashes both the
//      encoded bytes and the decoded CGImage in module state.
//   4. `BrowserTestRunner.run()` spawns the Swift Testing ABI v0 entry
//      point. Each `@Test` function inspects the captured state.
//
// OpenImageIO's decoders/encoders are pure Swift — there's no WebGPU
// or JS dependency — but running them under wasm32 still validates the
// things that can only break in that target: Int-width wraparound,
// byte-order assumptions, and the reactor-ABI global-init race.

import Foundation
import Testing
import WasmTesting
import JavaScriptKit
import OpenImageIO
import OpenCoreGraphics

// MARK: - Captured result (populated by performSetup)

nonisolated(unsafe) var statusText: String = "initializing"
nonisolated(unsafe) var sourceImage: CGImage?
nonisolated(unsafe) var encodedPNG: Data?
nonisolated(unsafe) var decodedImage: CGImage?
nonisolated(unsafe) var browserWebPRejectedSafely = false

@_cdecl("setup")
public func setup() {
    WasmTestingReactor.boot(
        touchGlobals: {
            statusText = "initializing"
            sourceImage = nil
            encodedPNG = nil
            decodedImage = nil
            browserWebPRejectedSafely = false
        },
        then: {
            performSetup()
            BrowserTestRunner.run()
        }
    )
}

func performSetup() {
    // Build a 4x4 RGBA source: top-left 2x2 red, top-right 2x2 green,
    // bottom-left 2x2 blue, bottom-right 2x2 white. Chosen so the
    // @Test functions can assert on specific pixel positions without
    // worrying about filter-byte / row ordering ambiguity.
    let width = 4
    let height = 4
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * bytesPerRow + x * 4
            let quadrant = (y < 2 ? 0 : 2) + (x < 2 ? 0 : 1)
            switch quadrant {
            case 0: pixels[offset] = 255; pixels[offset + 1] = 0;   pixels[offset + 2] = 0   // red
            case 1: pixels[offset] = 0;   pixels[offset + 1] = 255; pixels[offset + 2] = 0   // green
            case 2: pixels[offset] = 0;   pixels[offset + 1] = 0;   pixels[offset + 2] = 255 // blue
            default: pixels[offset] = 255; pixels[offset + 1] = 255; pixels[offset + 2] = 255 // white
            }
            pixels[offset + 3] = 255
        }
    }

    guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
        statusText = "error: sRGB color space unavailable"
        return
    }
    let provider = CGDataProvider(data: Data(pixels))
    guard let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: space,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        statusText = "error: source CGImage init returned nil"
        return
    }
    sourceImage = image

    var encoded = Data()
    guard let destination = CGImageDestinationCreateWithData(&encoded, "public.png", 1, nil) else {
        statusText = "error: PNG destination init returned nil"
        return
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        statusText = "error: PNG finalize failed"
        return
    }
    guard let pngData = CGImageDestinationCopyData(destination) else {
        statusText = "error: PNG CopyData returned nil"
        return
    }
    encodedPNG = pngData

    guard let source = CGImageSourceCreateWithData(pngData, nil) else {
        statusText = "error: PNG source init returned nil"
        return
    }
    guard let roundtripped = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        statusText = "error: PNG decode returned nil"
        return
    }
    decodedImage = roundtripped

    guard let webPBase64 = JSObject.global["__oiio_webp_fixture_base64"].string,
          let webPData = Data(base64Encoded: webPBase64),
          let webPSource = CGImageSourceCreateWithData(webPData, nil) else {
        statusText = "error: browser-generated WebP source parsing failed"
        return
    }
    browserWebPRejectedSafely = CGImageSourceCreateImageAtIndex(webPSource, 0, nil) == nil

    let browserFormats: [(name: String, type: String, properties: [String: Any]?)] = [
        ("png", "public.png", nil),
        ("jpeg", "public.jpeg", [kCGImageDestinationLossyCompressionQuality: 0.9]),
        ("gif", "com.compuserve.gif", nil),
        ("bmp", "com.microsoft.bmp", nil),
    ]
    for format in browserFormats {
        var output = Data()
        guard let formatDestination = CGImageDestinationCreateWithData(
            &output,
            format.type,
            1,
            nil
        ) else {
            statusText = "error: \(format.name) destination init returned nil"
            return
        }
        CGImageDestinationAddImage(formatDestination, image, format.properties)
        guard CGImageDestinationFinalize(formatDestination),
              let formatData = CGImageDestinationCopyData(formatDestination) else {
            statusText = "error: \(format.name) encode failed"
            return
        }
        JSObject.global["__oiio_\(format.name)_base64"] = .string(formatData.base64EncodedString())
    }

    statusText = "ready"
    print("OIIOSmoke ready: encoded=\(pngData.count) bytes, decoded=\(roundtripped.width)x\(roundtripped.height)")
}

// MARK: - Tests
//
// These tests read captured state from performSetup(). The pipeline is
// write-once (no test mutates it), but we still use @Suite(.serialized)
// so a future mutation test would not race against the roundtrip
// assertions. See memory: feedback_wasm_testing_serialized_suite.md

@Suite(.serialized)
struct OIIOSmokeTests {

    @Test func captureSucceeded() throws {
        try #require(
            statusText == "ready",
            "performSetup did not complete cleanly: \(statusText)"
        )
        try #require(sourceImage != nil, "source image missing")
        try #require(encodedPNG != nil, "encoded PNG missing")
        try #require(decodedImage != nil, "decoded image missing")
        #expect(browserWebPRejectedSafely, "unsupported browser WebP input was not rejected safely")
    }

    @Test func encodedDataLooksLikePNG() throws {
        let data = try #require(encodedPNG)
        try #require(data.count >= 8, "encoded data too short (\(data.count) bytes)")
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        for (i, expected) in signature.enumerated() {
            #expect(data[i] == expected, "byte \(i): got \(data[i]), expected \(expected)")
        }
    }

    @Test func roundtripPreservesDimensions() throws {
        let decoded = try #require(decodedImage)
        #expect(decoded.width == 4)
        #expect(decoded.height == 4)
    }

    @Test func roundtripPreservesQuadrantColors() throws {
        let decoded = try #require(decodedImage)
        let data = try #require(decoded.data, "decoded image has no pixel data")
        let bpr = decoded.bytesPerRow
        let bpp = decoded.bitsPerPixel / 8
        #expect(bpp >= 3, "unexpected bits-per-pixel \(decoded.bitsPerPixel)")

        // Sample one pixel inside each 2x2 quadrant. Tolerate small drift
        // so a future change in the PNG encoder's alpha-premultiplication
        // path doesn't flake the assertion.
        func sample(x: Int, y: Int) -> (UInt8, UInt8, UInt8) {
            let offset = y * bpr + x * bpp
            return (data[offset], data[offset + 1], data[offset + 2])
        }

        let topLeft = sample(x: 0, y: 0)      // red
        let topRight = sample(x: 3, y: 0)     // green
        let bottomLeft = sample(x: 0, y: 3)   // blue
        let bottomRight = sample(x: 3, y: 3)  // white

        #expect(topLeft.0 > 200 && topLeft.1 < 40 && topLeft.2 < 40,
                "top-left not red: \(topLeft)")
        #expect(topRight.0 < 40 && topRight.1 > 200 && topRight.2 < 40,
                "top-right not green: \(topRight)")
        #expect(bottomLeft.0 < 40 && bottomLeft.1 < 40 && bottomLeft.2 > 200,
                "bottom-left not blue: \(bottomLeft)")
        #expect(bottomRight.0 > 200 && bottomRight.1 > 200 && bottomRight.2 > 200,
                "bottom-right not white: \(bottomRight)")
    }

    @Test func unsupportedBrowserWebPIsRejectedWithoutTrapping() {
        #expect(browserWebPRejectedSafely)
    }
}
