// swift-tools-version: 6.0
//
// OpenImageIO WASM smoke-test executable. Runs Swift Testing `@Test`
// functions inside headless Chromium via swift-wasm-testing.
//
// OpenImageIO is a pure-Swift codec library with no browser dependency,
// but running the same encode/decode paths under wasm32 catches regressions
// unique to the WASM target (Int width, byte order, reactor-ABI init races).
//
// Builds with:
//   swift build --product OIIOSmoke --swift-sdk swift-6.3.1-RELEASE_wasm -c release
// then copy .build/wasm32-unknown-wasip1/release/OIIOSmoke.wasm into
// Examples/SmokeTest/web/ where server.mjs serves it.

import PackageDescription

let package = Package(
    name: "OIIOSmoke",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../OpenCoreGraphics"),
        .package(url: "https://github.com/1amageek/swift-wasm-testing", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "OIIOSmoke",
            dependencies: [
                .product(name: "OpenImageIO", package: "OpenImageIO"),
                .product(name: "OpenCoreGraphics", package: "OpenCoreGraphics"),
                .product(name: "WasmTesting", package: "swift-wasm-testing"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xclang-linker", "-mexec-model=reactor",
                    "-Xlinker", "--export=setup",
                ])
            ]
        ),
    ]
)
