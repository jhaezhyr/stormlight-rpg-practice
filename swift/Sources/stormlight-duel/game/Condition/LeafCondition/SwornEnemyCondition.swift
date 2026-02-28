public struct SwornEnemyCondition: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "SwornEnemy"
    public let characterRef: RpgCharacterRef
    public let enemyRef: RpgCharacterRef
    public let handlers: [any EventHandlerProtocol]

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any ConditionSnapshot
    {
        SwornEnemyConditionSnapshot(
            id: id,
            characterRef: characterRef,
            enemyRef: enemyRef
        )
    }

    public init(
        for characterRef: RpgCharacterRef,
        against enemyRef: RpgCharacterRef,
        in gameSession: isolated GameSession
    ) {
        let id = gameSession.nextId()
        self.id = id
        self.characterRef = characterRef
        self.enemyRef = enemyRef

        self.handlers = [
            EventHandler<TestEvent<TestHookType>> { event, gameSession in
                guard event.event == .beforeRoll else {
                    return
                }
                guard let attackTest = event.test as? RpgAttackTest,
                    let opponent = attackTest.opponent, opponent == enemyRef
                else {
                    return
                }
                guard characterRef == event.test.tester else {
                    return
                }
                let extraDie =
                    attackTest.damageDice.randomElement(using: &gameSession.game.rng) ?? .d4
                attackTest.damageDice.append(extraDie)

                await gameSession.game.broadcaster.tellAll(
                    DoubleTargetMessage(
                        w12:
                            "$1's sworn oath against $2 grants them an extra \(extraDie) to roll for damage!",
                        wU2:
                            "Your sworn oath against $2 grants you an extra \(extraDie) to roll for damage!",
                        w1U:
                            "$1's sworn oath against you grants them an extra \(extraDie) to roll for damage!",
                        as1: characterRef, as2: opponent)
                )
            },
            EventHandler<TestEvent<StrikePhase>> {
                event, gameSession in
                guard event.event == .dealtDamage else {
                    return
                }
                guard characterRef == event.test.tester else {
                    return
                }
                guard let attackTest = event.test as? RpgAttackTest,
                    let opponent = attackTest.opponent, opponent == enemyRef
                else {
                    return
                }
                guard var character = gameSession.game.anyCharacter(at: characterRef) else {
                    return
                }
                character.conditions.remove(id)
            },
        ]
    }
}

public struct SwornEnemyConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = SwornEnemyCondition.type
    public let characterRef: RpgCharacterRef
    public let enemyRef: RpgCharacterRef
}
