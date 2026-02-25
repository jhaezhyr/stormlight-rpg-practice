public struct UnbreakableCondition: Condition {
    public let id: Int
    public var type: ConditionTypeRef { Self.type }
    public static var type: ConditionTypeRef { "Unbreakable" }
    public let characterRef: RpgCharacterRef
    public let deflectBonus: Int
    public let syncHandlers: [any EventHandlerSyncProtocol]

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any ConditionSnapshot
    {
        UnbreakableConditionSnapshot(id: id, characterRef: characterRef, deflectBonus: deflectBonus)
    }

    public init(
        for characterRef: RpgCharacterRef,
        deflectBonus: Int = 3,
        in gameSession: isolated GameSession = #isolation,
    ) {
        let id = gameSession.nextId()
        self.id = id
        self.characterRef = characterRef
        self.deflectBonus = deflectBonus
        self.syncHandlers = [
            EventHandlerSync<CharacterPropertyCalculationEvent<Int>> {
                event, gameSession in
                guard characterRef == event.characterRef && event.type == .deflect else {
                    return
                }
                event.value += deflectBonus
            }
        ]
    }
}

public struct UnbreakableConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef { UnbreakableCondition.type }
    public let characterRef: RpgCharacterRef
    public let deflectBonus: Int
}
