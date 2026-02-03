public struct Determined: LeafCondition, ConditionSnapshot {
    public let id: Int
    public let selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol]
    public init(in gameSession: isolated GameSession) {
        let id = gameSession.nextId()
        self.id = id
        self.selfListenersSelfHooksForTests = [
            gameSession.selfListen(
                toMyTests: TestHookType.afterFailure,
                as: AnyRpgCharacter.self,
                testType: AnyRpgTest.self
            ) {
                game, character, test in
                test.opportunitiesAvailable += 1
                character.conditions.remove(id)
            }
        ]
    }
}
