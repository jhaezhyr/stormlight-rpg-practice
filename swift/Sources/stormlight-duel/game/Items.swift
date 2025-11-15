protocol Item {
    var name: String { get }
    var price: Money? { get }
    var weight: Weight { get }
}

enum TraitCondition {
    case always
    case expert
    case notExpert
}
