public typealias AllTheListenersHolder = ListenerHolder & SelfListenerHolder
    & SelfListenerSelfHookHolder
    & SelfListenerSelfHookForTestHolder
    & ListenerForWhenIAmTargetedInATestHolder

public protocol NonLeafGenericListenerHolder {
    var childHolders: [Any] { get }
}
