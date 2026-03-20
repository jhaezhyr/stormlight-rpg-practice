import Testing
import stormlight_duel

@Test("dodge creates one disadvantage")
func dodgeCreatesOneAdvantage() async throws {
    let goodGuyRef = RpgCharacterRef(name: "Goody")
    let badGuyRef = RpgCharacterRef(name: "Baddy")
    let badBrain = RpgCharacterDummyBrain(characterRef: badGuyRef)
    @MainActor
    func setPremadeAnswers() {
        badBrain.onlyGivePremadeAnswers = true
    }
    await setPremadeAnswers()
    let session = GameSession(
        game: Game(
            characters: [],
            broadcaster: Broadcaster(),
            gameMasterBrain: RpgCharacterDummyBrain(characterRef: RpgCharacterRef(name: "GM"))
        )
    )
    func doIt(in session: isolated GameSession) async throws {
        PlayerRpgCharacter.basicCharacter(name: goodGuyRef.name, andAddTo: session)
        PlayerRpgCharacter.basicCharacter(name: badGuyRef.name, brain: badBrain, andAddTo: session)
        let goodGuy = session.game.character(at: goodGuyRef, as: PlayerRpgCharacter.self)!
        let knife = basicWeapons[.knife]!(session)
        goodGuy.equipment.upsert(Readyable(knife, isReady: true))
        let combat = Combat(map: Map.emptyDuel)
        try await combat.start()
        let action = Strike(badGuyRef, with: knife.primaryKey)
        await badBrain.insertPremadeAnswer(ShouldDodgeChoice.shouldDodge)
        await badBrain.insertPremadeAnswer(
            DecideOrOther.decide(
                RoleWithAdvantageNumber<AttackDieRole>(role: .testDie, advantageNumber: nil)
            )
        )
        try await action.reallyTakeAction(by: goodGuyRef, in: session)
        let remainingAnswers = await badBrain.premadeAnswers
        #expect(remainingAnswers.count == 0, "The bad guy should have been asked to dodge.")
    }
    try await doIt(in: session)
}
