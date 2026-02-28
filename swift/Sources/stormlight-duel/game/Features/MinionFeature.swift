public struct MinionFeature: CharacterFeature {
    public var name: CharacterFeatureRef { Self.name }
    public static var name: CharacterFeatureRef { "Minion" }
    public let syncHandlers: [any EventHandlerSyncProtocol]
    private let savedSnapshot: any CharacterFeatureSnapshot
    public func _snapshot(in gameSession: isolated GameSession) -> any CharacterFeatureSnapshot {
        savedSnapshot
    }
    public init(
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.syncHandlers = [
            EventHandlerSync<OpportunitiesAvailableCalculationEvent> {
                event, gameSession in
                guard
                    characterRef == event.characterRef
                        && event.type == .opportunitiesAvailable
                else {
                    return
                }
                event.value.removeAll { $0 is CriticalHitOpportunity }
            }
        ]
        self.savedSnapshot = MinionFeatureSnapshot()
    }
}

public struct MinionFeatureSnapshot: CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { MinionFeature.name }
}
