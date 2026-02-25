public struct GiveConditionOpComp<M: Message, C: Condition>: OpComp {
    public let name: String
    public let getMessageAndCondition:
        @Sendable (_ testerRef: RpgCharacterRef, _ gameSession: isolated GameSession) -> (M, C)
    public func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool {
        return true
    }

    public func run(
        decider: any RpgCharacterBrain,
        on test: any RpgTest,
        in gameSession: isolated GameSession
    )
        async throws
    {
        guard var tester = gameSession.game.anyCharacter(at: test.tester) else {
            return
        }
        let (message, condition) = getMessageAndCondition(tester.primaryKey, gameSession)
        await gameSession.game.broadcaster.tellAll(message)

        tester.conditions.upsert(AnyCondition(condition))
    }
}
extension GiveConditionOpComp: CustomStringConvertible {
    public var description: String {
        name
    }
}
