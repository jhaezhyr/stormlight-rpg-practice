public protocol OpComp: Sendable {
    func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool
    func run(
        decider: any RpgCharacterBrain,
        on test: any RpgTest,
        in gameSession: isolated GameSession
    ) async throws
}
public typealias Opportunity = OpComp
public typealias Complication = OpComp

extension OpComp {
    func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool { true }
}

extension Game {
    /// All possible opportunities for a test
    func opportunities(
        test: any RpgTest,
        in gameSession: isolated GameSession = #isolation
    ) -> [Opportunity] {
        gameSession.game.dispatchCalculation(
            OpportunitiesAvailableCalculationEvent(
                Self.standardOpportunities,
                type: .opportunitiesAvailable,
                for: test.tester
            )
        )
    }
    /// All possible complications for a test
    func complications(
        test: any RpgTest,
        in gameSession: isolated GameSession = #isolation
    ) -> [Complication] {
        gameSession.game.dispatchCalculation(
            ComplicationsAvailableCalculationEvent(
                Self.standardComplications,
                type: .complicationsAvailable,
                for: test.tester
            )
        )
    }

    public static let standardOpportunities: [any Opportunity] = [
        CriticalHitOpportunity(),
        SwornEnemyOpportunity(),
        OutmaneuverOpportunity(),
        UnbreakableOpportunity(),
    ]
    public static let standardComplications: [any Complication] = [
        SurpriseComplication(),
        ComingStormComplication(),
    ]
}

public typealias ComplicationsAvailableCalculationEvent = CharacterPropertyCalculationEvent<
    [Complication]
>
public typealias OpportunitiesAvailableCalculationEvent = CharacterPropertyCalculationEvent<
    [Opportunity]
>
extension CalculationEventType {
    public static let opportunitiesAvailable = Self("opportunitiesAvailable")
    public static let complicationsAvailable = Self("complicationsAvailable")
}
