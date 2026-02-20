struct TempCondition: Condition {
    var id: Int
    var type: ConditionTypeRef = Self.type
    static let type: ConditionTypeRef = "TempCondition"
    let handlers: [any EventHandlerProtocol]
    init(handlers: [any EventHandlerProtocol], in gameSession: isolated GameSession = #isolation) {
        self.id = gameSession.nextId()
        self.handlers = handlers
    }
    var snapshot: any ConditionSnapshot {
        DummyConditionSnapshot(id: id, type: type)
    }
}

public struct DummyConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public let type: ConditionTypeRef
    public init(id: Int, type: ConditionTypeRef) {
        self.id = id
        self.type = type
    }
}

public func withTempHandlers(
    _ tempHandlers: [any EventHandlerProtocol],
    _ proc: (_ gameSession: isolated GameSession) async throws -> Void,
    in gameSession: isolated GameSession = #isolation
)
    async rethrows
{
    // The implementation details here don't matter too much.
    guard let anyCharacter = gameSession.game.characters.first else {
        return
    }
    let condition = AnyCondition(TempCondition(handlers: tempHandlers))
    anyCharacter.conditions.upsert(condition)
    try await proc(gameSession)
    anyCharacter.conditions.remove(condition)
}
