struct Condition: Sendable {
    public var type: any ConditionType
}

protocol ConditionType: Sendable, Hashable {}

struct Afflicted: ConditionType {}
struct Determined: ConditionType {}
struct Disoriented: ConditionType {}
struct Empowered: ConditionType {}
struct Enhanced: ConditionType {
    public var stat: AttributeName
    public var amount: Int
}
struct Exhausted: ConditionType {
    public var amount: Int
}
struct Focused: ConditionType {}
struct Immobilized: ConditionType {}
struct Prone: ConditionType {}
struct Restrained: ConditionType {}
struct Slowed: ConditionType {}
struct Stunned: ConditionType {}
struct Surprised: ConditionType {}
struct Unconscious: ConditionType {}
