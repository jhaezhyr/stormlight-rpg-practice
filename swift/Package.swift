// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stormlight-duel",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/juri/terminal-styles.git", from: "0.3.0"),
        .package(url: "https://github.com/juri/terminal-widgets.git", from: "0.1.0"),
        .package(url: "https://github.com/juri/terminal-ansi.git", from: "0.3.0"),
        .package(url: "https://github.com/mickmaccallum/CountedSet.git", from: "2.0.1"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.1.0"),
    ],
    targets: [
        // Signals Library
        .target(
            name: "Signals",
        ),

        // Signals Tests
        .testTarget(
            name: "SignalsTests",
            dependencies: [
                "Signals",
                .product(name: "Testing", package: "swift-testing"),
            ],
        ),

        .target(
            name: "stormlight-duel",
            dependencies: [
                .product(name: "CountedSet", package: "CountedSet")
            ]),

        // RPG Tests
        .testTarget(
            name: "StormlightDuelTests",
            dependencies: [
                "stormlight-duel",
                .product(name: "Testing", package: "swift-testing"),
            ],
        ),

        // Main executable
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "stormlight-duel-cli",
            dependencies: [
                .product(name: "TerminalStyles", package: "terminal-styles"),
                .product(name: "TerminalANSI", package: "terminal-ansi"),
                .product(name: "TerminalWidgets", package: "terminal-widgets"),
                .target(name: "stormlight-duel"),
            ],
        ),
    ],
)
