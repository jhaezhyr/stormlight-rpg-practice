public struct Determined: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Determined"
    public let handlers: [any EventHandlerProtocol]
    public var snapshot: any ConditionSnapshot {
        DeterminedSnapshot(id: id)
    }
    public init(for meRef: RpgCharacterRef, in gameSession: isolated GameSession) {
        let id = gameSession.nextId()
        self.id = id
        self.handlers = [
            EventHandler<TestEvent<TestHookType>> {
                (event, game) in
                var test = event.test
                guard event.tester.primaryKey == meRef else {
                    return
                }
                test.opportunitiesAvailable += 1
                event.tester.conditions.remove(id)
            }
        ]
    }
}

public struct DeterminedSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = Determined.type
}
