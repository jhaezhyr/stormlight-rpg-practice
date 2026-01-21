public struct Afflicted: LeafCondition, ConditionSnapshot {
    public let id: Int
    public let damagePerTurn: Damage
    public init(damagePerTurn: Damage, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.damagePerTurn = damagePerTurn
        self.selfListenersSelfHooks = [
            gameSession.selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                game, me in
                me.takeDamage(damagePerTurn)
            }
        ]
    }
    public let selfListenersSelfHooks: [any SelfListenerSelfHookProtocol]
}
