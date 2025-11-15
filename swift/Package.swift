// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stormlight-duel",
    targets: [
        // Signals Library
        .target(
            name: "Signals",
        ),

        // Signals Tests
        .testTarget(
            name: "SignalsTests",
            dependencies: ["Signals"],
        ),

        // Main executable
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "stormlight-duel",
            dependencies: ["Signals"]
        ),
    ]
)
