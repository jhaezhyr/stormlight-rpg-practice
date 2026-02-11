public struct DodgeProvider: Responder {
    public let handlers: [any EventHandlerProtocol]
    public init(
        for meRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation,
    ) {
        self.handlers = [
            EventHandler<TestEvent<StrikePhase>> {
                event, session in
                guard event.event == .aboutToAttemptStrike else {
                    return
                }
                var test = event.test  // TODO A bug is saying this can't be a `let`
                let me = event.opponent!
                guard test.opponent == meRef else {
                    return
                }
                let focusCost = 1
                let reactionCost = 1
                if me.focus.value < focusCost {
                    return
                }
                guard let combatState = me.combatState,
                    combatState.reactionsRemaining >= reactionCost
                else {
                    return
                }
                let choice = await me.brain.decide(
                    .shouldDodge,
                    options: ShouldDodgeChoice.allCases,
                    in: session.game.snapshot
                )
                if choice == .shouldDodge {
                    await session.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            "$1 dodges the incoming strike.", "You dodge the incoming strike.",
                            for: meRef))
                    test.disadvantagesAvailable += 1
                    me.focus.value -= focusCost
                    me.combatState!.reactionsRemaining -= reactionCost
                }
            }
        ]
    }
}

public enum ShouldDodgeChoice: Sendable, Equatable, CaseIterable {
    case shouldDodge
    case shouldNotDodge
}
extension ShouldDodgeChoice: CustomStringConvertible {
    public var description: String {
        switch self {
        case .shouldDodge: "dodge"
        case .shouldNotDodge: "don't dodge"
        }
    }
}
