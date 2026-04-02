import Testing
import stormlight_duel

@Test("Martial Drill feature is present on SpearInfantry and works")
func testMartialDrillFeature() async throws {
    let gameSession = GameSession(
        game: Game(
            characters: [], broadcaster: Broadcaster(),
            gameMasterBrain: RpgCharacterDummyBrain(
                characterRef: .gameMaster, defaultBehavior: .firstOption)))
    func handle(in gameSession: isolated GameSession) async throws {
        let spearInfantry = PrefabCharacters.spearInfantry(
            isPlayer: false,
            brain: RpgCharacterDummyBrain(characterRef: RpgCharacterRef(name: "Test Spearman")),
            andAddTo: gameSession
        )

        gameSession.game.updateCharacter(spearInfantry)

        let hasMartialDrill = spearInfantry.features.contains { feature in
            feature.name == "Martial Drill"
        }
        #expect(hasMartialDrill == true)

        let hasShield = spearInfantry.equipment.contains { readyable in
            readyable.isReady && (readyable.core.core as? any Weapon)?.weaponName == .shield
        }
        #expect(hasShield == true)

        let martialDrillFeature = spearInfantry.features.first { feature in
            feature.name == "Martial Drill"
        }
        #expect(martialDrillFeature != nil)

        if let feature = martialDrillFeature {
            #expect(feature.handlers.count > 0)
        }
        let combat = Combat(map: Map.emptyDuel)
        try await combat.start()
        let braceCondition = spearInfantry.conditions.first { $0.type == BraceCondition.type }
        #expect(braceCondition != nil)
    }
    try await handle(in: gameSession)
}
