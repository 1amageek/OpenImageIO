import CoreFoundation
import Foundation
import ImageIO
import Testing
@testable import OpenImageIO
import OpenCoreGraphics

@Suite("External Codec Conformance")
struct ExternalCodecConformanceTests {
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
