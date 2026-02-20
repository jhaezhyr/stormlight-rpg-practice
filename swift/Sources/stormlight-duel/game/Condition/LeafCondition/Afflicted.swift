public struct Afflicted: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Afflicted"
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
                let damageDone = await doDamage(damagePerTurn, to: me.primaryKey, in: gameSession)
                await game.game.broadcaster.tellAll(
                    SingleTargetMessage(
                        w1:
                            "$1 takes \(damageDone.amount) \(damageDone.type.rawValue) damage from being afflicted.",
                        wU:
                            "You take \(damageDone.amount) \(damageDone.type.rawValue) damage from being afflicted.",
                        as1: me.primaryKey)
                )
            }
        ]
    }
}

public struct AfflictedSnapshot: ConditionSnapshot {
    public var id: Int
    public var type: ConditionTypeRef = Afflicted.type
    public var damagePerTurn: Damage
}
