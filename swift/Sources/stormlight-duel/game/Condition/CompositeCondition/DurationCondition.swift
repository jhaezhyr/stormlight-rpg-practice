public struct DurationCondition<C: Condition>: CompositeCondition {
    public var core: C
    public var durationRemainingInTurns: Int
    public let waitingCharacter: RpgCharacterRef
    public let parentCharacter: RpgCharacterRef
    public var type: ConditionTypeRef { core.type }

    public var handlers: [any EventHandlerProtocol]

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any ConditionSnapshot
    {
        DurationConditionSnapshot(
            core: AnyConditionSnapshot(core.snapshot()),
            waitingCharacter: waitingCharacter,
            parentCharacter: parentCharacter,
            durationRemainingInTurns: durationRemainingInTurns,
        )
    }

    public init(
        core: C,
        duration: Int,
        turnsFor waitingCharacter: RpgCharacterRef,
        butBelongingTo parentCharacter: RpgCharacterRef? = nil,
        in gameSession: isolated GameSession = #isolation
    ) {
        let id = core.id
        let coreName = "\(core)"
        self.core = core
        self.durationRemainingInTurns = duration
        self.waitingCharacter = waitingCharacter
        self.parentCharacter = parentCharacter ?? waitingCharacter
        self.handlers = [
            EventHandler<CombatPhaseEvent> {
                (event, gameSession) async throws in
                guard event.phase == .endOfTurn, waitingCharacter == event.character.primaryKey
                else {
                    return
                }
                guard
                    var character = gameSession.game.anyCharacter(  // TODO var is a bug
                        at: parentCharacter ?? waitingCharacter
                    )
                else {
                    fatalError("This condition wore off but its target character is missing.")
                }
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
    public let waitingCharacter: RpgCharacterRef
    public let parentCharacter: RpgCharacterRef
    public let durationRemainingInTurns: Int
}
