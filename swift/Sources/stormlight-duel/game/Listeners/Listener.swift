public protocol ListenerHolder {
    var listeners: [any ListenerProtocol] { get }
    var allListeners: [any ListenerProtocol] { get }
}
extension ListenerHolder {
    public var listeners: [any ListenerProtocol] { [] }
}
public protocol ListenerHolderLeaf: ListenerHolder {
}
extension ListenerHolderLeaf {
    public var allListeners: [any ListenerProtocol] {
        listeners
    }
}
extension NonLeafGenericListenerHolder where Self: ListenerHolder {
    public var allListeners: [any ListenerProtocol] {
        listeners
            + childHolders.compactMap { ($0 as? any ListenerHolder)?.allListeners }.flatMap { $0 }
    }
}

public protocol ListenerProtocol: Sendable {
    associatedtype Trigger: HookTrigger
    var id: ListenerId { get }
    var hook: Trigger { get }
    var action: Action { get }
}

public struct Listener<Trigger: HookTrigger>: ListenerProtocol {
    public var id: ListenerId
    public var hook: Trigger
    public var action: Action
}
extension GameSession {
    func listen<Trigger: HookTrigger>(to trigger: Trigger, action: @escaping Action) -> Listener<
        Trigger
    > {
        Listener(id: self.nextId(), hook: trigger, action: action)
    }
}

public typealias Action = @Sendable (_ gameSession: isolated GameSession) async -> Void

public protocol HookTrigger: Hashable, Sendable {}

public typealias ListenerId = Int
