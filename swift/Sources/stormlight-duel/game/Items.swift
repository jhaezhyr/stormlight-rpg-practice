public protocol ItemSharedProtocol: Keyed where Key == ItemRef {
    var name: String { get }
    var price: Money? { get }
    var weight: Weight { get }
}

extension ItemSharedProtocol {
    public var primaryKey: ItemRef {
        ItemRef(name: self.name)
    }
}

public enum TraitCondition: Sendable {
    case always
    case expert
    case notExpert
}

public protocol ItemSnapshot: ItemSharedProtocol, Sendable {
}

public protocol Item: ItemSharedProtocol {
    var snapshot: any ItemSnapshot { get }
}
extension Item where Self: ItemSnapshot {
    public var snapshot: any ItemSnapshot { self }
}
