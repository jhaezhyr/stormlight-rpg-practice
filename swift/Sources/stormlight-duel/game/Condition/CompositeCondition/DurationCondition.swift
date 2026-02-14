public struct DurationCondition<C: Condition>: CompositeCondition {
    public var core: C
    public var durationRemainingInTurns: Int

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
        self.core = core
        self.durationRemainingInTurns = duration
        self.handlers = [
            EventHandler<CombatPhaseEvent> {
                (event, gameSession) async throws in
                guard event.phase == .endOfTurn, character == event.character.primaryKey else {
                    return
                }
                let character = event.character
                guard var me = character.conditions[id]?.core as? Self else {
                    fatalError(
                        "Why is this condition happening to a character without this condition?")
                }
                me.durationRemainingInTurns -= 1
                if me.durationRemainingInTurns <= 0 {
                    character.conditions.remove(id)
                } else {
                    character.conditions[id] = AnyCondition(me)
                }
            }
        ]
    }
}

public struct DurationConditionSnapshot<T: ConditionSnapshot>: ConditionSnapshot {
    public var id: Int { core.id }
    public let core: T
    public let durationRemainingInTurns: Int
}
