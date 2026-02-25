public struct SwornEnemyOpportunity: Opportunity {
    public func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool {
        // This can run on any test for the tester, but makes most sense on attack tests
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
        guard test is RpgAttackTest else {
            return
        }

        let testerRef = test.tester
        guard var tester = gameSession.game.anyCharacter(at: testerRef) else {
            return
        }

        // Get list of enemies to choose from
        let enemies = gameSession.game.snapshot().opponentRefs(of: testerRef)

        guard !enemies.isEmpty else {
            return
        }

        // Let the player choose which enemy
        let chosenEnemy = try await decider.decide(
            .targetForGainAdvantage,
            options: enemies,
            in: gameSession.game.snapshot()
        )

        // Announce the choice
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 has chosen \(chosenEnemy.name) as their sworn enemy!",
                wU: "You have chosen \(chosenEnemy.name) as your sworn enemy!",
                as1: testerRef
            )
        )

        // Add the SwornEnemyCondition to the tester
        let condition = SwornEnemyCondition(
            for: testerRef,
            against: chosenEnemy,
            in: gameSession
        )
        tester.conditions.upsert(AnyCondition(condition))
    }
}
