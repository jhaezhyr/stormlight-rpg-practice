public struct BasicWeaponSnapshot: WeaponSnapshot, Sendable {
    public var weaponName: WeaponName
    public var type: WeaponSpecies
    public var weaponsSkill: WeaponsSkill
    public var range: WeaponRange
    public var damage: RandomDistribution
    public var damageType: DamageType
    public var traits: [(trait: any WeaponTraitSnapshot, condition: TraitCondition)]
    public var price: Money?
    public var weight: Weight
    public var name: String

    init(
        name: String,
        weaponName: WeaponName,
        type: WeaponSpecies,
        weaponsSkill: WeaponsSkill,
        range: WeaponRange,
        damage: RandomDistribution,
        damageType: DamageType,
        traits: [(trait: any WeaponTraitSnapshot, condition: TraitCondition)],
        price: Money?,
        weight: Weight,
        in gameSession: isolated GameSession
    ) {
        self.weaponName = weaponName
        self.type = type
        self.weaponsSkill = weaponsSkill
        self.range = range
        self.damage = damage
        self.damageType = damageType
        self.traits = traits
        self.price = price
        self.weight = weight
        self.name = name
    }
}
