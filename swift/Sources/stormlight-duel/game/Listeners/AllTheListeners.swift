public typealias AllTheListenersHolder = ListenerHolder & SelfListenerHolder
    & SelfListenerSelfHookHolder
    & SelfListenerSelfHookForTestHolder

public protocol NonLeafGenericListenerHolder {
    var childHolders: [Any] { get }
}
