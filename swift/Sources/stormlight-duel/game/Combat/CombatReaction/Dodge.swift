public struct DodgeProvider: ListenerForWhenIAmTargetedInATestHolderLeaf {
    public var listenersForWhenIAmTargetedInATest: [any ListenerForWhenIAmTargetedInATestProtocol]
    public init(
        for characterRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) {
        self.listenersForWhenIAmTargetedInATest = [
            gameSession.selfListen(
                toTestsWhereIAmTargeted: StrikePhase.aboutToAttemptStrike,
                as: AnyRpgCharacter.self,
                testType: RpgAttackTest.self
            ) {
                session, character, test in
                // TODO Shouldn't have to check this.
                if test.opponent != characterRef {
                    return
                }
                let focusCost = 1
                let reactionCost = 1
                if character.core.focus.value < focusCost {
                    return
                }
                guard let combatState = character.core.combatState,
                    combatState.reactionsRemaining >= reactionCost
                else {
                    return
                }
                let choice = await character.core.brain.decide(
                    .shouldDodge,
                    options: ShouldDodgeChoice.allCases,
                    in: session.game.snapshot
                )
                if choice == .shouldDodge {
                    test.disadvantagesAvailable += 1
                    character.focus.value -= focusCost
                    character.core.combatState!.reactionsRemaining -= reactionCost
                }
            }
        ]
    }
}

public enum ShouldDodgeChoice: Sendable, Equatable, CaseIterable {
    case shouldDodge
    case shouldNotDodge
}
