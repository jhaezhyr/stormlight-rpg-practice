public protocol Item: Keyed where Key == ItemRef {
    var name: String { get }
    var price: Money? { get }
    var weight: Weight { get }
}

extension Item {
    public var primaryKey: ItemRef {
        ItemRef(name: self.name)
    }
}

public enum TraitCondition: Sendable {
    case always
    case expert
    case notExpert
}
