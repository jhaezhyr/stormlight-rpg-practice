import KeyedSet

public typealias CharacterFeatureRef = String

public protocol CharacterFeatureSharedProtocol: Keyed where Key == CharacterFeatureRef {
    var name: CharacterFeatureRef { get }
    var actionsProvided: [CombatAction.Type] { get }
}

public protocol CharacterFeature: Responder, CharacterFeatureSharedProtocol, Keyed
where Key == CharacterFeatureRef {
    var snapshot: any CharacterFeatureSnapshot { get }
}
extension CharacterFeatureSharedProtocol {
    public var primaryKey: Key { name }
    public var actionsProvided: [CombatAction.Type] { [] }
}

public struct AnyCharacterFeature: CharacterFeature, Keyed {
    public let core: any CharacterFeature
    public var name: CharacterFeatureRef { core.name }
    public var actionsProvided: [any CombatAction.Type] { core.actionsProvided }
    public var childResponders: [any Responder] { core.childResponders }
    public var handlers: [any EventHandlerProtocol] { core.handlers }
    public var snapshot: any CharacterFeatureSnapshot { core.snapshot }
    public init(_ core: any CharacterFeature) {
        if let wrappedCore = core as? Self {
            self = wrappedCore
        } else {
            self.core = core
        }
    }
}

public protocol CharacterFeatureSnapshot: Sendable, CharacterFeatureSharedProtocol {}
extension CharacterFeature where Self: CharacterFeatureSnapshot {
    public var snapshot: any CharacterFeatureSnapshot { self }
}

public struct AnyCharacterFeatureSnapshot: CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { core.name }
    public var actionsProvided: [any CombatAction.Type] { core.actionsProvided }
    public var primaryKey: String { core.primaryKey }
    public let core: any CharacterFeatureSnapshot
    public init(_ core: any CharacterFeatureSnapshot) {
        if let wrappedCore = core as? Self {
            self = wrappedCore
        } else {
            self.core = core
        }
    }
}

public struct DummyCharacterFeatureSnapshot: CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef
    public var actionsProvided: [any CombatAction.Type]
}
