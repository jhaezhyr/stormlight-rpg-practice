import KeyedSet

public protocol RpgTestSharedProtocol: Keyed where Key == RpgTestRef {
    var id: Int { get }

    var tester: RpgCharacterRef { get }
    var opponent: RpgCharacterRef? { get }

    var skill: SkillName { get }
    var otherModifiers: Int { get set }
    var difficulty: Int { get set }  // In a head to head, this is the opponent's total number.

    var advantagesAvailable: Int { get set }
    var disadvantagesAvailable: Int { get set }
    var opportunitiesAvailable: Int { get set }
    var complicationsAvailable: Int { get set }
}
extension RpgTestSharedProtocol {
    public var primaryKey: RpgTestRef {
        RpgTestRef(id: id)
    }
}

public protocol RpgTestResultProtocol {
    var testDieRoll: Int { get }
    var testResult: Bool { get }

    var advantagesApplied: Int { get }
    var disadvantagesApplied: Int { get }
    var opportunitiesApplied: Int { get }
    var complicationsApplied: Int { get }
}

/// Since a test has lots of hooks, it is a fully mutable structure
///
/// A head-to-head test is presented to each character as a separate test structure.
///
/// In an attack, there will also be damage rolls. Those rolls are not part of the test structure. However, the advantages, disadvantages, opportunities, and complications from the test can affect those rolls.
public protocol RpgTest: AnyObject, RpgTestSharedProtocol, SendableMetatype {
    func _snapshot(in gameSession: isolated GameSession) -> any RpgTestSnapshot

    associatedtype ResultType: RpgTestResultProtocol
    func roll(in gameSession: isolated GameSession) async throws -> ResultType

    var trueSelf: any RpgTest { get }
}
extension RpgTest {
    public var trueSelf: any RpgTest { self }
    public func snapshot(in gameSession: isolated GameSession = #isolation) -> any RpgTestSnapshot {
        self._snapshot(in: gameSession)
    }
}
extension RpgTest where Self: RpgTestSnapshot {
    public var snapshot: some RpgTestSnapshot { self }
}

extension RpgTest {
    public func resolveOpportunitiesAndComplications(
        in gameSession: isolated GameSession = #isolation
    ) async throws {
        typealias IsOpportunity = Bool
        let complicationBrain = gameSession.game.gameMasterBrain
        let opportunityBrain = gameSession.game.anyCharacter(at: tester)!.brain
        while true {
            let remaining =
                [Bool](repeating: true, count: opportunitiesAvailable)
                + [Bool](repeating: false, count: complicationsAvailable)
            guard let next = remaining.randomElement(using: &gameSession.game.rng) else {
                return
            }
            let allOptions =
                (next
                ? gameSession.game.opportunities(test: trueSelf)
                : gameSession.game.complications(test: trueSelf)).filter {
                    $0.canRun(on: trueSelf, in: gameSession)
                }
            var mutatableSelf = self
            if next {
                mutatableSelf.opportunitiesAvailable -= 1
            } else {
                mutatableSelf.complicationsAvailable -= 1
            }
            if allOptions.isEmpty {
                await gameSession.game.broadcaster.tellAll(
                    NoTargetMessage(
                        "Sorry, there are no more \(next ? "opportunities" : "complications") for you to choose from."
                    )
                )
                if next {
                    mutatableSelf.opportunitiesAvailable = 0
                } else {
                    mutatableSelf.complicationsAvailable = 0
                }
                continue
            }
            // TODO Narrow the options.
            let brain = next ? opportunityBrain : complicationBrain
            let decision = try await brain.decide(
                next ? .opportunityChoice : .complicationChoice,
                options: allOptions,
                in: gameSession.game.snapshot()
            )

            try await decision.run(decider: brain, on: trueSelf, in: gameSession)
        }
    }
}

/// Use this in places where `any RpgTest` doesn't work.
public class AnyRpgTest: RpgTest {
    public var core: any RpgTest
    public var trueSelf: any RpgTest { core }
    public init(_ test: any RpgTest) {
        self.core = test
    }
    public var id: Int { core.id }

    public var tester: RpgCharacterRef { core.tester }
    public var opponent: RpgCharacterRef? { core.opponent }

    public var skill: SkillName { core.skill }
    public var difficulty: Int {
        get { core.difficulty }
        set { core.difficulty = newValue }
    }
    public var otherModifiers: Int {
        get { core.otherModifiers }
        set { core.otherModifiers = newValue }
    }
    public var advantagesAvailable: Int {
        get { core.advantagesAvailable }
        set { core.advantagesAvailable = newValue }
    }
    public var disadvantagesAvailable: Int {
        get { core.disadvantagesAvailable }
        set { core.disadvantagesAvailable = newValue }
    }
    public var opportunitiesAvailable: Int {
        get { core.opportunitiesAvailable }
        set { core.opportunitiesAvailable = newValue }
    }
    public var complicationsAvailable: Int {
        get { core.complicationsAvailable }
        set { core.complicationsAvailable = newValue }
    }

    public func _snapshot(in gameSession: isolated GameSession = #isolation) -> any RpgTestSnapshot
    {
        core._snapshot(in: gameSession)
    }

    public typealias ResultType = RpgSimpleTestResult
    public func roll(in gameSession: isolated GameSession) async throws -> RpgSimpleTestResult {
        fatalError("This really isn't how you're supposed to use a test, man.")
    }
}

public struct RpgTestRef: Sendable, Hashable {
    public var id: Int
}

public enum TestHookType: Sendable {
    case beforeRoll
    case beforeResolution
    case afterFailure
    case afterSuccess
}
