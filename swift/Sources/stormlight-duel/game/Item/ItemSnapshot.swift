public protocol ItemSnapshot: ItemSharedProtocol, Sendable {
}

public struct AnyItemSnapshot: ItemSnapshot {
    public let core: any ItemSnapshot

    public var name: String { core.name }
    public var price: Money? { core.price }
    public var weight: Weight { core.weight }

    public var trueSelf: any ItemSharedProtocol { core.trueSelf }

    public init(_ core: any ItemSnapshot) {
        if let wrappedCore = core as? Self {
            self.core = wrappedCore.core
        } else {
            self.core = core
        }
    }
}
