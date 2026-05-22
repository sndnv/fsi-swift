// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "fsi",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "fsi",
            targets: ["fsi"]
        ),
    ],
    targets: [
        .target(
            name: "fsi",
            path: "Sources/fsi"
        ),
        .testTarget(
            name: "fsiTests",
            dependencies: ["fsi"],
            path: "Tests/fsiTests"
        ),
    ]
)
