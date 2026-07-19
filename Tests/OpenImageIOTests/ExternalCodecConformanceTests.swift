import CoreFoundation
import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import OpenImageIO
import OpenCoreGraphics

@Suite("External Codec Conformance", .serialized)
struct ExternalCodecConformanceTests {
    @Test("OpenImageIO decodes PNG emitted by Apple ImageIO")
    func decodesApplePNG() throws {
        try assertDecodesAppleFormat("public.png")
    }

    @Test("OpenImageIO decodes JPEG emitted by Apple ImageIO")
    func decodesAppleJPEG() throws {
        try assertDecodesAppleFormat("public.jpeg")
    }

    @Test("OpenImageIO decodes GIF emitted by Apple ImageIO")
    func decodesAppleGIF() throws {
        try assertDecodesAppleFormat("com.compuserve.gif")
    }

    @Test("OpenImageIO decodes BMP emitted by Apple ImageIO")
    func decodesAppleBMP() throws {
        try assertDecodesAppleFormat("com.microsoft.bmp")
    }

    @Test("OpenImageIO decodes TIFF emitted by Apple ImageIO")
    func decodesAppleTIFF() throws {
        try assertDecodesAppleFormat("public.tiff")
    }

    private func assertDecodesAppleFormat(_ typeIdentifier: String) throws {
        let image = try makeAppleImage(width: 7, height: 5)
        let encoded = try encodeWithApple(image: image, typeIdentifier: typeIdentifier)
        let sourceCandidate = OpenImageIO.CGImageSourceCreateWithData(encoded, nil)
        let source = try #require(sourceCandidate, "OpenImageIO rejected Apple \(typeIdentifier)")
        #expect(OpenImageIO.CGImageSourceGetStatus(source) == .statusComplete)
        let decodedCandidate = OpenImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil)
        let decoded = try #require(
            decodedCandidate,
            "OpenImageIO could not decode Apple \(typeIdentifier)"
        )
        #expect(decoded.width == 7, "External width mismatch for \(typeIdentifier)")
        #expect(decoded.height == 5, "External height mismatch for \(typeIdentifier)")
    }

    @Test("Apple ImageIO decodes every advertised destination format")
    func appleImageIODecodesAdvertisedFormats() throws {
        let image = try makeImage(width: 7, height: 5)

        for typeIdentifier in CGImageDestinationCopyTypeIdentifiers() {
            let encoded = try encode(image: image, typeIdentifier: typeIdentifier)
            let sourceCandidate = ImageIO.CGImageSourceCreateWithData(encoded as CFData, nil)
            let source = try #require(
                sourceCandidate,
                "Apple ImageIO rejected \(typeIdentifier)"
            )
            let decodedCandidate = ImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil)
            let decoded = try #require(
                decodedCandidate,
                "Apple ImageIO could not decode \(typeIdentifier)"
            )

            #expect(decoded.width == 7, "External width mismatch for \(typeIdentifier)")
            #expect(decoded.height == 5, "External height mismatch for \(typeIdentifier)")
        }
    }

    @Test("Apple ImageIO decodes all pages of an encoded TIFF")
    func appleImageIODecodesMultiPageTIFF() throws {
        let sizes = [(4, 3), (5, 6), (8, 2)]
        let images = try sizes.map { try makeImage(width: $0.0, height: $0.1) }
        var storage = Data()
        let destinationCandidate = OpenImageIO.CGImageDestinationCreateWithData(
            &storage,
            "public.tiff",
            images.count,
            nil
        )
        let destination = try #require(destinationCandidate)
        for image in images {
            OpenImageIO.CGImageDestinationAddImage(destination, image, nil)
        }
        let finalized = OpenImageIO.CGImageDestinationFinalize(destination)
        #expect(finalized)

        let encodedCandidate = OpenImageIO.CGImageDestinationCopyData(destination)
        let encoded = try #require(encodedCandidate)
        let sourceCandidate = ImageIO.CGImageSourceCreateWithData(encoded as CFData, nil)
        let source = try #require(sourceCandidate)
        let pageCount = ImageIO.CGImageSourceGetCount(source)
        #expect(pageCount == images.count)

        for (index, size) in sizes.enumerated() {
            let decodedCandidate = ImageIO.CGImageSourceCreateImageAtIndex(source, index, nil)
            let decoded = try #require(decodedCandidate)
            #expect(decoded.width == size.0)
            #expect(decoded.height == size.1)
        }
    }

    @Test("Apple ImageIO decodes alpha-bearing BITMAPV5 output")
    func appleImageIODecodesAlphaBMP() throws {
        let pixels: [UInt8] = [
            128, 0, 0, 128,
            0, 0, 255, 255,
        ]
        let provider = OpenCoreGraphics.CGDataProvider(data: Data(pixels))
        let colorSpaceCandidate = OpenCoreGraphics.CGColorSpace(
            name: OpenCoreGraphics.CGColorSpace.sRGB
        )
        let colorSpace = try #require(colorSpaceCandidate)
        let imageCandidate = OpenCoreGraphics.CGImage(
            width: 2,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 8,
            space: colorSpace,
            bitmapInfo: OpenCoreGraphics.CGBitmapInfo(
                rawValue: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        let image = try #require(imageCandidate)

        let encoded = try encode(image: image, typeIdentifier: "com.microsoft.bmp")
        #expect(encoded[14] == 124)
        #expect(encoded[28] == 32)
        let sourceCandidate = ImageIO.CGImageSourceCreateWithData(encoded as CFData, nil)
        let source = try #require(sourceCandidate)
        let decodedCandidate = ImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil)
        let decoded = try #require(decodedCandidate)
        #expect(decoded.width == 2)
        #expect(decoded.height == 1)
    }

    @Test("Apple ImageIO parses XMP serialized by OpenImageIO")
    func appleImageIOParsesSerializedXMP() throws {
        let metadata = OpenImageIO.CGImageMetadataCreateMutable()
        let didSetTitle = OpenImageIO.CGImageMetadataSetValueWithPath(
            metadata,
            nil,
            "dc:title",
            "External & <validated>"
        )
        #expect(didSetTitle)
        let encodedCandidate = OpenImageIO.CGImageMetadataCreateXMPData(metadata, nil)
        let encoded = try #require(encodedCandidate)
        let appleMetadataCandidate = ImageIO.CGImageMetadataCreateFromXMPData(encoded as CFData)
        let appleMetadata = try #require(appleMetadataCandidate)
        let value = ImageIO.CGImageMetadataCopyStringValueWithPath(
            appleMetadata,
            nil,
            "dc:title" as CFString
        )
        #expect(value as String? == "External & <validated>")
    }

    private func encode(image: OpenCoreGraphics.CGImage, typeIdentifier: String) throws -> Data {
        var storage = Data()
        let destinationCandidate = OpenImageIO.CGImageDestinationCreateWithData(
            &storage,
            typeIdentifier,
            1,
            nil
        )
        let destination = try #require(destinationCandidate)
        OpenImageIO.CGImageDestinationAddImage(destination, image, nil)
        let finalized = OpenImageIO.CGImageDestinationFinalize(destination)
        #expect(finalized)
        let encoded = OpenImageIO.CGImageDestinationCopyData(destination)
        return try #require(encoded)
    }

    private func encodeWithApple(
        image: CoreGraphics.CGImage,
        typeIdentifier: String
    ) throws -> Data {
        let storage = NSMutableData()
        let destinationCandidate = ImageIO.CGImageDestinationCreateWithData(
            storage,
            typeIdentifier as CFString,
            1,
            nil
        )
        let destination = try #require(destinationCandidate)
        ImageIO.CGImageDestinationAddImage(destination, image, nil)
        let finalized = ImageIO.CGImageDestinationFinalize(destination)
        #expect(finalized)
        return storage as Data
    }

    private func makeAppleImage(width: Int, height: Int) throws -> CoreGraphics.CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                pixels[offset] = UInt8((x * 255) / max(width - 1, 1))
                pixels[offset + 1] = UInt8((y * 255) / max(height - 1, 1))
                pixels[offset + 2] = 127
                pixels[offset + 3] = 255
            }
        }

        let providerCandidate = CoreGraphics.CGDataProvider(data: Data(pixels) as CFData)
        let provider = try #require(providerCandidate)
        let colorSpaceCandidate = CoreGraphics.CGColorSpace(name: CoreGraphics.CGColorSpace.sRGB)
        let colorSpace = try #require(colorSpaceCandidate)
        let imageCandidate = CoreGraphics.CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CoreGraphics.CGBitmapInfo(
                rawValue: CoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        return try #require(imageCandidate)
    }

    private func makeImage(width: Int, height: Int) throws -> OpenCoreGraphics.CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                pixels[offset] = UInt8((x * 255) / max(width - 1, 1))
                pixels[offset + 1] = UInt8((y * 255) / max(height - 1, 1))
                pixels[offset + 2] = 127
                pixels[offset + 3] = 255
            }
        }

        let provider = OpenCoreGraphics.CGDataProvider(data: Data(pixels))
        let colorSpaceCandidate = OpenCoreGraphics.CGColorSpace(
            name: OpenCoreGraphics.CGColorSpace.sRGB
        )
        let colorSpace = try #require(colorSpaceCandidate)
        let image = OpenCoreGraphics.CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: OpenCoreGraphics.CGBitmapInfo(
                    rawValue: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        return try #require(image)
    }
}
