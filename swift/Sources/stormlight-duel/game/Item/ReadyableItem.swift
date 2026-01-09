public struct ReadyableItem {
    public var core: any Item
    public var isReady: Bool
    public init(_ core: any Item, isReady: Bool) {
        self.core = core
        self.isReady = isReady
    }
    public var snapshot: ReadyableItemSnapshot { .init(core.snapshot, isReady: isReady) }
}
extension ReadyableItem: Keyed {
    public var primaryKey: ItemRef {
        core.primaryKey
    }
}

public struct ReadyableItemSnapshot: Sendable {
    public var core: any ItemSnapshot
    public var isReady: Bool
    public init(_ core: any ItemSnapshot, isReady: Bool) {
        self.core = core
        self.isReady = isReady
    }
}
extension ReadyableItemSnapshot: Keyed {
    public var primaryKey: ItemRef {
        core.primaryKey
    }
}
