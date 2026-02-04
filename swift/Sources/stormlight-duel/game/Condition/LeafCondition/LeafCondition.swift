internal protocol LeafCondition: Condition,
    AllTheListenersHolder,
    ListenerHolderLeaf,
    SelfListenerHolderLeaf,
    SelfListenerSelfHookHolderLeaf,
    SelfListenerSelfHookForTestHolderLeaf,
    ListenerForWhenIAmTargetedInATestHolderLeaf
{
}

/// If this needs any extra api, then the definition of LeafCondition is incomplete.
struct DummyLeafCondition: LeafCondition {
    var snapshot: any ConditionSnapshot
    var id: Int

}
