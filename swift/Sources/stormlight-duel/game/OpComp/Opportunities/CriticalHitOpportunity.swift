public struct CriticalHitOpportunity: Opportunity {
    public var name: String {
        "Critical Hit"
    }
    public func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool {
        guard test is RpgAttackTest else {
            return false
        }
        return true
    }

    public func run(
        decider: any RpgCharacterBrain,
        on test: any RpgTest,
        in gameSession: isolated GameSession
    )
        async throws
    {
        guard let test = test as? RpgAttackTest else {
            return
        }
        guard var result = test.result else {
            return
        }
        let newDieRolls = test.damageDice.map { $0.rawValue }
        let newGrazeDamage = newDieRolls.reduce(0, +)
        let newDamage = newGrazeDamage + test.modifier()
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 found a weakness and can do max damage!",
                wU: "You found a weakness and can do max damage!",
                as1: test.tester
            )
        )
        result.damageDieRolls = newDieRolls
        result.grazeDamage = newGrazeDamage
        result.fullDamage = newDamage
        test.result = result
    }
}
