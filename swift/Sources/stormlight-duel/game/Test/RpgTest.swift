public protocol RpgTestSharedProtocol: Keyed where Key == RpgTestRef {
    var id: Int { get }

    var skill: SkillName { get }
    var advantages: Int { get }
    var disadvantages: Int { get }
    var testRolls: [RpgTestRoll] { get }
    var difficulty: Int { get }  // In a head to head, this is the opponent's total number.
    var opportunities: Int { get }
    var complications: Int { get }

    var success: Bool? { get }
}
extension RpgTestSharedProtocol {
    public var primaryKey: RpgTestRef {
        RpgTestRef(id: id)
    }
}

/// Since a test has lots of hooks, it is a fully mutable structure
///
/// A head-to-head test is presented to each character as a separate test structure.
///
/// In an attack, there will also be damage rolls. Those rolls are not part of the test structure. However, the advantages, disadvantages, opportunities, and complications from the test can affect those rolls.
public protocol RpgTest: AnyObject, RpgTestSharedProtocol, SendableMetatype {
    var skill: SkillName { get set }
    var advantages: Int { get set }
    var disadvantages: Int { get set }
    var testRolls: [RpgTestRoll] { get set }
    var difficulty: Int { get set }  // In a head to head, this is the opponent's total number.
    var opportunities: Int { get set }
    var complications: Int { get set }

    var snapshot: any RpgTestSnapshot { get }
}
extension RpgTest where Self: RpgTestSnapshot {
    public var snapshot: any RpgTestSnapshot { self }
}

public class RpgSimpleTest: RpgTest {
    public let id: Int
    public var skill: SkillName
    public var difficulty: Int
    public var advantages: Int = 0
    public var disadvantages: Int = 0
    public var testRolls: [RpgTestRoll] = []
    public var opportunities: Int = 0
    public var complications: Int = 0

    public var success: Bool? = nil

    public init(
        skill: SkillName,
        difficulty: Int,
        advantages: Int? = nil,
        disadvantages: Int? = nil,
        testRolls: [RpgTestRoll]? = nil,
        opportunities: Int? = nil,
        complications: Int? = nil,
        success: Bool? = nil,
        in gameSession: isolated GameSession
    ) {
        self.id = gameSession.nextId()
        self.skill = skill
        self.difficulty = difficulty
        if let advantages { self.advantages = advantages }
        if let disadvantages { self.disadvantages = disadvantages }
        if let testRolls { self.testRolls = testRolls }
        if let opportunities { self.opportunities = opportunities }
        if let complications { self.complications = complications }
        if let success { self.success = success }
    }

    public var snapshot: any RpgTestSnapshot {
        RpgSimpleTestSnapshot(
            id: id,
            skill: skill,
            difficulty: difficulty,
            advantages: advantages,
            disadvantages: disadvantages,
            testRolls: testRolls,
            opportunities: opportunities,
            complications: complications,
        )
    }
}

/// Use this in places where `any RpgTest` doesn't work.
public class AnyRpgTest: RpgTest {
    public var core: any RpgTest
    public init(_ test: any RpgTest) {
        self.core = test
    }
    public var id: Int { core.id }
    public var skill: SkillName {
        get { core.skill }
        set { core.skill = newValue }
    }
    public var advantages: Int {
        get { core.advantages }
        set { core.advantages = newValue }
    }
    public var disadvantages: Int {
        get { core.disadvantages }
        set { core.disadvantages = newValue }
    }
    public var testRolls: [RpgTestRoll] {
        get { core.testRolls }
        set { core.testRolls = newValue }
    }
    public var difficulty: Int {
        get { core.difficulty }
        set { core.difficulty = newValue }
    }
    public var opportunities: Int {
        get { core.opportunities }
        set { core.opportunities = newValue }
    }
    public var complications: Int {
        get { core.complications }
        set { core.complications = newValue }
    }
    public var success: Bool? {
        core.success
    }
    public var snapshot: any RpgTestSnapshot {
        core.snapshot
    }
}

public struct RpgTestRef: Sendable, Hashable {
    public var id: Int
}

enum TestHookType: Sendable, HookTriggerForSomeRpgCharacterAndTest {
    case beforeRoll
    case beforeResolution
    case afterFailure
    case afterSuccess
}

public struct RpgTestRoll: Sendable {
    var numberDice: [NumberDie: Int]
    var plotDice: [PlotDieResult]
}
