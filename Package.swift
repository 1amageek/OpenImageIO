// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenImageIO",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OpenImageIO",
            targets: ["OpenImageIO"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/OpenCoreGraphics.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OpenImageIO",
            dependencies: ["OpenCoreGraphics"]
        ),
        .testTarget(
            name: "OpenImageIOTests",
            dependencies: ["OpenImageIO"]
        ),
    ]
)
