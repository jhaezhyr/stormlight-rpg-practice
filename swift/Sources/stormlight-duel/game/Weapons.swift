public enum WeaponRange: Sendable, Hashable {
    case melee(extraReach: Distance? = nil)
    case ranged(short: Distance, long: Distance)
}

public enum WeaponType: CaseIterable, Sendable, Hashable {
    case lightWeaponry
    case heavyWeaponry
    case specialWeapons
}

public enum WeaponsSkill: CaseIterable, Sendable, Hashable {
    case heavy
    case light
}

public enum DamageType: CaseIterable, Sendable, Hashable {
    case keen
    case vital
    case impact
}

public enum WeaponName: CaseIterable, Sendable, Hashable {
    case axe
    case crossbow
    case grandbow
    case greatsword
    case halfShard
    case hammer
    case handBallista
    case javelin
    case knife
    case longbow
    case longspear
    case longsword
    case mace
    case poleaxe
    case rapier
    case shardblade
    case shield
    case shortbow
    case shortspear
    case sidesword
    case sling
    case spikedShield
    case staff
    case warhammer

    case unarmedAttack
    case improvisedWeapon
}

public protocol Weapon: Item {
    var type: WeaponType { get }
    var weaponsSkill: WeaponsSkill { get }
    var range: WeaponRange { get }
    var damage: RandomDistribution { get }
    var damageType: DamageType { get }
    var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { get }
}

public protocol WeaponTrait {}

public struct Thrown: WeaponTrait {}
public struct Offhand: WeaponTrait {}
public struct Loaded: WeaponTrait {
    var ammunition: Resource
}
public struct TwoHanded: WeaponTrait {}
public struct Deadly: WeaponTrait {}
public struct CumbersomeWeapon: WeaponTrait {
    var minStrength: Int
}
public struct Pierce: WeaponTrait {}
public struct Defensive: WeaponTrait {}
public struct UniqueWeapon: WeaponTrait {}
public struct Momentum: WeaponTrait {}
public struct Fragile: WeaponTrait {}
public struct Indirect: WeaponTrait {}
public struct Quickdraw: WeaponTrait {}
public struct Dangerous: WeaponTrait {}
public struct Discreet: WeaponTrait {}
