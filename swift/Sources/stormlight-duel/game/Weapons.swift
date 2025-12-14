public enum WeaponRange: Sendable, Hashable {
    case melee(extraReach: Distance? = nil)
    case ranged(short: Distance, long: Distance)
}

public enum WeaponType: CaseIterable, Sendable, Hashable {
    case lightWeaponry
    case heavyWeaponry
    case specialWeapons

    var skill: SkillName {
        let coreSkill: CoreSkillName =
            switch self {
            case .lightWeaponry: .lightWeaponry
            case .heavyWeaponry: .heavyWeaponry
            case .specialWeapons: .lightWeaponry  // TODO i don't know
            }
        return .core(coreSkill)
    }
}

public enum WeaponsSkill: CaseIterable, Sendable, Hashable {
    case heavy
    case light
}

public enum DamageType: String, CaseIterable, Sendable, Hashable {
    case keen = "keen"
    case vital = "vital"
    case impact = "impact"
}

public enum WeaponName: String, CaseIterable, Sendable, Hashable {
    case axe = "axe"
    case crossbow = "crossbow"
    case grandbow = "grandbow"
    case greatsword = "greatsword"
    case halfShard = "halfshard"
    case hammer = "hammer"
    case handBallista = "ballista"
    case javelin = "javelin"
    case knife = "knife"
    case longbow = "longbow"
    case longspear = "longspear"
    case longsword = "longsword"
    case mace = "mace"
    case poleaxe = "poleaxe"
    case rapier = "rapier"
    case shardblade = "shardblade"
    case shield = "shield"
    case shortbow = "shortbow"
    case shortspear = "shortspear"
    case sidesword = "sidesword"
    case sling = "sling"
    case spikedShield = "spikedshield"
    case staff = "staff"
    case warhammer = "warhammer"

    case unarmedAttack = "unarmed"
    case improvisedWeapon = "improvised"
}

public protocol Weapon: Item {
    var type: WeaponType { get }
    var weaponName: WeaponName { get }
    var weaponsSkill: WeaponsSkill { get }
    var range: WeaponRange { get }
    var damage: RandomDistribution { get }
    var damageType: DamageType { get }
    var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { get }
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

public protocol WeaponTrait: Sendable {}

public struct Thrown: WeaponTrait {
    var short: Distance
    var long: Distance
}
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

public struct BasicWeapon: Weapon, Sendable {
    public var weaponName: WeaponName
    public var type: WeaponType
    public var weaponsSkill: WeaponsSkill
    public var range: WeaponRange
    public var damage: RandomDistribution
    public var damageType: DamageType
    public var traits: [(trait: any WeaponTrait, condition: TraitCondition)]
    public var price: Money?
    public var weight: Weight
    public var name: String

    init(
        weaponName: WeaponName,
        type: WeaponType,
        weaponsSkill: WeaponsSkill,
        range: WeaponRange,
        damage: RandomDistribution,
        damageType: DamageType,
        traits: [(trait: any WeaponTrait, condition: TraitCondition)],
        price: Money?,
        weight: Weight,
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
        name = "\(self.weaponName) \(BasicWeapon.getNewWeaponId())"
    }

    nonisolated(unsafe) private static var nextWeaponId = 1
    private static func getNewWeaponId() -> Int {
        nextWeaponId += 1
        return nextWeaponId - 1
    }
}

nonisolated(unsafe) public let basicWeapons: [WeaponName: () -> BasicWeapon] = [
    .axe: {
        BasicWeapon(
            weaponName: .axe,
            type: .heavyWeaponry,
            weaponsSkill: .heavy,
            range: .melee(),
            damage: .init(dice: [(.d6, 1)]),
            damageType: .keen,
            traits: [(Thrown(short: 20, long: 60), .always), (Offhand(), .expert)],
            price: 20,
            weight: 2
        )
    },
    .crossbow: {
        BasicWeapon(
            weaponName: .crossbow,
            type: .heavyWeaponry,
            weaponsSkill: .heavy,
            range: .ranged(short: 100, long: 400),
            damage: .init(dice: [(.d8, 1)]),
            damageType: .keen,
            traits: [
                (Loaded(ammunition: .init(value: 1, maxValue: 1)), .always),
                (TwoHanded(), .always),
                (Deadly(), .expert),
            ],
            price: 200,
            weight: 7
        )
    },
    .knife: {
        BasicWeapon(
            weaponName: .knife,
            type: .lightWeaponry,
            weaponsSkill: .light,
            range: .melee(),
            damage: .init(dice: [(.d4, 1)]),
            damageType: .keen,
            traits: [
                (Discreet(), .always),
                (Offhand(), .expert),
                (Thrown(short: 20, long: 60), .expert),
            ],
            price: 8,
            weight: 1
        )
    },
]
