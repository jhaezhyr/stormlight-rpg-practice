// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import stormlight_duel
import text_brain

@MainActor
@main
public struct MyCLI {
    static func main() async throws {
        let session = GameSession()
        let broadcaster = Broadcaster()

        let player1Ref = RpgCharacterRef(name: "Kal")
        let player1 = PlayerRpgCharacter(
            name: player1Ref.name,
            expertises: [],
            equipment: [await Readyable(basicWeapons[.axe]!(session), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            reach: 0,
            conditions: [],
            brain: try await TextBrain(
                characterRef: player1Ref,
                ui: TextInterfaceProxy(connection: CliInterfaceConnection(for: player1Ref))
            ),
            isPlayer: true
        )
        let player2 = PlayerRpgCharacter(
            name: "Shallan",
            expertises: [],
            equipment: [await Readyable(basicWeapons[.knife]!(session), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            reach: 0,
            conditions: [],
            brain: Level1CpuBrain(
                for: RpgCharacterRef(name: "Shallan")
            ),
            isPlayer: false
        )
        await session.provideGame(
            Game(
                characters: [player1, player2], broadcaster: broadcaster,
                gameMasterBrain: Level1CpuBrain(
                    for: RpgCharacterRef(name: "GM EN")
                )))

        try await session.switch(to: Combat(map: Map.emptyDuel))
    }
}
