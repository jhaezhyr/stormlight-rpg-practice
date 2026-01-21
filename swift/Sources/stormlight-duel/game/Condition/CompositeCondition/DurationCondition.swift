public struct DurationCondition<C: Condition & ConditionSnapshot>: CompositeCondition,
    ConditionSnapshot
{
    public var core: C
    public var durationRemainingInTurns: Int
    public let selfListenersSelfHooks: [any SelfListenerSelfHookProtocol]

    public init(core: C, duration: Int, in gameSession: isolated GameSession) {
        let id = core.id
        self.core = core
        self.durationRemainingInTurns = duration
        self.selfListenersSelfHooks = [
            gameSession.selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                gameSession, character in
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
