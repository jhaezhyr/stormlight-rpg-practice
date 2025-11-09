enum NumberDie: Int {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d20 = 20
    case d100 = 100
}

struct RandomDistribution {
    public var dice: [(die: NumberDie, count: Int)]
}

// Measured in ft
typealias Distance = Int
// Measured in diamond marks or mk
typealias Money = Int
// Measured in lb
typealias Weight = Int

enum Realms: Hashable, CaseIterable {
    case physical
    case cognitive
    case spiritual
}

enum StatName: Hashable, CaseIterable {
    case strength
    case speed
    case intellect
    case awareness
    case willpower
    case presence
}

enum CoreSkillName: Hashable, CaseIterable {
    case agility
    case athletics
    case heavyWeaponry
    case lightWeaponry
    case stealth
    case thievery
    case crafting
    case deduction
    case discipline
    case intimidation
    case lore
    case medicine
    case deception
    case insight
    case leadership
    case perception
    case persuasion
    case survival

    static let statToSkill: CompleteDictionary<StatName, Set<CoreSkillName>> = [
        .strength: [.athletics, .heavyWeaponry],
        .speed: [.agility, .lightWeaponry, .stealth, .thievery],
        .intellect: [.crafting, .deduction, .lore, .medicine],
        .willpower: [.discipline, .intimidation],
        .awareness: [.insight, .perception, .survival],
        .presence: [.deception, .leadership, .persuasion]
    ]

    static let skillToStat: CompleteDictionary<CoreSkillName, StatName> = {
        CompleteDictionary(from: statToSkill.reduce([CoreSkillName: StatName]()) { (initial, x) in
            initial.merging(x.1.map { y in (y, x.0) }, uniquingKeysWith: { x, y in fatalError("Core skill associated with multiple stats: \(x) and \(y)") })
        })
    }()
}

enum SurgeName: Hashable, CaseIterable {
    case division
    case abrasion
    case cohesion
    case adhesion
    case gravitation
    case tension
    case illumination
    case transportation
    case progression
    case transformation
}

enum SkillName: Hashable {
    case core(CoreSkillName)
    case surge(SurgeName)
}

struct Resource: Comparable {
    public var value: Int
    public var maxValue: Int
    public mutating func restore(_ delta: Int) {
        value += max(min(delta, maxValue - value), 0)
    }

    static func < (lhs: Resource, rhs: Resource) -> Bool {
        lhs.value < rhs.value
    }
}

enum CultureName: CaseIterable {
    case alethi
    case natan
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

enum Expertise: Hashable {
    case weapon(WeaponName)
    case culture(CultureName)
}

protocol Character {
    var stats: CompleteDictionary<StatName, Int> { get }
    var coreSkills: CompleteDictionary<CoreSkillName, Int> { get }
    var otherSkills: Dictionary<SkillName, Int> { get }
    var defenses: CompleteDictionary<Realms, Int> { get }
    var health: Resource { get }
    var focus: Resource { get }
    var investiture: Resource { get }
    var recoveryDie: NumberDie { get }
    var sensesRange: Distance { get }
    var conditions: [Condition] { get }
}

protocol PlayerCharacter {
    var expertises: Set<Expertise> { get }
    var equipment: [Item] { get }
    var money: Money { get }
}

protocol Item {
    var name: String { get }
    var price: Money? { get }
    var weight: Weight { get }
}

enum TraitCondition {
    case always
    case expert
    case notExpert
}