public struct BasicArmor: Armor, Sendable {
    public typealias WeaponType = any Weapon

    public var name: String

    public var price: Money?
    public var weight: Weight

    public var armorType: ArmorType
    public var deflect: Int

    public var traits: [(trait: any ArmorTrait, condition: TraitCondition)]

    public var possibleTraits: [any ArmorTrait] { traits.map { $0.trait } }
    public func activeTraits(
        whenEquippedBy characterRef: RpgCharacterRef, in gameSession: isolated GameSession
    ) -> [any ArmorTrait] {
        guard let character = gameSession.game.anyCharacter(at: characterRef) else {
            return []
        }
        return traits.compactMap { traitPair in
            if character.meets(traitPair.condition, for: armorType) {
                traitPair.trait
            } else {
                nil
            }
        }
    }

    public func _snapshot(in gameSession: isolated GameSession = #isolation) -> any ItemSnapshot {
        BasicArmorSnapshot(
            name: name, price: price, weight: weight, armorType: armorType, deflect: deflect)
    }

    public init(
        name: String? = nil,
        price: Money?,
        weight: Weight,
        armorType: ArmorType,
        deflect: Int,
        traits: [(trait: any ArmorTrait, condition: TraitCondition)],
        in gameSession: isolated GameSession,
    ) {
        if let name {
            self.name = name
        } else {
            self.name = "\(armorType) \(gameSession.nextId())"
        }
        self.price = price
        self.weight = weight
        self.armorType = armorType
        self.deflect = deflect
        self.traits = traits
    }
}

public struct BasicArmorSnapshot: ArmorSnapshot {
    public typealias WeaponType = any WeaponSnapshot
    public var name: String
    public var price: Money?
    public var weight: Weight
    public var armorType: ArmorType
    public var deflect: Int
}
