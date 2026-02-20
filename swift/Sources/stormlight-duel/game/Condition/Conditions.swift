import KeyedSet

public typealias ConditionTypeRef = String

public protocol ConditionSharedProtocol: Keyed where Key == Int {
    var id: Int { get }
    var type: ConditionTypeRef { get }
}
extension ConditionSharedProtocol {
    public var primaryKey: Int { id }
}

public protocol Condition: ConditionSharedProtocol, Responder {
    var snapshot: any ConditionSnapshot { get }
}
extension Condition where Self: ConditionSnapshot {
    public var snapshot: any ConditionSnapshot { self }
    public var type: ConditionTypeRef { "\(Self.self)" }
    public static var type: ConditionTypeRef { "\(Self.self)" }
}

/// Cannot hold one itself recursively. `AnyCondition(AnyCondition(someCondition)).core === someCondition`
public struct AnyCondition: Condition {
    public var core: any Condition
    public var id: Int { core.id }
    public var type: ConditionTypeRef { core.type }
    public var snapshot: any ConditionSnapshot { core.snapshot }
    public var handlers: [any EventHandlerProtocol] { core.handlers }
    public var childResponders: [any Responder] { core.childResponders }
    private init(notUnwrapping condition: any Condition) {
        self.core = condition
    }
    public init(_ condition: any Condition) {
        if let character = condition as? AnyCondition {
            self.init(character)
        } else {
            self.init(notUnwrapping: condition)
        }
    }
}
