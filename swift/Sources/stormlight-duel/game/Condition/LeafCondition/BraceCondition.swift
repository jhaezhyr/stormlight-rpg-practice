import KeyedSet

public struct BraceCondition: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Brace"
    public func _snapshot(in gameSession: isolated GameSession) -> any ConditionSnapshot {
        BraceConditionSnapshot(id: id)
    }

    public let handlers: [any EventHandlerProtocol]

    public init(
        for characterRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) {
        let id = gameSession.nextId()
        self.id = id
        self.handlers = [
            EventHandler<TestEvent<StrikePhase>> {
                event, gameSession in
                guard event.event == .aboutToAttemptStrike else {
                    return
                }
                guard event.opponent?.primaryKey == characterRef else {
                    return
                }
                if let test = event.test as? RpgAttackTest {
                    test.disadvantagesAvailable += 1
                }
            },
            EventHandler<TestEvent<StrikePhase>> {
                event, gameSession in
                guard event.event == .aboutToAttemptStrike else {
                    return
                }
                // Remove brace condition when character strikes
                let characterRef = event.test.tester
                if var character = gameSession.game.anyCharacter(at: characterRef) {
                    character.conditions.remove(id)
                }
            },
            EventHandler<CombatActionEvent> {
                event, gameSession in
                // Remove brace condition when character moves
                if event.action is InteractiveMove {
                    if var character = gameSession.game.anyCharacter(at: event.characterRef) {
                        character.conditions.remove(id)
                    }
                }
            },
        ]
    }
}

public struct BraceConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public let type: ConditionTypeRef = BraceCondition.type
}
extension BraceConditionSnapshot: CustomStringConvertible {
    public var description: String {
        "braced"
    }
}
