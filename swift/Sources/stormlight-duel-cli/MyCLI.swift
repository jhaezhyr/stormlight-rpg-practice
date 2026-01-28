// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import stormlight_duel

@MainActor
@main
public struct MyCLI {
    static func main() async {
        let session = GameSession()
        let broadcaster = CliBroadcaster()

        let player1 = PlayerRpgCharacter(
            name: "Kal",
            expertises: [],
            equipment: [await Readyable(basicWeapons[.axe]!(session), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            conditions: [],
            brain: CliRpgCharacterBrain(
                broadcaster: broadcaster,
                characterRef: RpgCharacterRef(name: "Kal")
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
            conditions: [],
            brain: Level1CpuBrain(
                for: RpgCharacterRef(name: "Shallan")
            ),
            isPlayer: false
        )
        await session.provideGame(Game(characters: [player1, player2], broadcaster: broadcaster))

        await session.switch(to: Combat())
    }
}
