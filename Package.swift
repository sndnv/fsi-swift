// swift-tools-version: 6.0

import Foundation
import PackageDescription

let benchmarksEnabled = ProcessInfo.processInfo.environment["BENCHMARKS_ENABLED"] != nil

let benchmarkDependencies: [Package.Dependency] = benchmarksEnabled ? [
    .package(url: "https://github.com/ordo-one/benchmark", from: "1.33.0"),
] : []

let benchmarkTargets: [Target] = benchmarksEnabled ? [
    .executableTarget(
        name: "fsiBenchmarks",
        dependencies: [
            .product(name: "Benchmark", package: "benchmark"),
            "fsi",
        ],
        path: "Benchmarks/fsiBenchmarks",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "benchmark"),
        ]
    ),
] : []

let package = Package(
    name: "fsi",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "fsi",
            targets: ["fsi"]
        ),
    ],
    dependencies: benchmarkDependencies,
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
    ] + benchmarkTargets
)
