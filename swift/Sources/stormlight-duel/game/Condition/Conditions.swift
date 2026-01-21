public protocol ConditionSharedProtocol {
    var id: Int { get }
}

public protocol Condition: ConditionSharedProtocol {
    var snapshot: any ConditionSnapshot { get }
}
extension Condition where Self: ConditionSnapshot {
    public var snapshot: ConditionSnapshot { self }
}

/// Cannot hold one itself recursively. `AnyCondition(AnyCondition(someCondition)).core === someCondition`
public struct AnyCondition: Condition {
    public var core: any Condition
    public var id: Int { core.id }
    public var snapshot: any ConditionSnapshot { core.snapshot }
    private init(notUnwrapping character: any Condition) {
        self.core = character
    }
    public init(_ character: any Condition) {
        if let character = character as? AnyCondition {
            self.init(character)
        } else {
            self.init(notUnwrapping: character)
        }
    }
}
extension AnyCondition: Keyed {
    public var primaryKey: Int { id }
}
