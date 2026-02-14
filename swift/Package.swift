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
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.2.0"),
    ],
    targets: [
        // Signals
        .target(
            name: "Signals",
            path: "Sources/lib/Signals/"
        ),
        .testTarget(
            name: "SignalsTests",
            dependencies: [
                "Signals",
                .product(name: "Testing", package: "swift-testing"),
            ],
        ),

        .target(name: "KeyedSet", path: "Sources/lib/KeyedSet/"),
        .target(name: "CompleteDictionary", path: "Sources/lib/CompleteDictionary/"),

        // Main RPG logic
        .target(
            name: "stormlight-duel",
            dependencies: [
                .product(name: "CountedSet", package: "CountedSet"),
                .target(name: "KeyedSet"),
                .target(name: "CompleteDictionary"),
            ],
            path: "Sources/stormlight-duel/game/",
        ),
        .testTarget(
            name: "StormlightDuelTests",
            dependencies: [
                "stormlight-duel",
                .product(name: "Testing", package: "swift-testing"),
            ],
        ),

        // Text brain
        .target(
            name: "text-brain",
            dependencies: [
                .target(name: "stormlight-duel")
            ],
            path: "Sources/stormlight-duel/text-brain",
        ),

        // CLI
        .executableTarget(
            name: "stormlight-duel-cli",
            dependencies: [
                .product(name: "TerminalStyles", package: "terminal-styles"),
                .product(name: "TerminalANSI", package: "terminal-ansi"),
                .product(name: "TerminalWidgets", package: "terminal-widgets"),
                .target(name: "stormlight-duel"),
                .target(name: "text-brain"),
            ],
        ),

        .executableTarget(
            name: "stormlight-duel-service",
            dependencies: [
                .target(name: "stormlight-duel"),
                .target(name: "text-brain"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
            ]
        ),
    ],
)
