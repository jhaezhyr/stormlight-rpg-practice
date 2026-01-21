internal protocol CompositeCondition:
    Condition,
    NonLeafGenericListenerHolder,
    AllTheListenersHolder
{
    associatedtype C: Condition
    var core: C { get }
}
extension CompositeCondition {
    public var id: Int { core.id }
    public var childHolders: [Any] { [core] }
}
