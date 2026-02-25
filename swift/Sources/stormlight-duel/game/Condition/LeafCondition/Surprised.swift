public struct Surprised: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Surprised"
    public let handlers: [any EventHandlerProtocol]

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any ConditionSnapshot
    {
        SurprisedSnapshot(id: id)
    }

    public init(for meRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation) {
        let id = gameSession.nextId()
        self.id = id
        self.handlers = [
            EventHandler<CombatPhaseEvent> {
                (event, game) in
                guard event.phase == .startOfTurn, meRef == event.character.primaryKey else {
                    return
                }
                let me = event.character
                // Don't gain a reaction at the start of your turn
                me.combatState!.reactionsRemaining = 0
                // Gain one fewer action
                me.combatState!.actionsRemaining = me.combatState!.turnSpeed.actionsPerTurn - 1
            },
            EventHandler<CombatPhaseEvent> {
                (event, game) in
                guard event.phase == .endOfTurn, meRef == event.character.primaryKey else {
                    return
                }
                var me = event.character
                me.conditions.remove(id)
            },
        ]
    }
}

public struct SurprisedSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = Surprised.type
}
