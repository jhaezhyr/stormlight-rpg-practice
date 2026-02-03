public protocol RpgTestSnapshot: RpgTestSharedProtocol, Sendable {
}

public struct AnyRpgTestSnapshot: RpgTestSnapshot {
    public var core: any RpgTestSnapshot
    public init(_ test: any RpgTestSnapshot) {
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
}
