/// Since a test has lots of hooks, it is a fully mutable structure
///
/// A head-to-head test is presented to each character as a separate test structure.
///
/// In an attack, there will also be damage rolls. Those rolls are not part of the test structure. However, the advantages, disadvantages, opportunities, and complications from the test can affect those rolls.
public protocol RpgTestProtocol {
    var skill: SkillName { get set }
    var advantages: Int { get set }
    var disadvantages: Int { get set }
    var testRolls: [RpgTestRoll] { get set }
    var difficulty: Int { get set }  // In a head to head, this is the opponent's total number.
    var opportunities: Int { get set }
    var complications: Int { get set }

    var success: Bool? { get }
}

public struct RpgSimpleTest: RpgTestProtocol {
    public var skill: SkillName
    public var advantages: Int
    public var disadvantages: Int
    public var testRolls: [RpgTestRoll]
    public var difficulty: Int
    public var opportunities: Int
    public var complications: Int

    public var success: Bool?
}

/// Use this in places where `any RpgTestProtocol` doesn't work.
public struct AnyRpgTest: RpgTestProtocol {
    public var core: any RpgTestProtocol
    public init(_ test: any RpgTestProtocol) {
        self.core = test
    }
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
}

public struct RpgTestRef: Sendable, Hashable {
    var id: Int
}

enum TestHookType: Sendable, HookTriggerForSomeRpgCharacterAndTest {
    case beforeRoll
    case beforeResolution
    case afterFailure
    case afterSuccess
}

public struct RpgTestRoll {
    var numberDice: [NumberDie: Int]
    var plotDice: [PlotDieResult]
}
