public struct OutmaneuverCondition: Condition {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Outmaneuver"
    public let characterRef: RpgCharacterRef
    public let handlers: [any EventHandlerProtocol]

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any ConditionSnapshot
    {
        OutmaneuverConditionSnapshot(id: id, characterRef: characterRef)
    }

    public init(
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation,
    ) {
        let id = gameSession.nextId()
        self.id = id
        self.characterRef = characterRef

        self.handlers = []
    }
}

public struct OutmaneuverConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = OutmaneuverCondition.type
    public let characterRef: RpgCharacterRef
}
