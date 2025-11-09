enum WeaponRange {
    case melee(extraReach: Distance? = nil)
    case ranged(short: Distance, long: Distance)
}

enum WeaponType {
    case lightWeaponry
    case heavyWeaponry
    case specialWeapons
}

enum WeaponsSkill {
    case heavy
    case light
}

enum DamageType {
    case keen
    case vital
    case impact
}

enum WeaponName: CaseIterable {
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

protocol Weapon: Item {
    var type: WeaponType { get }
    var weaponsSkill: WeaponsSkill { get }
    var range: WeaponRange { get }
    var damage: RandomDistribution { get }
    var damageType: DamageType { get }
    var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { get }
}

protocol WeaponTrait {}

struct Thrown: WeaponTrait {}
struct Offhand: WeaponTrait {}
struct Loaded: WeaponTrait {
    var ammunition: Resource
}
struct TwoHanded: WeaponTrait {}
struct Deadly: WeaponTrait {}
struct CumbersomeWeapon: WeaponTrait {
    var minStrength: Int
}
struct Pierce: WeaponTrait {}
struct Defensive: WeaponTrait {}
struct UniqueWeapon: WeaponTrait {}
struct Momentum: WeaponTrait {}
struct Fragile: WeaponTrait {}
struct Indirect: WeaponTrait {}
struct Quickdraw: WeaponTrait {}
struct Dangerous: WeaponTrait {}
struct Discreet: WeaponTrait {}

