import KeyedSet

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

public protocol Item: ItemSharedProtocol, Responder {
    func _snapshot(in gameSession: isolated GameSession) -> any ItemSnapshot
}
extension Item {
    public func snapshot(in gameSession: isolated GameSession = #isolation) -> any ItemSnapshot {
        _snapshot(in: gameSession)
    }
}
extension Item where Self: ItemSnapshot {
    public func _snapshot(in gameSession: isolated GameSession) -> any ItemSnapshot { self }
}

public struct AnyItem: Item {
    public let core: any Item

    public var name: String { core.name }
    public var price: Money? { core.price }
    public var weight: Weight { core.weight }

    public func _snapshot(in gameSession: isolated GameSession = #isolation) -> any ItemSnapshot {
        core.snapshot()
    }

    public var childResponders: [any Responder] { core.childResponders }
    public var handlers: [any EventHandlerProtocol] { core.handlers }
    public var syncHandlers: [any EventHandlerSyncProtocol] { core.syncHandlers }

    init(_ core: any Item) {
        if let wrappedCore = core as? AnyItem {
            self.core = wrappedCore.core
        } else {
            self.core = core
        }
    }
}
