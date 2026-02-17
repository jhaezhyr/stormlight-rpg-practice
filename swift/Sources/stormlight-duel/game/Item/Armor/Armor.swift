public protocol ArmorSharedProtocol: ItemSharedProtocol {
    var armorType: ArmorType { get }
    var deflect: Int { get }
    // TODO Something about traits, I guess.
}

public protocol Armor: ArmorSharedProtocol, Item {
    func activeTraits(
        whenEquippedBy characterRef: RpgCharacterRef, in gameSession: isolated GameSession
    ) -> [any ArmorTrait]
    var possibleTraits: [any ArmorTrait] { get }
}
extension Armor {
    public var childResponders: [any Responder] {
        possibleTraits
    }
}

public protocol ArmorTrait: Responder, Sendable {}

public enum ArmorType: Sendable, Hashable {
    case uniform
    case leather
    case chain
    case breastplate
    case halfPlate
    case fullPlate
}

public protocol ArmorSnapshot: ArmorSharedProtocol, ItemSnapshot {}

extension RpgCharacterSharedProtocol {
    func meets(_ traitCondition: TraitCondition, for armorType: ArmorType) -> Bool {
        let iAmExpert = false  // TODO Make this affected by actual expertises
        switch (traitCondition, iAmExpert) {
        case (.expert, true), (.notExpert, false), (.always, _): return true
        default: return false
        }
    }
}
