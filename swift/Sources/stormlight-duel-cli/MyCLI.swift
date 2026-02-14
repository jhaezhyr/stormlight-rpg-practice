// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import stormlight_duel
import text_brain

@MainActor
@main
public struct MyCLI {
    static func main() async throws {
        try await GameSession.playSinglePlayerGame {
            try await TextBrain(
                characterRef: $0,
                ui: TextInterfaceProxy(connection: CliInterfaceConnection(for: $0))
            )
        }
    }
}
