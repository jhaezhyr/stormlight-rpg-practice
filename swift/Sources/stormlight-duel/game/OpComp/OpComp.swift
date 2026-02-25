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
        Self.standardOpportunities
    }
    /// All possible complications for a test
    func complications(
        test: any RpgTest,
        in gameSession: isolated GameSession = #isolation
    ) -> [Complication] {
        Self.standardComplications
    }

    public static let standardOpportunities: [any Opportunity] = [
        CriticalHitOpportunity()
    ]
    public static let standardComplications: [any Complication] = [
        SurpriseComplication()
    ]
}
