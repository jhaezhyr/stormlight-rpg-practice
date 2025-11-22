public protocol Item: Keyed where Key == String {
    var name: String { get }
    var price: Money? { get }
    var weight: Weight { get }
}

extension Item {
    public var primaryKey: String {
        name
    }
}

public enum TraitCondition {
    case always
    case expert
    case notExpert
}
