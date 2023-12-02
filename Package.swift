// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MRZScanner",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "MRZScanner",
            targets: ["MRZScanner"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/romanmazeev/MRZParser.git", branch: "master"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.2")
    ],
    targets: [
        .target(
            name: "MRZScanner",
            dependencies: [
                "MRZParser",
                .product(
                    name: "XCTestDynamicOverlay",
                    package: "xctest-dynamic-overlay"
                ),
                .product(
                    name: "Dependencies",
                    package: "swift-dependencies"
                )
            ]
        ),
        .testTarget(
            name: "MRZScannerTests",
            dependencies: ["MRZScanner"],
            resources: [.process("Private/TextRecognizerTests/ImageTest.png")]),
    ]
)
