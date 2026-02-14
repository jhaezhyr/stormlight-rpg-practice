public struct Afflicted: Condition {
    public let id: Int
    public let damagePerTurn: Damage
    public var snapshot: any ConditionSnapshot {
        AfflictedSnapshot(id: id, damagePerTurn: damagePerTurn)
    }
    public var handlers: [any EventHandlerProtocol]

    public init(
        damagePerTurn: Damage,
        to meRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.id = gameSession.nextId()
        self.damagePerTurn = damagePerTurn
        self.handlers = [
            EventHandler<CombatPhaseEvent> {
                (event: CombatPhaseEvent, game: isolated GameSession) async throws in
                guard event.phase == .endOfTurn,
                    meRef == event.character.primaryKey
                else {
                    return
                }
                let me = event.character
                me.takeDamage(damagePerTurn, in: gameSession)
            }
        ]
    }
}

public struct AfflictedSnapshot: ConditionSnapshot {
    public var id: Int
    public var damagePerTurn: Damage
}
