// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import stormlight_duel

@main
public struct MyCLI {
    static func main() {
        let player1 = PlayerRpgCharacter(
            name: "Kal",
            expertises: [],
            equipment: [ReadyableItem(basicWeapons[.axe]!(), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            conditions: [],
            brain: CliRpgCharacterBrain()
        )
        let player2 = PlayerRpgCharacter(
            name: "Shallan",
            expertises: [],
            equipment: [ReadyableItem(basicWeapons[.knife]!(), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            conditions: [],
            brain: CliRpgCharacterBrain()
        )
        var game = Game(characters: [player1, player2], broadcaster: CliBroadcaster())

        let combat = Combat()
        combat.run(in: game)
    }
}
