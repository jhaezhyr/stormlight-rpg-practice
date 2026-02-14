import KeyedSet

public struct Readyable<T: ItemSharedProtocol> {
    public var core: T
    public var isReady: Bool
    public init(_ core: T, isReady: Bool) {
        self.core = core
        self.isReady = isReady
    }
}
extension Readyable: Keyed {
    public var primaryKey: T.Key {
        core.primaryKey
    }
}
extension Readyable where T: Item {
    public var snapshot: Readyable<AnyItemSnapshot> {
        .init(.init(core.snapshot), isReady: isReady)
    }
}
extension Readyable where T == AnyItem {
    public init(_ core: any Item, isReady: Bool) {
        self.init(AnyItem(core), isReady: isReady)
    }
}
extension Readyable: Sendable where T: Sendable {
}
