/// An item used in combat to do the Strike action.
public protocol WeaponSharedProtocol: Item, ItemSnapshot {
    var type: WeaponSpecies { get }
    var weaponName: WeaponName { get }
    var weaponsSkill: WeaponsSkill { get }
    var range: WeaponRange { get }
    var damage: RandomDistribution { get }
    var damageType: DamageType { get }
    var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { get }
}
public protocol Weapon: WeaponSharedProtocol where WeaponType == any Weapon {
    func activeTraits(
        whenEquippedBy characterRef: RpgCharacterRef,
        in gameSnapshot: GameSnapshot,
    ) -> [any WeaponTrait]
}
extension WeaponSharedProtocol {
    public func activeTraits(
        whenEquippedBy characterRef: RpgCharacterRef,
        in gameSnapshot: GameSnapshot
    ) -> [any WeaponTrait] {
        guard let character = gameSnapshot.characters[characterRef] else {
            return []
        }
        return traits.compactMap { traitPair in
            if character.meets(traitPair.condition, for: self.weaponName) {
                traitPair.trait
            } else {
                nil
            }
        }
    }
}

extension Weapon {
    /// If you pass a preferred hand, then it will only try to ready a single-handed weapon in that hand.
    ///
    /// If it returns nil, then it can't ready it as requested. If it returns a set of hands, then all those hands must be set to be this item to ready it.
    public func canReady(
        by characterRef: RpgCharacterRef,
        preferredHand: Hand?,
        in gameSession: isolated GameSession = #isolation
    ) -> Set<Hand>? {
        guard let me = gameSession.game.anyCharacter(at: characterRef) else {
            return nil
        }
        let isTwoHanded = self.activeTraits(
            whenEquippedBy: me.primaryKey, in: gameSession.game.snapshot()
        )
        .contains { $0 is TwoHanded }
        let mainHandIsFree = me.mainHand == nil
        let offHandIsFree = me.offHand == nil
        if isTwoHanded {
            return mainHandIsFree && offHandIsFree ? [.mainHand, .offHand] : nil
        } else {
            switch preferredHand {
            case .mainHand:
                return mainHandIsFree ? [.mainHand] : nil
            case .offHand:
                return offHandIsFree ? [.offHand] : nil
            case nil:
                return mainHandIsFree ? [.mainHand] : offHandIsFree ? [.offHand] : nil
            }
        }
    }
    public func ready(
        by character: any RpgCharacter,
        preferredHand inHand: Hand?,
        in gameSession: isolated GameSession = #isolation,
    ) {
        guard let handsRequired = canReady(by: character.primaryKey, preferredHand: inHand) else {
            return
        }
        var me = character
        let itemRef = self.primaryKey
        if handsRequired.contains(.mainHand) {
            me.mainHand = itemRef
        }
        if handsRequired.contains(.offHand) {
            me.offHand = itemRef
        }
        me.equipment[itemRef]?.isReady = true
    }
}
public protocol WeaponSnapshot: WeaponSharedProtocol {}
public struct AnyWeaponSnapshot: WeaponSharedProtocol {
    public init(_ core: any WeaponSnapshot) {
        self.core = core
    }

    private var core: any WeaponSnapshot

    public var type: WeaponSpecies { core.type }
    public var weaponName: WeaponName { core.weaponName }
    public var weaponsSkill: WeaponsSkill { core.weaponsSkill }
    public var range: WeaponRange { core.range }
    public var damage: RandomDistribution { core.damage }
    public var damageType: DamageType { core.damageType }
    public var traits: [(trait: any WeaponTrait, condition: TraitCondition)] { core.traits }
    public typealias WeaponType = any WeaponSnapshot
    public var name: String { core.name }
    public var price: Money? { core.price }
    public var weight: Weight { core.weight }
    public var trueSelf: any ItemSharedProtocol { core.trueSelf }
}
extension AnyWeaponSnapshot: CustomStringConvertible {
    public var description: String { "\(core)" }
}

public enum WeaponRange: Sendable, Hashable {
    case melee(extraReach: Distance? = nil)
    case ranged(short: Distance, long: Distance)
}

public enum WeaponSpecies: CaseIterable, Sendable, Hashable {
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
    public var coreSkill: CoreSkillName {
        switch self {
        case .heavy: .heavyWeaponry
        case .light: .lightWeaponry
        }
    }
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

extension RpgCharacterSharedProtocol {
    func meets(_ traitCondition: TraitCondition, for weaponTrait: WeaponName) -> Bool {
        let iAmExpert = false  // TODO Make this affected by actual expertises
        switch (traitCondition, iAmExpert) {
        case (.expert, true), (.notExpert, false), (.always, _): return true
        default: return false
        }
    }
}

extension CaseIterable where Self: RawRepresentable, RawValue == String {
    public init?(caseInsensitiveRawValue: String) {
        // TODO Check for duplicates
        for candidate in Self.allCases {
            if candidate.rawValue.lowercased() == caseInsensitiveRawValue {
                self = candidate
                return
            }
        }
        return nil
    }
}
