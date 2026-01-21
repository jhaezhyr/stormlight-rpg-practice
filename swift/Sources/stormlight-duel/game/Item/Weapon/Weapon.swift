/// An item used in combat to do the Strike action.
public protocol Weapon: Item {
    var type: WeaponType { get }
    var weaponName: WeaponName { get }
    var weaponsSkill: WeaponsSkill { get }
    var range: WeaponRange { get }
    var damage: RandomDistribution { get }
    var damageType: DamageType { get }
    var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { get }
}

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

public protocol WeaponTrait: Sendable {}
