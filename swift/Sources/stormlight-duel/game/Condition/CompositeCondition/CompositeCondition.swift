internal protocol CompositeCondition: Condition {
    associatedtype C: Condition
    var core: C { get }
}
extension CompositeCondition {
    public var id: Int { core.id }
    public var childResponders: [any Responder] { [core] }
}
