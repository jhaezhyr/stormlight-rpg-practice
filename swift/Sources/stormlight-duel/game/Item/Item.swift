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

public struct ItemRef: Hashable, Sendable {
    public var name: String
    init(name: String) {
        self.name = name
    }
    public init(of item: any Item) {
        self = item.primaryKey
    }
}

public enum TraitCondition: Sendable {
    case always
    case expert
    case notExpert
}

public protocol Item: ItemSharedProtocol {
    var snapshot: any ItemSnapshot { get }
}
extension Item where Self: ItemSnapshot {
    public var snapshot: any ItemSnapshot { self }
}
