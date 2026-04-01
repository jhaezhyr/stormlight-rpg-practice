// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import stormlight_duel
import text_brain

/// Creates a brain for CLI-based play.
func makeCliBrain(
    for template: PlayerBuilderTemplate,
    ref: RpgCharacterRef
) async throws -> RpgCharacterBrain {
    // For CLI, we always use TextBrain with a CliInterfaceConnection
    return try await TextBrain(
        characterRef: ref,
        ui: TextInterfaceProxy(connection: CliInterfaceConnection(for: ref))
    )
}

@MainActor
@main
public struct MyCLI {
    static func main() async throws {
        // Build player template - Archer named Kal
        let playerTemplate = PlayerBuilderTemplate(
            prefab: .archer,
            isPlayer: true,
            name: "Kal",
            cpuBrainKey: nil,
            connection: nil
        )

        // Build enemy template - Spear Infantry named Shallan with CPU
        let enemyTemplate = PlayerBuilderTemplate(
            prefab: .spearInfantry,
            isPlayer: false,
            name: "Shallan",
            cpuBrainKey: .level1,
            connection: nil
        )

        // Create and run game session
        _ = try await GameSession.from(
            [playerTemplate, enemyTemplate],
            brainFactory: makeCliBrain
        )
    }
}
