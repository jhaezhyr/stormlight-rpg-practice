public struct SwornEnemyOpportunity: Opportunity {
    public var name: String {
        "Sworn Enemy"
    }
    public func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool {
        let testerRef = test.tester
        let enemies = gameSession.game.snapshot().opponentRefs(of: testerRef)
        guard enemies.isEmpty else {
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
        let testerRef = test.tester
        let enemies = gameSession.game.snapshot().opponentRefs(of: testerRef)
        guard var tester = gameSession.game.anyCharacter(at: testerRef) else {
            return
        }

        let chosenEnemy = try await decider.decide(
            .targetForGainAdvantage,
            options: enemies,
            in: gameSession.game.snapshot(),
        )

        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 has chosen \(chosenEnemy.name) as their sworn enemy!",
                wU: "You have chosen \(chosenEnemy.name) as your sworn enemy!",
                as1: testerRef
            )
        )

        let condition = SwornEnemyCondition(
            for: testerRef,
            against: chosenEnemy,
            in: gameSession
        )
        tester.conditions.upsert(.init(condition))
    }
}
