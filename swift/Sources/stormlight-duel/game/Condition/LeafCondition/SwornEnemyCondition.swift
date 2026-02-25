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
                // Check if this is an attack test
                guard let attackTest = event.test as? RpgAttackTest else {
                    return
                }

                // Check if the tester is the character with this condition
                guard characterRef == event.test.tester else {
                    return
                }

                // Check if the opponent is the chosen enemy
                guard let opponent = attackTest.opponent, opponent == enemyRef else {
                    return
                }

                // Check if the attack was successful (hit or graze)
                guard var result = attackTest.result else {
                    return
                }

                guard result.testResult else {
                    return
                }

                // Add an extra weapon die of damage
                // Roll one of the existing damage dice
                guard !attackTest.damageDice.isEmpty else {
                    return
                }

                let extraDie = attackTest.damageDice.randomElement(using: &gameSession.game.rng)!
                let extraRoll = extraDie.roll(withModifier: nil, rng: &gameSession.game.rng)

                // Update the result with the extra damage
                result.damageDieRolls.append(extraRoll)
                result.grazeDamage += extraRoll
                result.fullDamage += extraRoll

                attackTest.result = result

                // Announce the bonus damage
                await gameSession.game.broadcaster.tellAll(
                    SingleTargetMessage(
                        w1:
                            "$1's sworn enemy oath grants them an extra \(extraDie) of damage, hitting for \(extraRoll)!",
                        wU:
                            "Your sworn enemy oath grants you an extra \(extraDie) of damage, hitting for \(extraRoll)!",
                        as1: characterRef
                    )
                )

                // Remove this condition after it's been used
                var tester = event.tester
                tester.conditions.remove(id)
            }
        ]
    }
}

public struct SwornEnemyConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = SwornEnemyCondition.type
    public let characterRef: RpgCharacterRef
    public let enemyRef: RpgCharacterRef
}
