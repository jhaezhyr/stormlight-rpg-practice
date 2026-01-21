public protocol RpgTestSnapshot: RpgTestSharedProtocol, Sendable {
}

public struct RpgSimpleTestSnapshot: RpgTestSnapshot {
    public let id: Int
    public var skill: SkillName
    public var difficulty: Int
    public var advantages: Int
    public var disadvantages: Int
    public var testRolls: [RpgTestRoll]
    public var opportunities: Int
    public var complications: Int
    public var success: Bool?
}

public struct AnyRpgTestSnapshot: RpgTestSnapshot {
    public var core: any RpgTestSnapshot
    public init(_ test: any RpgTestSnapshot) {
        self.core = test
    }
    public var id: Int { core.id }
    public var skill: SkillName {
        core.skill
    }
    public var advantages: Int {
        core.advantages
    }
    public var disadvantages: Int {
        core.disadvantages
    }
    public var testRolls: [RpgTestRoll] {
        core.testRolls
    }
    public var difficulty: Int {
        core.difficulty
    }
    public var opportunities: Int {
        core.opportunities
    }
    public var complications: Int {
        core.complications
    }
    public var success: Bool? {
        core.success
    }
}
