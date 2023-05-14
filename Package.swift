// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PreviewShowcase",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "previewShowcase",
                    targets: ["PreviewShowcase"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PreviewShowcase",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]),
    ]
)
