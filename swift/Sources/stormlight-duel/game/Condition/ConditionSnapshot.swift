import KeyedSet

public protocol ConditionSnapshot: Sendable, ConditionSharedProtocol {
}

public struct AnyConditionSnapshot: ConditionSnapshot {
    public var core: any ConditionSnapshot
    public var id: Int { core.id }
    private init(notUnwrapping conditionSnapshot: any ConditionSnapshot) {
        self.core = conditionSnapshot
    }
    public init(_ conditionSnapshot: any ConditionSnapshot) {
        if let conditionSnapshot = conditionSnapshot as? AnyConditionSnapshot {
            self.init(conditionSnapshot)
        } else {
            self.init(notUnwrapping: conditionSnapshot)
        }
    }
}
extension AnyConditionSnapshot: Keyed {
    public var primaryKey: Int { id }
}
