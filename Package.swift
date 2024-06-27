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
        .package(url: "https://github.com/romanmazeev/MRZParser.git", from: "1.1.4"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.3.1"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "MRZScanner",
            dependencies: [
                "MRZParser",
                .product(
                    name: "Dependencies",
                    package: "swift-dependencies"
                ),
                .product(
                    name: "DependenciesMacros",
                    package: "swift-dependencies"
                )
            ]
        ),
        .testTarget(
            name: "MRZScannerTests",
            dependencies: [
                "MRZScanner",
                .product(
                    name: "CustomDump",
                    package: "swift-custom-dump"
                )
            ],
            resources: [.process("TestImage.png")]
        )
    ]
)
