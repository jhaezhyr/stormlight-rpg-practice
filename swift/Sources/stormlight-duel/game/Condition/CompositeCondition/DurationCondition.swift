public struct DurationCondition<C: Condition>: CompositeCondition {
    public var core: C
    public var durationRemainingInTurns: Int
    public var type: ConditionTypeRef { core.type }

    public var handlers: [any EventHandlerProtocol]

    public var snapshot: any ConditionSnapshot {
        DurationConditionSnapshot(
            core: AnyConditionSnapshot(core.snapshot),
            durationRemainingInTurns: durationRemainingInTurns
        )
    }

    public init(
        core: C,
        duration: Int,
        for character: RpgCharacterRef,
        in gameSession: isolated GameSession
    ) {
        let id = core.id
        let coreName = "\(core)"
        self.core = core
        self.durationRemainingInTurns = duration
        self.handlers = [
            EventHandler<CombatPhaseEvent> {
                (event, gameSession) async throws in
                guard event.phase == .endOfTurn, character == event.character.primaryKey else {
                    return
                }
                var character = event.character  // TODO var is a bug
                guard var me = character.conditions[id]?.core as? Self else {
                    fatalError(
                        "Why is this condition happening to a character without this condition?")
                }
                me.durationRemainingInTurns -= 1
                if me.durationRemainingInTurns <= 0 {
                    character.conditions.remove(id)
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1: "$1 loses the \(coreName) condition.",
                            wU: "You lose the \(coreName) condition.", as1: character.primaryKey))
                } else {
                    character.conditions[id] = AnyCondition(me)
                }
            }
        ]
    }
}

public struct DurationConditionSnapshot<T: ConditionSnapshot>: ConditionSnapshot {
    public var id: Int { core.id }
    public var type: ConditionTypeRef { core.type }
    public let core: T
    public let durationRemainingInTurns: Int
}
