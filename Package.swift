// swift-tools-version: 5.8.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PreviewShowcase",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "previewShowcase",
                    targets: ["PreviewShowcase"]),
        .library(name: "PreviewShowcaseUpdater", targets: ["PreviewShowcaseUpdater"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PreviewShowcase",
            dependencies: ["PreviewShowcaseUpdater"]),
        .target(
            name: "PreviewShowcaseUpdater",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "PreviewShowcaseUpdaterTests",
            dependencies: ["PreviewShowcaseUpdater"],
            resources: [
                .process("Resources")
            ])
    ]
)
